const path = require('path');
const dotenv = require('dotenv');
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const API_KEY = (process.env.GEMINI_API_KEY || '').trim();
const MODEL_NAME = 'gemini-3.5-flash-lite';

/**
 * Extract structured identity fields from an uploaded document buffer.
 * Uses Gemini Vision as primary OCR engine, with Tesseract.js as local fallback.
 */
async function extractDocumentFields(buffer, mimeType, docType = 'OTHER', language = 'bn') {
  if (API_KEY && buffer && buffer.length > 0) {
    const geminiResult = await extractWithGeminiVision(buffer, mimeType, docType, language);
    if (geminiResult) {
      return geminiResult;
    }
  }

  // Fallback to Tesseract.js for image buffers
  if (mimeType && mimeType.startsWith('image/') && buffer && buffer.length > 0) {
    const tesseractResult = await extractWithTesseract(buffer);
    if (tesseractResult) {
      return tesseractResult;
    }
  }

  return {
    fullName: null,
    dateOfBirth: null,
    documentNumber: null,
    fatherName: null,
    motherName: null,
    address: null,
    rawText: '',
    confidence: 0,
    ocrEngine: 'unavailable',
  };
}

async function extractWithGeminiVision(buffer, mimeType, docType, language) {
  const supported = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
  const safeMime = supported.includes(mimeType) ? mimeType : 'image/jpeg';

  const prompt = `You are an OCR extraction engine for Bangladesh government service documents (e.g., NID, Birth Certificate, SSC/HSC Certificate, Citizenship Certificate, Utility Bill).
Document Type hint: ${docType}
Preferred output language context: ${language === 'bn' ? 'Bangla/English' : 'English'}

Extract the key fields visible in this document. If a field is not present or illegible, return null.
Normalize dateOfBirth to YYYY-MM-DD if possible.

Respond ONLY with valid JSON (no markdown fences):
{
  "fullName": "string or null",
  "dateOfBirth": "YYYY-MM-DD or null",
  "documentNumber": "string or null",
  "fatherName": "string or null",
  "motherName": "string or null",
  "address": "string or null",
  "rawText": "short summary of extracted text",
  "confidence": 0.92
}`;

  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inlineData: {
                  mimeType: safeMime,
                  data: buffer.toString('base64'),
                },
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 700,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok || !data.candidates || !data.candidates.length) {
      console.warn('[OCR Gemini Warning]', data.error ? data.error.message : 'No candidate returned');
      return null;
    }

    const rawText = data.candidates[0].content.parts[0].text.trim();
    const cleaned = rawText.replace(/^```json\s*/i, '').replace(/```$/i, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      fullName: parsed.fullName || null,
      dateOfBirth: parsed.dateOfBirth || null,
      documentNumber: parsed.documentNumber || null,
      fatherName: parsed.fatherName || null,
      motherName: parsed.motherName || null,
      address: parsed.address || null,
      rawText: parsed.rawText || '',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.88,
      ocrEngine: 'gemini-vision',
    };
  } catch (err) {
    console.warn('[OCR Gemini Error]', err.message);
    return null;
  }
}

async function extractWithTesseract(buffer) {
  try {
    const Tesseract = require('tesseract.js');
    const result = await Tesseract.recognize(buffer, 'eng');
    const text = (result && result.data && result.data.text ? result.data.text : '').trim();
    const parsed = parseBasicFieldsFromText(text);
    return {
      ...parsed,
      rawText: text.slice(0, 500),
      confidence: result && result.data && typeof result.data.confidence === 'number'
        ? Number((result.data.confidence / 100).toFixed(2))
        : 0.65,
      ocrEngine: 'tesseract',
    };
  } catch (err) {
    console.warn('[OCR Tesseract Error]', err.message);
    return null;
  }
}

function parseBasicFieldsFromText(text) {
  if (!text) {
    return {
      fullName: null,
      dateOfBirth: null,
      documentNumber: null,
      fatherName: null,
      motherName: null,
      address: null,
    };
  }

  const nameMatch = text.match(/(?:Name|নাম)\s*[:\-]\s*([A-Za-z. ]{3,60})/i);
  const dobMatch = text.match(/(\d{4}-\d{2}-\d{2}|\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{2}\s+[A-Za-z]{3,9}\s+\d{4})/);
  const idMatch = text.match(/\b(\d{10}|\d{13}|\d{17})\b/);

  return {
    fullName: nameMatch ? nameMatch[1].trim() : null,
    dateOfBirth: dobMatch ? dobMatch[1].trim() : null,
    documentNumber: idMatch ? idMatch[1].trim() : null,
    fatherName: null,
    motherName: null,
    address: null,
  };
}

module.exports = {
  extractDocumentFields,
  parseBasicFieldsFromText,
};
