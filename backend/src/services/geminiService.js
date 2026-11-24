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

Important Bangladesh Government domain rules:
- Citizens often use colloquial or phonetic Banglish terms:
  * "Voter ID", "Boter ID", "Votar", "Botar", "Smart Card", "National ID", "ভোটার আইডি", "জাতীয় পরিচয়পত্র" refer to Service ID 2 (NID Correction / এনআইডি তথ্য সংশোধন).
  * "Jonmo", "Jonma", "বাচ্চা নিবন্ধন" refer to Service ID 1 (Birth Registration / জন্ম নিবন্ধন).
  * "Namjari", "Khariz", "Khatian", "Dalil", "জমির খারিজ" refer to Service ID 4 (e-Mutation / ই-নামজারি).
  * "Gari license", "Driving", "BRTA" refer to Service ID 7 (Driving License / ড্রাইভিং লাইসেন্স).
  * "Dokandari", "Trade" refer to Service ID 5 (Trade License / ট্রেড লাইসেন্স).

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
  let matched = null;
  let confidence = 0.75;

  if (lower.includes('পাসপোর্ট') || lower.includes('passport') || lower.includes('ভিসা') || lower.includes('visa')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 3);
    confidence = 0.95;
  } else if (
    lower.includes('এনআইডি') ||
    lower.includes('nid') ||
    lower.includes('ভোটার') ||
    lower.includes('voter') ||
    lower.includes('boter') ||
    lower.includes('votar') ||
    lower.includes('botar') ||
    lower.includes('smart card') ||
    lower.includes('স্মার্ট কার্ড') ||
    lower.includes('জাতীয় পরিচয়পত্র') ||
    lower.includes('national id') ||
    lower.includes('আইডি কার্ড') ||
    lower.includes('id card') ||
    lower.includes('সংশোধন')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 2);
    confidence = 0.96;
  } else if (
    lower.includes('ট্রেড') ||
    lower.includes('ব্যবসা') ||
    lower.includes('দোকান') ||
    lower.includes('trade') ||
    lower.includes('business')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 5);
    confidence = 0.92;
  } else if (
    lower.includes('জমি') ||
    lower.includes('নামজারি') ||
    lower.includes('খারিজ') ||
    lower.includes('দলিল') ||
    lower.includes('mutation') ||
    lower.includes('namjari') ||
    lower.includes('land')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 4);
    confidence = 0.94;
  } else if (
    lower.includes('জন্ম') ||
    lower.includes('birth') ||
    lower.includes('বাচ্চা') ||
    lower.includes('jonmo') ||
    lower.includes('jonma')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 1);
    confidence = 0.95;
  } else if (
    lower.includes('ড্রাইভিং') ||
    lower.includes('driving') ||
    lower.includes('ড্রাইভার') ||
    lower.includes('driver') ||
    lower.includes('লাইসেন্স') ||
    lower.includes('brta')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 7);
    confidence = 0.93;
  } else if (
    lower.includes('মৃত্যু') ||
    lower.includes('death') ||
    lower.includes('মারা') ||
    lower.includes('mrittu')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 6);
    confidence = 0.95;
  } else if (
    lower.includes('টিন') ||
    lower.includes('tin') ||
    lower.includes('কর') ||
    lower.includes('tax') ||
    lower.includes('incometax')
  ) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 8);
    confidence = 0.91;
  } else {
    matched = GOVERNMENT_CATALOG[0];
    confidence = 0.60;
  }

  const isBn = language === 'bn';
  let requiredDocs;
  let actionSteps;

  if (matched.id === 2) {
    requiredDocs = isBn
      ? ['১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদ', 'এসএসসি বা সমমানের শিক্ষাগত সনদ', 'পিতা ও মাতার এনআইডি ফটোকপি', 'নাগরিকত্ব প্রত্যয়নপত্র']
      : ['17-digit online birth certificate', 'SSC / Educational qualification certificate', "Parents' National ID photocopies", 'Citizenship certificate / Chairman verification'];
    actionSteps = isBn
      ? ['services.nidw.gov.bd ওয়েবসাইটে লগইন করে ভোটার/এনআইডি সেবা বেছে নিন', 'প্রয়োজনীয় সরকারি ফি পরিশোধ করুন', 'নির্বাচন অফিসে প্রয়োজনীয় কাগজপত্র জমা দিয়ে এনআইডি/স্মার্ট কার্ড গ্রহণ করুন']
      : ['Log in to services.nidw.gov.bd for voter/NID application or correction', 'Pay the designated government fee via mobile banking', 'Submit documents to the local election office to receive your NID/Smart card'];
  } else if (matched.id === 1) {
    requiredDocs = isBn
      ? ['শিশুর ইপিআই টিকা কার্ডের মূল ও সত্যায়িত কপি', 'পিতা-মাতার অনলাইন জন্ম নিবন্ধন ও এনআইডি', 'বাসার হোল্ডিং ট্যাক্স রশিদ বা ভাড়ার চুক্তিপত্র']
      : ["Child's EPI immunization card", "Parents' online birth certificates and NID", 'Holding tax receipt or rental agreement'];
    actionSteps = isBn
      ? ['bdris.gov.bd পোর্টালে গিয়ে অনলাইন জন্ম নিবন্ধনের আবেদন পূরণ করুন', 'আবেদনপত্র প্রিন্ট করে চালান ফি পরিশোধ করুন', 'ইউনিয়ন পরিষদ বা পৌরসভা কার্যালয়ে সনদ গ্রহণ করুন']
      : ['Fill out the online application at bdris.gov.bd', 'Print the application and pay designated fee', 'Collect official birth certificate from your local authority'];
  } else {
    requiredDocs = isBn
      ? ['জাতীয় পরিচয়পত্র / জন্ম নিবন্ধন সনদ', 'পাসপোর্ট সাইজ ছবি', 'প্রযোজ্য ক্ষেত্রে চালান কপি']
      : ['National ID / Birth Certificate', 'Passport size photographs', 'Payment receipt/challan'];
    actionSteps = isBn
      ? ['সংশ্লিষ্ট সরকারি পোর্টালে ফর্ম পূরণ করুন', 'প্রয়োজনীয় ফি জমা দিন', 'কাগজপত্র জমা দিয়ে সনদ সংগ্রহ করুন']
      : ['Fill out the application on the official portal', 'Pay the requisite government fees', 'Submit documents and receive approval'];
  }

  return {
    serviceId: matched.id,
    serviceName: matched.nameEn,
    serviceNameBn: matched.nameBn,
    confidence,
    summary: isBn
      ? `আপনার অনুরোধটি "${matched.nameBn}" সেবার সাথে মিলেছে।`
      : `Your request matches the "${matched.nameEn}" service.`,
    requiredDocuments: requiredDocs,
    steps: actionSteps,
    aiPowered: false,
  };
}

module.exports = {
  identifyServiceWithGemini,
  GOVERNMENT_CATALOG,
};
