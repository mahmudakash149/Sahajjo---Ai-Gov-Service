const path = require('path');
const dotenv = require('dotenv');
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const API_KEY = (process.env.GEMINI_API_KEY || '').trim();
const MODEL_NAME = 'gemini-3.5-flash-lite';

const GOVERNMENT_CATALOG = [
  { id: 1, nameBn: 'জন্ম নিবন্ধন', nameEn: 'Birth Registration', categoryBn: 'পরিচয় ও নিবন্ধন', categoryEn: 'Identity & Registration' },
  { id: 2, nameBn: 'এনআইডি তথ্য সংশোধন', nameEn: 'NID Correction', categoryBn: 'পরিচয় ও নিবন্ধন', categoryEn: 'Identity & Registration' },
  { id: 3, nameBn: 'পাসপোর্ট সেবা', nameEn: 'Passport Services', categoryBn: 'ভ্রমণ ও যানবাহন', categoryEn: 'Travel & Transport' },
  { id: 4, nameBn: 'ই-নামজারি', nameEn: 'e-Mutation', categoryBn: 'ভূমি সেবা', categoryEn: 'Land Services' },
  { id: 5, nameBn: 'ট্রেড লাইসেন্স', nameEn: 'Trade License', categoryBn: 'ব্যবসা', categoryEn: 'Business' },
  { id: 6, nameBn: 'মৃত্যু নিবন্ধন', nameEn: 'Death Registration', categoryBn: 'পরিচয় ও নিবন্ধন', categoryEn: 'Identity & Registration' },
  { id: 7, nameBn: 'ড্রাইভিং লাইসেন্স', nameEn: 'Driving License', categoryBn: 'ভ্রমণ ও যানবাহন', categoryEn: 'Travel & Transport' },
  { id: 8, nameBn: 'টিআইএন নিবন্ধন', nameEn: 'TIN Registration', categoryBn: 'ব্যবসা', categoryEn: 'Business' },
];

/**
 * Identify target government service using Google Gemini AI.
 * Returns structured JSON with service identification, confidence, documents, and guidelines.
 */
async function identifyServiceWithGemini(requestText, language = 'bn') {
  if (!API_KEY) {
    console.warn('[Gemini Service] No GEMINI_API_KEY found. Using fallback classifier.');
    return fallbackClassifier(requestText, language);
  }

  const prompt = `You are "Sahajjo AI", the smart Bangladesh Government Service Assistant.
A citizen has submitted a service request or question in ${language === 'bn' ? 'Bangla' : 'English'}:
"${requestText}"

Here is the official list of available government services:
${GOVERNMENT_CATALOG.map((s) => `${s.id}. ${s.nameEn} (${s.nameBn}) - Category: ${s.categoryEn}`).join('\n')}

Your task:
1. Analyze the citizen's need and identify which single service from the catalog best matches their request.
2. If it does not match any service specifically, select the closest service or ID 0 if unknown.
3. Provide a helpful, clear, and reassuring summary in ${language === 'bn' ? 'Bangla' : 'English'}.
4. List the essential documents (প্রয়োজনীয় কাগজপত্র) the citizen must prepare.
5. Provide a 3-step practical action plan for this citizen.

Respond ONLY with valid JSON in this EXACT structure (no markdown formatting, no code fences):
{
  "serviceId": 2,
  "serviceName": "NID Correction",
  "serviceNameBn": "এনআইডি তথ্য সংশোধন",
  "confidence": 0.95,
  "summary": "সংক্ষিপ্ত বিবরণ",
  "requiredDocuments": [
    "দলিল ১",
    "দলিল ২"
  ],
  "steps": [
    "ধাপ ১",
    "ধাপ ২",
    "ধাপ ৩"
  ]
}`;

  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 800,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok || !data.candidates || !data.candidates.length) {
      console.warn('[Gemini API Warning]', data.error ? data.error.message : 'No candidate returned');
      return fallbackClassifier(requestText, language);
    }

    const rawText = data.candidates[0].content.parts[0].text.trim();
    // Clean potential markdown fences ```json ... ```
    const cleaned = rawText.replace(/^```json\s*/i, '').replace(/```$/i, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      serviceId: parsed.serviceId || 1,
      serviceName: parsed.serviceName || 'General Service',
      serviceNameBn: parsed.serviceNameBn || 'সরকারি সেবা',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.9,
      summary: parsed.summary || '',
      requiredDocuments: Array.isArray(parsed.requiredDocuments) ? parsed.requiredDocuments : [],
      steps: Array.isArray(parsed.steps) ? parsed.steps : [],
      aiPowered: true,
    };
  } catch (err) {
    console.error('[Gemini Service Error]', err.message);
    return fallbackClassifier(requestText, language);
  }
}

/**
 * Intelligent local semantic fallback in case Gemini API is unreachable or rate limited.
 */
function fallbackClassifier(text, language = 'bn') {
  const lower = text.toLowerCase();
  let matched = GOVERNMENT_CATALOG[0];
  let confidence = 0.75;

  if (lower.includes('পাসপোর্ট') || lower.includes('passport') || lower.includes('ভিসা')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 3);
    confidence = 0.95;
  } else if (lower.includes('এনআইডি') || lower.includes('nid') || lower.includes('ভোটার') || lower.includes('আইডি কার্ড') || lower.includes('সংশোধন')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 2);
    confidence = 0.96;
  } else if (lower.includes('ট্রেড') || lower.includes('ব্যবসা') || lower.includes('দোকান') || lower.includes('লাইসেন্স') || lower.includes('trade')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 5);
    confidence = 0.92;
  } else if (lower.includes('জমি') || lower.includes('নামজারি') || lower.includes('খারিজ') || lower.includes('দলিল') || lower.includes('mutation')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 4);
    confidence = 0.94;
  } else if (lower.includes('জন্ম') || lower.includes('birth') || lower.includes('বাচ্চা')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 1);
    confidence = 0.95;
  } else if (lower.includes('ড্রাইভিং') || lower.includes('driving') || lower.includes('লাইসেন্স')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 7);
    confidence = 0.93;
  } else if (lower.includes('টিন') || lower.includes('tin') || lower.includes('কর')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 8);
    confidence = 0.91;
  }

  const isBn = language === 'bn';
  return {
    serviceId: matched.id,
    serviceName: matched.nameEn,
    serviceNameBn: matched.nameBn,
    confidence,
    summary: isBn
      ? `আপনার অনুরোধটি "${matched.nameBn}" সেবার সাথে মিলেছে।`
      : `Your request matches the "${matched.nameEn}" service.`,
    requiredDocuments: isBn
      ? ['জাতীয় পরিচয়পত্র / জন্ম নিবন্ধন সনদ', 'পাসপোর্ট সাইজ ছবি', 'প্রযোজ্য ক্ষেত্রে চালান কপি']
      : ['National ID / Birth Certificate', 'Passport size photographs', 'Payment receipt/challan'],
    steps: isBn
      ? ['সংশ্লিষ্ট সরকারি পোর্টালে ফর্ম পূরণ করুন', 'প্রয়োজনীয় ফি জমা দিন', 'কাগজপত্র জমা দিয়ে সনদ সংগ্রহ করুন']
      : ['Fill out the application on the official portal', 'Pay the requisite government fees', 'Submit documents and receive approval'],
    aiPowered: false,
  };
}

module.exports = {
  identifyServiceWithGemini,
  GOVERNMENT_CATALOG,
};
