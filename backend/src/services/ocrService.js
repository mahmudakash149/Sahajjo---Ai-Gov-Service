const path = require('path');
const dotenv = require('dotenv');
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const API_KEY = (process.env.GEMINI_API_KEY || '').trim();
const MODEL_NAME = 'gemini-3.5-flash-lite';

function computeReadability(result, docType) {
  if (docType === 'PHOTO') return true;
  if (!result || result.ocrEngine === 'unavailable') return false;
  const hasKeyField = Boolean(result.fullName || result.dateOfBirth || result.documentNumber);
  if (typeof result.confidence === 'number' && result.confidence < 0.45 && !hasKeyField) {
    return false;
  }
  if (!hasKeyField && String(result.rawText || '').trim().length < 15) {
    return false;
  }
  return true;
}

/**
 * Extract structured identity fields from an uploaded document buffer.
 * Uses Gemini Vision as primary OCR engine, with Tesseract.js as local fallback.
 */
async function extractDocumentFields(buffer, mimeType, docType = 'OTHER', language = 'bn') {
  if (API_KEY && buffer && buffer.length > 0) {
    let geminiResult = await extractWithGeminiVision(buffer, mimeType, docType, language);
    if (!geminiResult) {
      await new Promise((r) => setTimeout(r, 800));
      geminiResult = await extractWithGeminiVision(buffer, mimeType, docType, language);
    }
    if (geminiResult) {
      return { ...geminiResult, isReadable: computeReadability(geminiResult, docType) };
    }
  }

  // Fallback to Tesseract.js for image buffers
  if (mimeType && mimeType.startsWith('image/') && buffer && buffer.length > 0) {
    const tesseractResult = await extractWithTesseract(buffer);
    if (tesseractResult) {
      return { ...tesseractResult, isReadable: computeReadability(tesseractResult, docType) };
    }
  }

  const unavailable = {
    fullName: null,
    fullNameEn: null,
    fullNameBn: null,
    dateOfBirth: null,
    documentNumber: null,
    fatherName: null,
    motherName: null,
    address: null,
    rawText: '',
    confidence: 0,
    ocrEngine: 'unavailable',
  };
  return { ...unavailable, isReadable: computeReadability(unavailable, docType) };
}

async function extractWithGeminiVision(buffer, mimeType, docType, language) {
  const supported = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
  const safeMime = supported.includes(mimeType) ? mimeType : 'image/jpeg';

  const prompt = `You are an OCR extraction engine for Bangladesh government service documents (NID, Online Birth Certificate, Passport, Driving License, SSC/HSC Certificate, Citizenship Certificate, Utility Bill).
Document Type hint: ${docType}
Preferred display language context: ${language === 'bn' ? 'Bangla/English' : 'English'}

CRITICAL EXTRACTION RULES:
1. Names: Bangladesh documents often print the person's name in Bangla (e.g. "মাহমুদ আকাশ") and/or English (e.g. "Mahmud Akash").
   - Put the English name in "fullNameEn". If ONLY Bangla is printed on the document, transliterate the Bangla name accurately into standard English spelling in "fullNameEn" (e.g., "মাহমুদ আকাশ" -> "Mahmud Akash").
   - Put the Bangla name in "fullNameBn" (if printed in Bangla, otherwise null).
   - Set "fullName" to "fullNameEn" if available, otherwise "fullNameBn".
2. Date of Birth: Extract ONLY the person's Date of Birth (জন্ম তারিখ / Date of Birth / DOB).
   - NEVER extract Issue Date (প্রদানের তারিখ / Date of Issue), Registration Date (নিবন্ধনের তারিখ / Date of Registration), or Expiry Date.
   - Normalize "dateOfBirth" strictly to YYYY-MM-DD (convert any Bangla digits ০-৯ to English digits 0-9).
3. If any field is not present or illegible, return null.

Respond ONLY with valid JSON:
{
  "fullName": "string or null",
  "fullNameEn": "string or null",
  "fullNameBn": "string or null",
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
          responseMimeType: 'application/json',
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

    const fullNameEn = parsed.fullNameEn || null;
    const fullNameBn = parsed.fullNameBn || null;
    const fullName = parsed.fullName || fullNameEn || fullNameBn || null;

    return {
      fullName,
      fullNameEn,
      fullNameBn,
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
    let result;
    try {
      result = await Tesseract.recognize(buffer, 'eng+ben');
    } catch (_langErr) {
      result = await Tesseract.recognize(buffer, 'eng');
    }
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

function normalizeBanglaDigits(str) {
  const map = { '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4', '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9' };
  return String(str || '').replace(/[০-৯]/g, (d) => map[d] || d);
}

function parseBasicFieldsFromText(text) {
  if (!text) {
    return {
      fullName: null,
      fullNameEn: null,
      fullNameBn: null,
      dateOfBirth: null,
      documentNumber: null,
      fatherName: null,
      motherName: null,
      address: null,
    };
  }

  const normalizedText = normalizeBanglaDigits(text);
  const nameMatch = normalizedText.match(/(?:Name|নাম)\s*[:\-]\s*([A-Za-z. \u0980-\u09FF]{3,60})/i);

  // Prefer explicit Date of Birth lines and avoid Issue / Registration / Expiry dates
  const dobLineMatch = normalizedText.match(
    /(?:Date\s*of\s*Birth|DOB|Birth\s*Date|জন্ম\s*তারিখ)[^\n\r]{0,30}?(\d{4}-\d{2}-\d{2}|\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{2}\s+[A-Za-z]{3,9}\s+\d{4})/i
  );

  let dob = dobLineMatch ? dobLineMatch[1].trim() : null;
  if (!dob) {
    const lines = normalizedText.split(/\r?\n/);
    for (const line of lines) {
      if (/(?:issue|registration|expiry|valid|প্রদান|নিবন্ধন|মেয়াদ)/i.test(line)) {
        continue;
      }
      const m = line.match(/(\d{4}-\d{2}-\d{2}|\d{2}[\/\-]\d{2}[\/\-]\d{4}|\d{2}\s+[A-Za-z]{3,9}\s+\d{4})/);
      if (m) {
        dob = m[1].trim();
        break;
      }
    }
  }

  const idMatch = normalizedText.match(/\b(\d{10}|\d{13}|\d{17})\b/);
  const extractedName = nameMatch ? nameMatch[1].trim() : null;
  const isBangla = extractedName ? /[\u0980-\u09FF]/.test(extractedName) : false;

  return {
    fullName: extractedName,
    fullNameEn: extractedName && !isBangla ? extractedName : null,
    fullNameBn: extractedName && isBangla ? extractedName : null,
    dateOfBirth: dob,
    documentNumber: idMatch ? idMatch[1].trim() : null,
    fatherName: null,
    motherName: null,
    address: null,
  };
}

module.exports = {
  extractDocumentFields,
  parseBasicFieldsFromText,
  computeReadability,
};
