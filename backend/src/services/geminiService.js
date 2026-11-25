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

// ==========================================
// 1. BIRTH REGISTRATION QUESTION BANK
// ==========================================
function getBirthRegistrationFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'birth_new_age',
      question: isBn ? 'যার নিবন্ধন করা হচ্ছে তার বয়স কত?' : 'What is the age group of the person being registered?',
      options: isBn
        ? ['নবজাতক (০–৪৫ দিন)', 'শিশু (৪৬ দিন থেকে ৫ বছর)', 'প্রাপ্তবয়স্ক (৫ বছরের ঊর্ধ্বে)', 'নিশ্চিত নই']
        : ['Newborn (0–45 days)', 'Child (46 days to 5 years)', 'Adult (Above 5 years)', 'Not sure'],
    },
    {
      id: 'birth_parents_cert',
      question: isBn ? 'পিতা ও মাতা উভয়ের কি ১৭-সংখ্যার অনলাইন ডিজিটাল জন্ম নিবন্ধন সনদ আছে?' : 'Do both parents have 17-digit verified online birth certificates?',
      options: isBn
        ? ['হ্যাঁ, উভয়ের আছে', 'শুধুমাত্র একজনের আছে', 'কারোরই অনলাইন সনদ নেই', 'নিশ্চিত নই']
        : ['Yes, both have', 'Only one has', 'Neither has online certificate', 'Not sure'],
    },
    {
      id: 'birth_new_docs',
      question: isBn ? 'আপনার কাছে বর্তমানে কী কী সহায়ক কাগজপত্র প্রস্তুত আছে?' : 'Which supporting documents do you currently have?',
      options: isBn
        ? ['ইপিআই (টিকা) কার্ড / হাসপাতালের ছাড়পত্র', 'পিতা-মাতার এনআইডি ও জন্ম সনদ', 'হোল্ডিং ট্যাক্স রশিদ / বিদ্যুৎ বিল', 'শিক্ষাগত সনদ (PSC/JSC/SSC)', 'উপরের কোনটিই নয়']
        : ['EPI Immunization Card / Hospital Discharge Slip', "Parents' NID & Birth Certificate", 'Holding Tax Receipt / Utility Bill', 'Educational Certificate (PSC/JSC/SSC)', 'None of the above'],
    },
  ];

  const correctionQuestions = [
    {
      id: 'birth_corr_which',
      question: isBn ? 'জন্ম নিবন্ধন সনদের কোন তথ্যটি সংশোধন করতে চান?' : 'Which information do you want to correct on the birth certificate?',
      options: isBn
        ? ['নামের বানান (নিজের/পিতামাতার)', 'জন্ম তারিখ', 'ঠিকানা', 'পিতামাতার তথ্য']
        : ['Name Spelling (Own/Parents)', 'Date of Birth', 'Address', "Parents' Information"],
    },
    {
      id: 'birth_corr_proof',
      question: isBn ? 'সংশোধনের স্বপক্ষে আপনার কাছে কী প্রমাণপত্র আছে?' : 'What supporting proof do you have for the correction?',
      options: isBn
        ? ['শিক্ষাগত বোর্ড সনদ', 'পাসপোর্ট', 'পিতা-মাতার সংশোধিত এনআইডি / জন্ম সনদ', 'মেডিকেল সার্টিফিকেট / বয়স নির্ধারণী সনদ', 'উপরের কোনটিই নয়']
        : ['Educational Board Certificate', 'Passport', "Parents' Corrected NID / Birth Certificate", 'Medical Certificate / Age Proof', 'None of the above'],
    },
    {
      id: 'birth_corr_original',
      question: isBn ? 'আপনার কাছে কি মূল ১৭-সংখ্যার ডিজিটাল জন্ম নিবন্ধন কপি আছে?' : 'Do you have the original digital 17-digit birth certificate copy?',
      options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
    },
  ];

  const isCorrection = /(সংশোধন|ভুল|correction|change|fix|update|বানান)/i.test(text);
  if (isCorrection) return correctionQuestions;

  const isNew = /(নতুন|new|বাচ্চা|শিশু|নবজাতক|baby|born|first time)/i.test(text);
  if (isNew) return newAppQuestions;

  // General Initial Common Question
  return [
    {
      id: 'birth_service_type',
      question: isBn ? 'জন্ম নিবন্ধন সেবার ধরন নির্বাচন করুন:' : 'Select birth registration service type:',
      options: isBn
        ? ['নতুন জন্ম নিবন্ধন', 'তথ্য সংশোধন', 'পুনরায় উত্তোলন / ইংরেজি কপি']
        : ['New Birth Registration', 'Information Correction', 'Re-issue / English Copy'],
      subQuestionsByOption: {
        'New Birth Registration': newAppQuestions,
        'নতুন জন্ম নিবন্ধন': newAppQuestions,
        'Information Correction': correctionQuestions,
        'তথ্য সংশোধন': correctionQuestions,
      },
    },
  ];
}

// ==========================================
// 2. NID FOLLOW-UP QUESTION BANK
// ==========================================
function getNidFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  // Lost NID Replacement
  const isLost = /(হারিয়ে|হারানো|harie|harano|lost|stolen|নষ্ট|replacement|duplicate)/i.test(text);
  if (isLost) {
    return [
      {
        id: 'nid_lost_number',
        question: isBn ? 'আপনার কি এনআইডি নম্বরটি মনে আছে?' : 'Do you remember your NID number?',
        options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
      },
      {
        id: 'nid_lost_copy',
        question: isBn ? 'আপনার কাছে কি এনআইডি কার্ডের কোনো ডিজিটাল বা অনলাইন কপি আছে?' : 'Do you have a digital or online copy of your NID card?',
        options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
      },
    ];
  }

  // New NID Application
  const isNew = /(নতুন|new|বানাব|banabo|first time|প্রথমবার|apply for nid|voter|ভোটার)/i.test(text) &&
    !/(সংশোধন|correction|fix|change|পরিবর্তন)/i.test(text);
  if (isNew) {
    return [
      {
        id: 'nid_new_age',
        question: isBn ? 'আপনার বর্তমান বয়স কত?' : 'What is your current age group?',
        options: isBn ? ['১৬–১৭ বছর', '১৮ বছর বা তার বেশি', 'নিশ্চিত নই'] : ['16–17 years', '18 years or older', 'Not sure'],
      },
      {
        id: 'nid_new_voter_before',
        question: isBn ? 'আপনি কি পূর্বে কখনো বাংলাদেশে ভোটার হিসেবে নিবন্ধিত হয়েছেন?' : 'Have you ever registered as a voter in Bangladesh before?',
        options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
      },
      {
        id: 'nid_new_docs',
        question: isBn ? 'আপনার কাছে বর্তমানে কী কী সহায়ক কাগজপত্র আছে?' : 'Which supporting documents do you currently have?',
        options: isBn
          ? ['জন্ম নিবন্ধন সনদ', 'শিক্ষাগত সনদ (SSC/JSC)', 'নাগরিকত্ব সনদ', 'পিতামাতার এনআইডি কার্ড', 'পাসপোর্ট', 'উপরের কোনটিই নয়']
          : ['Birth Registration Certificate', 'Educational Certificate (SSC/JSC)', 'Citizenship Certificate', "Parents' NID Card", 'Passport', 'None of the above'],
      },
    ];
  }

  const nameCorrectionQuestions = [
    {
      id: 'nid_name_whose',
      question: isBn ? 'কার নাম সংশোধন করতে চান?' : "Whose name do you want to correct?",
      options: isBn
        ? ["বাবার নাম", "মায়ের নাম", "নিজের নাম", "স্বামী/স্ত্রীর নাম"]
        : ["Father's Name", "Mother's Name", "Own Name", "Spouse's Name"],
    },
    {
      id: 'nid_name_docs',
      question: isBn ? 'সঠিক নাম প্রমাণের জন্য আপনার কাছে বর্তমানে কী কী সহায়ক কাগজপত্র আছে?' : 'What supporting document do you currently have to verify the correct name?',
      options: isBn
        ? ["পিতা/মাতার এনআইডি কার্ড (প্রযোজ্য ক্ষেত্রে)", "জন্ম নিবন্ধন সনদ", "শিক্ষাগত সনদ (SSC/JSC)", "পাসপোর্ট", "অন্যান্য সহায়ক কাগজপত্র", "উপরের কোনটিই নয়"]
        : ["Father's / Mother's NID Card (as applicable)", "Birth Registration Certificate", "Educational Certificate (SSC/JSC)", "Passport", "Other Supporting Documents", "None of the above"],
    },
    {
      id: 'nid_name_first_time',
      question: isBn ? 'আপনি কি এই নির্দিষ্ট এনআইডি সংশোধনের জন্য প্রথমবার আবেদন করছেন?' : 'Is this your first time applying for this specific NID correction?',
      options: isBn
        ? ['হ্যাঁ, প্রথমবার', 'না, পূর্বে বাতিল হয়েছিল', 'ইতিমধ্যে জমা দেওয়া হয়েছে']
        : ['Yes, first time', 'No, previously rejected', 'Already submitted'],
    },
  ];

  const dobCorrectionQuestions = [
    {
      id: 'nid_dob_docs',
      question: isBn ? 'আপনার সঠিক জন্ম তারিখ প্রমাণের জন্য বর্তমানে কী কী সহায়ক কাগজপত্র আছে?' : 'What supporting document do you currently have to verify your correct date of birth?',
      options: isBn
        ? ['জন্ম নিবন্ধন সনদ', 'শিক্ষাগত সনদ (SSC/JSC)', 'পাসপোর্ট', 'অন্যান্য সহায়ক কাগজপত্র', 'উপরের কোনটিই নয়']
        : ['Birth Registration Certificate', 'Educational Certificate (SSC/JSC)', 'Passport', 'Other Supporting Documents', 'None of the above'],
    },
    {
      id: 'nid_dob_first_time',
      question: isBn ? 'আপনি কি এই নির্দিষ্ট এনআইডি সংশোধনের জন্য প্রথমবার আবেদন করছেন?' : 'Is this your first time applying for this specific NID correction?',
      options: isBn
        ? ['হ্যাঁ, প্রথমবার', 'না, পূর্বে বাতিল হয়েছিল', 'ইতিমধ্যে জমা দেওয়া হয়েছে']
        : ['Yes, first time', 'No, previously rejected', 'Already submitted'],
    },
  ];

  const addressCorrectionQuestions = [
    {
      id: 'nid_address_which',
      question: isBn ? 'আপনি কোন ঠিকানা পরিবর্তন করতে চান?' : 'Which address do you want to change?',
      options: isBn
        ? ['বর্তমান ঠিকানা', 'স্থায়ী ঠিকানা', 'উভয় ঠিকানা']
        : ['Present Address', 'Permanent Address', 'Both Addresses'],
    },
    {
      id: 'nid_address_docs',
      question: isBn ? 'আপনার নতুন বা সঠিক ঠিকানার স্বপক্ষে বর্তমানে কী কী কাগজপত্র আছে?' : 'What supporting documents do you currently have for your new or correct address?',
      options: isBn
        ? ['ইউটিলিটি বিল', 'নাগরিকত্ব সনদ', 'হোল্ডিং ট্যাক্স রশিদ', 'অন্যান্য সহায়ক কাগজপত্র', 'উপরের কোনটিই নয়']
        : ['Utility Bill', 'Citizenship Certificate', 'Holding Tax Receipt', 'Other Supporting Documents', 'None of the above'],
    },
  ];

  const otherCorrectionQuestions = [
    {
      id: 'nid_other_which',
      question: isBn ? 'আপনি কোন তথ্যটি সংশোধন করতে চান?' : 'Which information do you want to correct?',
      options: isBn
        ? ['রক্তের গ্রুপ', 'বৈবাহিক অবস্থা', 'অন্যান্য ব্যক্তিগত তথ্য']
        : ['Blood Group', 'Marital Status', 'Other Personal Information'],
    },
    {
      id: 'nid_other_docs',
      question: isBn ? 'সঠিক তথ্য প্রমাণের জন্য আপনার কাছে কি প্রয়োজনীয় কাগজপত্র আছে?' : 'Do you have supporting documents to verify the correct information?',
      options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
    },
  ];

  const isName = /(নাম|name)/i.test(text);
  if (isName) {
    const hasWhoseName = /(বাবার|পিতার|father|মায়ের|মাতার|মা\s*এর|mother|স্বামী|স্ত্রী|spouse|নিজের\s*নাম|own\s*name)/i.test(text);
    if (hasWhoseName) {
      return nameCorrectionQuestions.slice(1);
    }
    return nameCorrectionQuestions;
  }

  const isDob = /(জন্ম তারিখ|বয়স|date of birth|dob|birth date|birthdate)/i.test(text);
  if (isDob) return dobCorrectionQuestions;

  const isAddress = /(ঠিকানা|address|বাসা|স্থানান্তর)/i.test(text);
  if (isAddress) return addressCorrectionQuestions;

  const isOther = /(রক্ত|blood|বৈবাহিক|marital|বিয়ে|divorce)/i.test(text);
  if (isOther) return otherCorrectionQuestions;

  return [
    {
      id: 'nid_correction_type',
      question: isBn ? 'আপনি কোন তথ্যটি সংশোধন করতে চান?' : 'Which information do you want to correct?',
      options: isBn
        ? ['নাম সংশোধন', 'জন্ম তারিখ সংশোধন', 'ঠিকানা পরিবর্তন', 'অন্যান্য তথ্য সংশোধন']
        : ['Name Correction', 'Date of Birth Correction', 'Address Correction', 'Other Information Correction'],
      subQuestionsByOption: {
        'Name Correction': nameCorrectionQuestions,
        'নাম সংশোধন': nameCorrectionQuestions,
        'Date of Birth Correction': dobCorrectionQuestions,
        'জন্ম তারিখ সংশোধন': dobCorrectionQuestions,
        'Address Correction': addressCorrectionQuestions,
        'ঠিকানা পরিবর্তন': addressCorrectionQuestions,
        'Other Information Correction': otherCorrectionQuestions,
        'অন্যান্য তথ্য সংশোধন': otherCorrectionQuestions,
      },
    },
  ];
}

// ==========================================
// 3. PASSPORT SERVICES QUESTION BANK
// ==========================================
function getPassportFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'passport_age_group',
      question: isBn ? 'আবেদনকারীর বয়স সীমা কত?' : 'What is your age group?',
      options: isBn
        ? ['প্রাপ্তবয়স্ক (১৮ বছর বা তার বেশি)', 'অপ্রাপ্তবয়স্ক (১৮ বছরের নিচে)', 'নিশ্চিত নই']
        : ['Adult (18 years or older)', 'Minor (Under 18 years)', 'Not sure'],
    },
    {
      id: 'passport_id_type',
      question: isBn ? 'আপনার কি জাতীয় পরিচয়পত্র (NID) অথবা ১৭-সংখ্যার অনলাইন জন্ম সনদ আছে?' : 'Do you have a National ID Card (NID) or 17-digit Online Birth Certificate?',
      options: isBn
        ? ['হ্যাঁ, এনআইডি আছে', 'হ্যাঁ, ১৭ ডিজিটের জন্ম সনদ আছে', 'উভয়টিই আছে', 'কোনটিই নেই']
        : ['Yes, have NID', 'Yes, have 17-digit Birth Certificate', 'Both', 'None'],
    },
    {
      id: 'passport_pages_validity',
      question: isBn ? 'পাসপোর্টের মেয়াদ ও পৃষ্ঠার সংখ্যা কত চান?' : 'What validity and page count do you prefer?',
      options: isBn
        ? ['৫ বছর (৪৮ পৃষ্ঠা)', '১০ বছর (৪৮ পৃষ্ঠা)', '১০ বছর (৬৪ পৃষ্ঠা)', 'নিশ্চিত নই']
        : ['5 Years (48 Pages)', '10 Years (48 Pages)', '10 Years (64 Pages)', 'Not sure'],
    },
  ];

  const renewalQuestions = [
    {
      id: 'passport_renewal_reason',
      question: isBn ? 'আপনার বর্তমান পাসপোর্টের অবস্থা কী?' : 'What is the current status of your existing passport?',
      options: isBn
        ? ['মেয়াদোত্তীর্ণ / মেয়াদ শেষের পথে', 'পৃষ্ঠা শেষ হয়ে গেছে', 'হারিয়ে গেছে বা ক্ষতিগ্রস্ত', 'তথ্য সংশোধন প্রয়োজন']
        : ['Expired / Nearing Expiry', 'Pages Exhausted', 'Lost or Damaged', 'Data Correction Required'],
    },
    {
      id: 'passport_has_old_copy',
      question: isBn ? 'আপনার কাছে কি পূর্বের মূল পাসপোর্ট এবং তার ফটোকপি আছে?' : 'Do you have the original existing passport and previous copies?',
      options: isBn
        ? ['হ্যাঁ, মূল পাসপোর্ট আছে', 'শুধুমাত্র ফটোকপি আছে', 'হারিয়ে গেছে (জিডি করা হয়েছে)', 'হারিয়ে গেছে (জিডি করা হয়নি)']
        : ['Yes, have original', 'Only photocopy available', 'Lost (GD filed)', 'Lost (No GD yet)'],
    },
  ];

  const isRenewal = /(নবায়ন|renew|renewal|মেয়াদ|reissue|রি-ইস্যু|হারিয়ে|lost)/i.test(text);
  if (isRenewal) return renewalQuestions;

  const isNew = /(নতুন|new|first time|প্রথমবার)/i.test(text);
  if (isNew) return newAppQuestions;

  return [
    {
      id: 'passport_service_type',
      question: isBn ? 'আপনার কোন ধরণের পাসপোর্ট সেবা প্রয়োজন?' : 'What type of passport service do you need?',
      options: isBn
        ? ['নতুন ই-পাসপোর্ট', 'পাসপোর্ট নবায়ন', 'হারানো পাসপোর্ট রি-ইস্যু']
        : ['New e-Passport', 'Passport Renewal', 'Lost Passport Re-issue'],
      subQuestionsByOption: {
        'New e-Passport': newAppQuestions,
        'নতুন ই-পাসপোর্ট': newAppQuestions,
        'Passport Renewal': renewalQuestions,
        'পাসপোর্ট নবায়ন': renewalQuestions,
        'Lost Passport Re-issue': renewalQuestions,
        'হারানো পাসপোর্ট রি-ইস্যু': renewalQuestions,
      },
    },
  ];
}

// ==========================================
// 4. E-MUTATION (ই-নামজারি) QUESTION BANK
// ==========================================
function getMutationFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const purchaseQuestions = [
    {
      id: 'mutation_has_deed',
      question: isBn ? 'আপনার কাছে কি মূল নিবন্ধিত দলিল বা সার্টিফাইড কপি আছে?' : 'Do you have the registered deed (মূল সাফ-কবলা দলিল)?',
      options: isBn
        ? ['হ্যাঁ, মূল দলিল আছে', 'সার্টিফাইড কপি আছে', 'দলিল এখনো পাইনি', 'নিশ্চিত নই']
        : ['Yes, original deed', 'Certified copy available', 'Deed not received yet', 'Not sure'],
    },
    {
      id: 'mutation_tax_cleared',
      question: isBn ? 'জমির হালনাগাদ খাজনা (দাখিলা) কি পরিশোধিত?' : 'Is the land revenue tax (হালনাগাদ দাখিলা/খাজনা) paid up to date?',
      options: isBn
        ? ['হ্যাঁ, হালনাগাদ পরিশোধিত', 'কয়েক বছর বকেয়া আছে', 'নিশ্চিত নই']
        : ['Yes, up to date', 'Unpaid for few years', 'Not sure'],
    },
    {
      id: 'mutation_khatian_chain',
      question: isBn ? 'পূর্ববর্তী খতিয়ানসমূহের ধারাবাহিক কপি (CS/SA/RS/BS) কি আপনার কাছে আছে?' : 'Do you have the previous CS/SA/RS/BS Khatian chain?',
      options: isBn
        ? ['হ্যাঁ, সকল খতিয়ান আছে', 'কিছু খতিয়ান আছে', 'কোনো খতিয়ান নেই', 'নিশ্চিত নই']
        : ['Yes, all khatians available', 'Partial khatians available', 'None available', 'Not sure'],
    },
  ];

  const inheritanceQuestions = [
    {
      id: 'mutation_has_warishan',
      question: isBn ? 'আপনার কাছে কি স্থানীয় কাউন্সিলর/চেয়ারম্যানের ওয়ারিশান সনদ আছে?' : 'Do you have the official Warishan Certificate (ওয়ারিশান সনদপত্র)?',
      options: isBn
        ? ['হ্যাঁ, সত্যায়িত সনদ আছে', 'আবেদন করেছি, এখনো পাইনি', 'নেই', 'নিশ্চিত নই']
        : ['Yes, verified certificate', 'Applied, pending', 'No', 'Not sure'],
    },
    {
      id: 'mutation_heir_agreement',
      question: isBn ? 'সকল বৈধ ওয়ারিশ কি নামজারি আবেদনের বিষয়ে একমত?' : 'Are all legal heirs mutually agreed on the mutation application?',
      options: isBn
        ? ['হ্যাঁ, সকলে একমত', 'ওয়ারিশদের মধ্যে বিরোধ আছে', 'এককভাবে আবেদন করছি']
        : ['Yes, mutually agreed', 'Dispute among heirs', 'Applying individually'],
    },
  ];

  const isInheritance = /(ওয়ারিশ|উত্তরাধিকার|warish|inheritance|বাবার জমি|পৈতৃক)/i.test(text);
  if (isInheritance) return inheritanceQuestions;

  const isPurchase = /(ক্রয়|কিনেছি|দলিল|saf-kabala|purchase|bought)/i.test(text);
  if (isPurchase) return purchaseQuestions;

  return [
    {
      id: 'mutation_acquisition_type',
      question: isBn ? 'জমির মালিকানা কীভাবে অর্জিত হয়েছে?' : 'How was the land ownership acquired?',
      options: isBn
        ? ['ক্রয়সূত্রে (সাব-কবলা দলিল)', 'ওয়ারিশসূত্রে (উত্তরাধিকার)', 'হেবা বা দানপত্র সূত্রে', 'আদালতের ডিগ্রি / অন্যান্য']
        : ['By Purchase (Deed)', 'By Inheritance (Warishan)', 'By Gift / Heba Deed', 'Court Decree / Other'],
      subQuestionsByOption: {
        'By Purchase (Deed)': purchaseQuestions,
        'ক্রয়সূত্রে (সাব-কবলা দলিল)': purchaseQuestions,
        'By Inheritance (Warishan)': inheritanceQuestions,
        'ওয়ারিশসূত্রে (উত্তরাধিকার)': inheritanceQuestions,
      },
    },
  ];
}

// ==========================================
// 5. TRADE LICENSE QUESTION BANK
// ==========================================
function getTradeLicenseFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'trade_area_jurisdiction',
      question: isBn ? 'আপনার ব্যবসা প্রতিষ্ঠানটি কোন প্রশাসনিক এলাকায় অবস্থিত?' : 'What administrative jurisdiction is your business located in?',
      options: isBn
        ? ['সিটি কর্পোরেশন (ঢাকা/চট্টগ্রাম ইত্যাদি)', 'পৌরসভা এলাকা', 'ইউনিয়ন পরিষদ', 'নিশ্চিত নই']
        : ['City Corporation (Dhaka/Chittagong/etc.)', 'Municipality (Pourashava)', 'Union Parishad', 'Not sure'],
    },
    {
      id: 'trade_business_structure',
      question: isBn ? 'ব্যবসা প্রতিষ্ঠানের মালিকানার ধরন কী?' : 'What is your business ownership structure?',
      options: isBn
        ? ['একক মালিকানা (Proprietorship)', 'অংশীদারি (Partnership)', 'লিমিটেড কোম্পানি (Limited Company)', 'নিশ্চিত নই']
        : ['Proprietorship (একক মালিকানা)', 'Partnership (অংশীদারি)', 'Limited Company (কোম্পানি)', 'Not sure'],
    },
    {
      id: 'trade_rental_agreement',
      question: isBn ? 'দোকান/অফিসের ভাড়ার চুক্তিপত্র বা জায়গার মালিকানা দলিল কি আছে?' : 'Do you have the commercial space rental agreement or ownership deed?',
      options: isBn
        ? ['হ্যাঁ, নন-জুডিশিয়াল স্ট্যাম্পে চুক্তিপত্র আছে', 'নিজের বাণিজ্যিক জায়গা', 'প্রক্রিয়াধীন আছে', 'নেই']
        : ['Yes, signed agreement on non-judicial stamp', 'Own commercial space', 'In progress', 'No'],
    },
  ];

  const renewalQuestions = [
    {
      id: 'trade_previous_doc',
      question: isBn ? 'পূর্ববর্তী বছরের মূল ট্রেড লাইসেন্স ও ট্যাক্স জমার চালান কি আছে?' : "Do you have previous year's trade license and tax challan receipt?",
      options: isBn
        ? ['হ্যাঁ, উভয়টি আছে', 'শুধুমাত্র লাইসেন্স নম্বর আছে', 'আগের লাইসেন্স হারিয়ে গেছে', 'নিশ্চিত নই']
        : ['Yes, have both', 'Have license number only', 'Lost previous license', 'Not sure'],
    },
    {
      id: 'trade_due_status',
      question: isBn ? 'বিগত অর্থবছরগুলোর কোনো বকেয়া ফি আছে কি?' : 'Are there any pending dues for past financial years?',
      options: isBn
        ? ['না, সম্পূর্ণ পরিশোধিত', '১–২ বছর বকেয়া', '৩ বছরের বেশি বকেয়া', 'নিশ্চিত নই']
        : ['No, fully cleared', '1–2 years overdue', '3+ years overdue', 'Not sure'],
    },
  ];

  const isRenewal = /(নবায়ন|renew|renewal|মেয়াদ শেষ)/i.test(text);
  if (isRenewal) return renewalQuestions;

  const isNew = /(নতুন|new|দোকান|চালু|খুলব|start|open)/i.test(text);
  if (isNew) return newAppQuestions;

  return [
    {
      id: 'trade_service_type',
      question: isBn ? 'ট্রেড লাইসেন্স আবেদনের ধরন নির্বাচন করুন:' : 'Select trade license application type:',
      options: isBn
        ? ['নতুন ট্রেড লাইসেন্স', 'লাইসেন্স নবায়ন', 'তথ্য বা ঠিকানা পরিবর্তন']
        : ['New Trade License', 'License Renewal', 'Information / Address Change'],
      subQuestionsByOption: {
        'New Trade License': newAppQuestions,
        'নতুন ট্রেড লাইসেন্স': newAppQuestions,
        'License Renewal': renewalQuestions,
        'লাইসেন্স নবায়ন': renewalQuestions,
      },
    },
  ];
}

// ==========================================
// 6. DEATH REGISTRATION QUESTION BANK
// ==========================================
function getDeathRegistrationFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'death_timeline_passed',
      question: isBn ? 'মৃত্যুর পর কত দিন অতিবাহিত হয়েছে?' : 'How many days have passed since the demise?',
      options: isBn
        ? ['৩০ দিনের মধ্যে (নিয়মিত)', '৩১ দিন থেকে ২ বছরের মধ্যে', '২ বছরের অধিক', 'নিশ্চিত নই']
        : ['Within 30 days (Free/Regular)', '31 days to 2 years', 'More than 2 years', 'Not sure'],
    },
    {
      id: 'death_place_occurred',
      question: isBn ? 'মৃত্যু কোথায় সংঘটিত হয়েছে?' : 'Where did the death occur?',
      options: isBn
        ? ['হাসপাতাল / মেডিকেল ক্লিনিক', 'বাসাবাড়ি / নিজ গৃহে', 'বিদেশে (প্রবাসী)', 'অন্যান্য']
        : ['Hospital / Medical Clinic', 'At Residence / Home', 'Abroad (Expatriate)', 'Other'],
    },
    {
      id: 'death_proof_docs',
      question: isBn ? 'মৃত্যুর স্বপক্ষে কী কী কাগজপত্র প্রস্তুত আছে?' : 'Which death proof documents do you have ready?',
      options: isBn
        ? ['হাসপাতালের ডেথ সার্টিফিকেট / স্লিপ', 'দাফন / সৎকারের রশিদ (গোরস্থান/শ্মশান)', 'কাউন্সিলর / চেয়ারম্যানের প্রত্যয়নপত্র', 'উপরের কোনটিই নয়']
        : ['Hospital Death Certificate / Slip', 'Burial / Cremation Receipt', 'Councilor / Chairman Verification', 'None of the above'],
    },
  ];

  const correctionQuestions = [
    {
      id: 'death_corr_which',
      question: isBn ? 'মৃত্যু সনদের কোন তথ্য সংশোধন করতে চান?' : 'Which information needs correction?',
      options: isBn
        ? ['নাম / পিতার নাম', 'মৃত্যুর তারিখ বা কারণ', 'মৃত্যুর স্থান', 'ঠিকানা']
        : ["Name / Father's Name", 'Date or Cause of Death', 'Place of Death', 'Address'],
    },
    {
      id: 'death_has_original',
      question: isBn ? 'আপনার কাছে কি বিদ্যমান মূল মৃত্যু সনদ আছে?' : 'Do you have the original death registration certificate?',
      options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
    },
  ];

  const isCorrection = /(সংশোধন|correction|ভুল|change)/i.test(text);
  if (isCorrection) return correctionQuestions;

  const isNew = /(নতুন|new|মারা গেছেন|death|demise|ইন্তেকাল)/i.test(text);
  if (isNew) return newAppQuestions;

  return [
    {
      id: 'death_service_type',
      question: isBn ? 'মৃত্যু নিবন্ধন সেবার ধরন নির্বাচন করুন:' : 'Select death registration service type:',
      options: isBn
        ? ['নতুন মৃত্যু নিবন্ধন', 'সনদ তথ্য সংশোধন', 'পুনরায় উত্তোলন / ইংরেজি সনদ']
        : ['New Death Registration', 'Certificate Correction', 'Re-issue / English Certificate'],
      subQuestionsByOption: {
        'New Death Registration': newAppQuestions,
        'নতুন মৃত্যু নিবন্ধন': newAppQuestions,
        'Certificate Correction': correctionQuestions,
        'সনদ তথ্য সংশোধন': correctionQuestions,
      },
    },
  ];
}

// ==========================================
// 7. DRIVING LICENSE QUESTION BANK
// ==========================================
function getDrivingLicenseFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'driving_license_class',
      question: isBn ? 'কোন শ্রেণীর ড্রাইভিং লাইসেন্সের জন্য আবেদন করতে চান?' : 'What class of driving license do you want to apply for?',
      options: isBn
        ? ['অপেশাদার (হালকা যান / মোটরসাইকেল)', 'পেশাদার (ভারী বা মাঝারি যান)', 'শুধুমাত্র মোটরসাইকেল', 'নিশ্চিত নই']
        : ['Non-Professional (Light / Motorcycle)', 'Professional (Medium / Heavy)', 'Motorcycle Only', 'Not sure'],
    },
    {
      id: 'driving_medical_fitness',
      question: isBn ? 'আপনার কাছে কি রেজিস্টার্ড চিকিৎসকের মেডিকেল সার্টিফিকেট (ফরম খ) আছে?' : 'Do you have a registered Medical Fitness Certificate (ডাক্তারি প্রত্যয়ন)?',
      options: isBn
        ? ['হ্যাঁ, প্রস্তুত আছে', 'অনুমোদিত ডাক্তার থেকে সংগ্রহ করব', 'নিশ্চিত নই']
        : ['Yes, ready', 'Will obtain from approved doctor', 'Not sure'],
    },
    {
      id: 'driving_learner_status',
      question: isBn ? 'আপনি কি বিআরটিএ শিক্ষানবিশ (Learner) পারমিট সম্পন্ন করেছেন?' : 'Have you completed or registered for the BRTA Learner Permit?',
      options: isBn
        ? ['হ্যাঁ, সক্রিয় লার্নার পারমিট আছে', 'এখনই লার্নারের আবেদন করব', 'লার্নারের মেয়াদ শেষ', 'নিশ্চিত নই']
        : ['Yes, have active learner permit', 'Applying for learner permit now', 'Learner expired', 'Not sure'],
    },
  ];

  const renewalQuestions = [
    {
      id: 'driving_renewal_status',
      question: isBn ? 'নবায়নের কারণ বা লাইসেন্সের বর্তমান অবস্থা কী?' : 'What is your renewal reason or license state?',
      options: isBn
        ? ['১ বছরের মধ্যে মেয়াদোত্তীর্ণ', '১ বছরের বেশি মেয়াদোত্তীর্ণ (জরিমানা প্রযোজ্য)', 'স্মার্ট কার্ড হারিয়ে বা নষ্ট হয়ে গেছে', 'ঠিকানা বা ক্যাটাগরি পরিবর্তন']
        : ['Expired within 1 year', 'Expired over 1 year (Fine applicable)', 'Lost / Damaged Smart Card', 'Address / Category Update'],
    },
    {
      id: 'driving_prev_card',
      question: isBn ? 'আপনার পূর্বের ড্রাইভিং লাইসেন্স রেফারেন্স বা কার্ডের কপি কি আছে?' : 'Do you have your previous driving license reference / smart card copy?',
      options: isBn
        ? ['হ্যাঁ, স্মার্ট কার্ড হাতে আছে', 'শুধুমাত্র লাইসেন্স নম্বর/ছবি আছে', 'হারিয়ে গেছে (জিডি করা আছে)', 'নেই']
        : ['Yes, smart card in hand', 'Have license number / photo only', 'Lost (GD done)', 'No'],
    },
  ];

  const isRenewal = /(নবায়ন|renew|renewal|মেয়াদ শেষ|হারিয়ে|lost)/i.test(text);
  if (isRenewal) return renewalQuestions;

  const isNew = /(নতুন|new|লার্নার|learner|শিখছি|apply)/i.test(text);
  if (isNew) return newAppQuestions;

  return [
    {
      id: 'driving_service_type',
      question: isBn ? 'ড্রাইভিং লাইসেন্স সেবার ধরন নির্বাচন করুন:' : 'Select driving license service type:',
      options: isBn
        ? ['নতুন লাইসেন্স (লার্নার)', 'লাইসেন্স নবায়ন', 'হারানো স্মার্ট কার্ড উত্তোলন']
        : ['New License (Learner)', 'License Renewal', 'Lost Smart Card Re-issue'],
      subQuestionsByOption: {
        'New License (Learner)': newAppQuestions,
        'নতুন লাইসেন্স (লার্নার)': newAppQuestions,
        'License Renewal': renewalQuestions,
        'লাইসেন্স নবায়ন': renewalQuestions,
      },
    },
  ];
}

// ==========================================
// 8. TIN REGISTRATION QUESTION BANK
// ==========================================
function getTinRegistrationFollowUpBank(requestText = '', language = 'bn') {
  const isBn = language === 'bn';
  const text = (requestText || '').toLowerCase();

  const newAppQuestions = [
    {
      id: 'tin_purpose_type',
      question: isBn ? 'টিআইএন নিবন্ধনের মূল উদ্দেশ্য কী?' : 'What is the purpose of registering for a TIN?',
      options: isBn
        ? ['ব্যক্তিগত আয়কর রিটার্ন দাখিল', 'ব্যবসা বা কোম্পানি পরিচালনা', 'ব্যাংক ঋণ / সঞ্চয়পত্র / ক্রেডিট কার্ড', 'গাড়ি নিবন্ধন / জমি ক্রয়-বিক্রয়']
        : ['Individual Income Tax Return', 'Business / Company Operations', 'Bank Loan / Sanchayapatra / Credit Card', 'Vehicle Registration / Land Purchase'],
    },
    {
      id: 'tin_applicant_type',
      question: isBn ? 'আবেদনকারীর ধরন কী?' : 'What is the applicant type?',
      options: isBn
        ? ['ব্যক্তিগত বাংলাদেশি (এনআইডিধারী)', 'এনআইডি বিহীন ব্যক্তি (পাসপোর্ট)', 'কোম্পানি / ফার্ম', 'নিশ্চিত নই']
        : ['Individual Bangladeshi (having NID)', 'Individual without NID (Passport)', 'Company / Partnership Firm', 'Not sure'],
    },
    {
      id: 'tin_biometric_sim',
      question: isBn ? 'আপনার মোবাইল নম্বরটি কি নিজের এনআইডি দিয়ে বায়োমেট্রিক নিবন্ধিত?' : 'Is your mobile number registered with your own NID (বায়োমেট্রিক সিম)?',
      options: isBn ? ['হ্যাঁ', 'না / অন্যের নামে নিবন্ধিত', 'নিশ্চিত নই'] : ['Yes', 'No / Registered with someone else', 'Not sure'],
    },
  ];

  const updateQuestions = [
    {
      id: 'tin_help_type',
      question: isBn ? 'বিদ্যমান টিআইএন নিয়ে কী সহায়তা প্রয়োজন?' : 'What assistance do you need with your existing TIN?',
      options: isBn
        ? ['টিআইএন ভুলে গেছি / সার্টিফিকেট পুনর্মুদ্রণ', 'সার্কেল বা কর অঞ্চল পরিবর্তন', 'মোবাইল বা ইমেইল আপডেট', 'টিআইএন বাতিল / নিষ্ক্রিয়করণ']
        : ['Forgot TIN / Re-print Certificate', 'Change Circle / Tax Zone', 'Update Mobile / Email', 'Cancel / Deactivate TIN'],
    },
    {
      id: 'tin_remember_num',
      question: isBn ? 'আপনার কি ১২-সংখ্যার ই-টিআইএন নম্বরটি মনে আছে?' : 'Do you remember your 12-digit e-TIN number?',
      options: isBn ? ['হ্যাঁ', 'না', 'নিশ্চিত নই'] : ['Yes', 'No', 'Not sure'],
    },
  ];

  const isNew = /(নতুন|new|টিন করব|tin lagbe|আয়কর|রিটার্ন)/i.test(text);
  if (isNew) return newAppQuestions;

  const isUpdate = /(পুনর্মুদ্রণ|রিপ্রিন্ট|reprint|ভুলে গেছি|হারিয়ে|change|আপডেট|সার্কেল|বাতিল)/i.test(text);
  if (isUpdate) return updateQuestions;

  return [
    {
      id: 'tin_service_type',
      question: isBn ? 'টিআইএন সেবার ধরন নির্বাচন করুন:' : 'Select TIN service type:',
      options: isBn
        ? ['নতুন ই-টিআইএন নিবন্ধন', 'টিআইএন সার্টিফিকেট পুনর্মুদ্রণ', 'কর অঞ্চল / তথ্য আপডেট']
        : ['New e-TIN Registration', 'Re-print TIN Certificate', 'Tax Zone / Info Update'],
      subQuestionsByOption: {
        'New e-TIN Registration': newAppQuestions,
        'নতুন ই-টিআইএন নিবন্ধন': newAppQuestions,
        'Re-print TIN Certificate': updateQuestions,
        'টিআইএন সার্টিফিকেট পুনর্মুদ্রণ': updateQuestions,
      },
    },
  ];
}

/**
 * Service-specific default follow-up questions dispatching to each respective bank
 */
function getCatalogFollowUpQuestions(serviceId, language = 'bn', requestText = '') {
  switch (serviceId) {
    case 1:
      return getBirthRegistrationFollowUpBank(requestText, language);
    case 2:
      return getNidFollowUpBank(requestText, language);
    case 3:
      return getPassportFollowUpBank(requestText, language);
    case 4:
      return getMutationFollowUpBank(requestText, language);
    case 5:
      return getTradeLicenseFollowUpBank(requestText, language);
    case 6:
      return getDeathRegistrationFollowUpBank(requestText, language);
    case 7:
      return getDrivingLicenseFollowUpBank(requestText, language);
    case 8:
      return getTinRegistrationFollowUpBank(requestText, language);
    default:
      return getNidFollowUpBank(requestText, language);
  }
}

/**
 * Identify target government service using Google Gemini AI.
 * Returns structured JSON with service identification, confidence, documents, guidelines,
 * and follow-up clarifying questions (FR6).
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
6. [FR6 Follow-up Questions]:
   Generate 1 to 3 targeted, highly relevant follow-up questions with 2 to 4 concise multiple-choice options each in ${language === 'bn' ? 'Bangla' : 'English'}.
   For NID, Birth Registration, Passport, e-Mutation, Trade License, Death Registration, Driving License, or TIN:
   Align strictly with standard Bangladesh Government processing (distinguish new application vs renewal/correction, age group, administrative jurisdiction, and document availability).

Respond ONLY with valid JSON in this EXACT structure (no markdown formatting, no code fences):
{
  "serviceId": 2,
  "serviceName": "NID Correction",
  "serviceNameBn": "এনআইডি তথ্য সংশোধন",
  "confidence": 0.88,
  "summary": "সংক্ষিপ্ত বিবরণ",
  "requiredDocuments": [
    "দলিল ১",
    "দলিল ২"
  ],
  "steps": [
    "ধাপ ১",
    "ধাপ ২",
    "ধাপ ৩"
  ],
  "followUpQuestions": [
    {
      "id": "q1",
      "question": "প্রশ্ন ১",
      "options": ["বিকল্প ১", "বিকল্প ২", "বিকল্প ৩"]
    }
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
          temperature: 0.15,
          maxOutputTokens: 1100,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok || !data.candidates || !data.candidates.length) {
      console.warn('[Gemini API Warning]', data.error ? data.error.message : 'No candidate returned');
      return fallbackClassifier(requestText, language);
    }

    const rawText = data.candidates[0].content.parts[0].text.trim();
    const cleaned = rawText.replace(/^```json\s*/i, '').replace(/```$/i, '').trim();
    const parsed = JSON.parse(cleaned);

    const serviceId = parsed.serviceId || 1;
    let followUpQuestions = Array.isArray(parsed.followUpQuestions) && parsed.followUpQuestions.length > 0
      ? parsed.followUpQuestions
      : getCatalogFollowUpQuestions(serviceId, language, requestText);

    return {
      serviceId,
      serviceName: parsed.serviceName || 'General Service',
      serviceNameBn: parsed.serviceNameBn || 'সরকারি সেবা',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.88,
      summary: parsed.summary || '',
      requiredDocuments: Array.isArray(parsed.requiredDocuments) ? parsed.requiredDocuments : [],
      steps: Array.isArray(parsed.steps) ? parsed.steps : [],
      followUpQuestions,
      aiPowered: true,
    };
  } catch (err) {
    console.error('[Gemini Service Error]', err.message);
    return fallbackClassifier(requestText, language);
  }
}

/**
 * Refine government service diagnosis using citizen's answers to follow-up questions (FR6).
 * Re-runs analysis with increased confidence and tailored guidelines.
 */
async function refineServiceWithGemini(originalRequest, previousDiagnosis, answers, language = 'bn') {
  if (!API_KEY) {
    return refineFallbackClassifier(originalRequest, previousDiagnosis, answers, language);
  }

  const isBn = language === 'bn';
  const answersText = Array.isArray(answers)
    ? answers.map((a, i) => `${i + 1}. Question: "${a.question || a.questionId}" -> Citizen Answer: "${a.answer}"`).join('\n')
    : JSON.stringify(answers);

  const prompt = `You are "Sahajjo AI", the smart Bangladesh Government Service Assistant.
A citizen previously submitted: "${originalRequest}"
Previously identified service: ${previousDiagnosis?.serviceNameEn || previousDiagnosis?.serviceName} (${previousDiagnosis?.serviceNameBn})

The citizen has now provided the following clarifying answers to your follow-up questions:
${answersText}

Your task:
1. Re-analyze the citizen's need with these precise details.
2. Provide a refined, definitive action plan and specific list of required documents for this exact scenario in ${isBn ? 'Bangla' : 'English'}.
3. Increase the confidence score (0.95 to 0.99) since specific details are now clarified.
4. Any remaining unresolved follow-up questions (or empty array [] if everything needed is now clear).

Respond ONLY with valid JSON in this EXACT structure (no markdown formatting, no code fences):
{
  "serviceId": ${previousDiagnosis?.serviceId || 1},
  "serviceName": "${previousDiagnosis?.serviceName || 'Service'}",
  "serviceNameBn": "${previousDiagnosis?.serviceNameBn || 'সরকারি সেবা'}",
  "confidence": 0.98,
  "summary": "আপডেটকৃত সংক্ষিপ্ত বিবরণ",
  "requiredDocuments": [
    "নির্দিষ্ট প্রয়োজনীয় দলিল ১",
    "নির্দিষ্ট প্রয়োজনীয় দলিল ২"
  ],
  "steps": [
    "নির্দিষ্ট ধাপ ১",
    "নির্দিষ্ট ধাপ ২",
    "নির্দিষ্ট ধাপ ৩"
  ],
  "followUpQuestions": [],
  "clarifiedDetails": ${JSON.stringify(answers)}
}`;

  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${API_KEY}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.15,
          maxOutputTokens: 1000,
        },
      }),
    });

    const data = await response.json();
    if (!response.ok || !data.candidates || !data.candidates.length) {
      return refineFallbackClassifier(originalRequest, previousDiagnosis, answers, language);
    }

    const rawText = data.candidates[0].content.parts[0].text.trim();
    const cleaned = rawText.replace(/^```json\s*/i, '').replace(/```$/i, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      serviceId: parsed.serviceId || previousDiagnosis?.serviceId || 1,
      serviceName: parsed.serviceName || previousDiagnosis?.serviceName || 'General Service',
      serviceNameBn: parsed.serviceNameBn || previousDiagnosis?.serviceNameBn || 'সরকারি সেবা',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.98,
      summary: parsed.summary || previousDiagnosis?.summary || '',
      requiredDocuments: Array.isArray(parsed.requiredDocuments) ? parsed.requiredDocuments : (previousDiagnosis?.requiredDocuments || []),
      steps: Array.isArray(parsed.steps) ? parsed.steps : (previousDiagnosis?.steps || []),
      followUpQuestions: Array.isArray(parsed.followUpQuestions) ? parsed.followUpQuestions : [],
      clarifiedDetails: answers,
      aiPowered: true,
      refined: true,
    };
  } catch (err) {
    console.warn('[Gemini Refine Error]', err.message);
    return refineFallbackClassifier(originalRequest, previousDiagnosis, answers, language);
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
    confidence = 0.92;
  } else if (lower.includes('এনআইডি') || lower.includes('nid') || lower.includes('ভোটার') || lower.includes('আইডি কার্ড') || lower.includes('সংশোধন')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 2);
    confidence = 0.92;
  } else if (lower.includes('ট্রেড') || lower.includes('ব্যবসা') || lower.includes('দোকান') || lower.includes('লাইসেন্স') || lower.includes('trade')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 5);
    confidence = 0.90;
  } else if (lower.includes('জমি') || lower.includes('নামজারি') || lower.includes('খারিজ') || lower.includes('দলিল') || lower.includes('mutation')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 4);
    confidence = 0.92;
  } else if (lower.includes('জন্ম') || lower.includes('birth') || lower.includes('বাচ্চা')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 1);
    confidence = 0.92;
  } else if (lower.includes('মৃত্যু') || lower.includes('death') || lower.includes('মারা')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 6);
    confidence = 0.93;
  } else if (lower.includes('ড্রাইভিং') || lower.includes('driving') || lower.includes('লার্নার')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 7);
    confidence = 0.90;
  } else if (lower.includes('টিন') || lower.includes('tin') || lower.includes('কর') || lower.includes('রিটার্ন')) {
    matched = GOVERNMENT_CATALOG.find((s) => s.id === 8);
    confidence = 0.90;
  }

  const isBn = language === 'bn';
  const followUpQuestions = getCatalogFollowUpQuestions(matched.id, language, text);

  return {
    serviceId: matched.id,
    serviceName: matched.nameEn,
    serviceNameBn: matched.nameBn,
    confidence,
    summary: isBn
      ? `আপনার অনুরোধটি "${matched.nameBn}" সেবার সাথে মিলেছে। অধিকতর সুনির্দিষ্ট নির্দেশনার জন্য নিচের প্রশ্নগুলোর উত্তর নির্বাচন করুন।`
      : `Your request matches the "${matched.nameEn}" service. Please answer the follow-up question below for more specific guidelines.`,
    requiredDocuments: isBn
      ? ['জাতীয় পরিচয়পত্র / জন্ম নিবন্ধন সনদ', 'পাসপোর্ট সাইজ ছবি', 'প্রযোজ্য ক্ষেত্রে চালান কপি']
      : ['National ID / Birth Certificate', 'Passport size photographs', 'Payment receipt/challan'],
    steps: isBn
      ? ['সংশ্লিষ্ট সরকারি পোর্টালে ফর্ম পূরণ করুন', 'প্রয়োজনীয় ফি জমা দিন', 'কাগজপত্র জমা দিয়ে সনদ সংগ্রহ করুন']
      : ['Fill out the application on the official portal', 'Pay the requisite government fees', 'Submit documents and receive approval'],
    followUpQuestions,
    aiPowered: false,
  };
}

/**
 * Comprehensive Fallback Refinement across all Bangladesh Government services (FR6)
 */
function refineFallbackClassifier(originalRequest, previousDiagnosis, answers, language = 'bn') {
  const isBn = language === 'bn';
  const serviceId = previousDiagnosis?.serviceId || 1;
  const answerStr = JSON.stringify(answers || []);

  let refinedDocs = isBn
    ? ['জাতীয় পরিচয়পত্র ও ডিজিটাল জন্ম নিবন্ধন সনদ', 'প্রযোজ্য ক্ষেত্রে চালান কপি ও সত্যায়িত প্রমাণপত্র']
    : ['National ID & digital birth registration copy', 'Government payment challan & attested proofs'];
  let refinedSteps = isBn
    ? ['নির্দিষ্ট ক্যাটাগরি অনুযায়ী অনলাইনে নির্ভুল আবেদন করুন', 'প্রয়োজনীয় চালান ফি পরিশোধ করে প্রিন্ট কপি সংগ্রহ করুন', 'মূল প্রমাণপত্রসহ সংশ্লিষ্ট অফিসে জমা দিন']
    : ['Complete online application as per your selected category', 'Pay government fee and retain challan receipt', 'Submit hard copy with original proofs to the registrar office'];

  // 1. Birth Registration
  if (serviceId === 1 || answerStr.includes('birth_')) {
    if (answerStr.includes('নবজাতক') || answerStr.includes('Newborn')) {
      refinedDocs = isBn
        ? ['হাসপাতালের ছাড়পত্র / ইপিআই (টিকা) কার্ডের মূল ও সত্যায়িত ফটোকপি', 'পিতা ও মাতার ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন ও এনআইডি', 'বাসার হোল্ডিং ট্যাক্স রশিদ বা হালনাগাদ ভাড়ার চুক্তিপত্র']
        : ["Hospital discharge slip / Child's EPI card (original & attested)", "Parents' 17-digit online birth certificates & NIDs", 'Holding tax receipt or rental agreement'];
      refinedSteps = isBn
        ? ['bdris.gov.bd পোর্টালে ৪৫ দিনের মধ্যে বিনামূল্যে আবেদন ফরম পূরণ করুন', 'আবেদনপত্রের প্রিন্ট কপি ও ইপিআই কার্ডের সত্যায়িত কপি প্রস্তুত করুন', 'ইউনিয়ন পরিষদ বা ওয়ার্ড কাউন্সিলর অফিসে জমা দিয়ে সনদ গ্রহণ করুন']
        : ['Fill out application on bdris.gov.bd within 45 days (free of fee)', 'Print application form and attach attested EPI card photocopy', 'Submit to Union Parishad / Ward Councilor office to receive certificate'];
    } else if (answerStr.includes('সংশোধন') || answerStr.includes('Correction')) {
      refinedDocs = isBn
        ? ['মূল ১৭ ডিজিটের ডিজিটাল জন্ম নিবন্ধন সনদের কপি', 'শিক্ষাগত বোর্ড সনদ (PSC/JSC/SSC) অথবা পাসপোর্ট', 'পিতা-মাতার সংশোধিত এনআইডি ও অনলাইন জন্ম সনদ', 'স্থানীয় কাউন্সিলর প্রত্যয়নপত্র']
        : ['17-digit digital birth registration certificate copy', 'Educational board certificate (PSC/JSC/SSC) or passport', "Parents' corrected NID & birth certificate", 'Local councilor verification certificate'];
      refinedSteps = isBn
        ? ['bdris.gov.bd-এ "জন্ম তথ্য সংশোধন" নির্বাচন করে প্রয়োজনীয় তথ্য আপডেট করুন', 'প্রমাণের স্বপক্ষে স্ক্যান করা কাগজপত্র আপলোড করুন ও চালান ফি পরিশোধ করুন', 'আবেদন প্রিন্ট করে নিবন্ধক কার্যালয়ে মূল কাগজপত্রসহ দাখিল করুন']
        : ['Select "Birth Information Correction" on bdris.gov.bd and update details', 'Upload scanned proof documents and pay official challan fee', 'Submit printed application with originals to the registrar office'];
    }
  }

  // 2. NID Services
  else if (serviceId === 2 || answerStr.includes('nid_')) {
    if (answerStr.includes('১৬–১৭') || answerStr.includes('16–17')) {
      refinedDocs = isBn
        ? ['অনলাইন ডিজিটাল জন্ম নিবন্ধন সনদ (১৭ ডিজিট)', 'পিতামাতার জাতীয় পরিচয়পত্রের কপি', 'নাগরিকত্ব ও শিক্ষাগত সনদ (JSC/SSC)']
        : ['17-digit online birth registration certificate', "Parents' National ID copies", 'Citizenship certificate & educational certificate (JSC/SSC)'];
      refinedSteps = isBn
        ? ['services.nidw.gov.bd-এ অগ্রিম ভোটার নিবন্ধন ফরম পূরণ করুন', 'উপজেলা নির্বাচন অফিসে গিয়ে বায়োমেট্রিক ও ছবি প্রদান করুন', '১৮ বছর পূর্ণ হলে জাতীয় পরিচয়পত্র স্বয়ংক্রিয়ভাবে সক্রিয় হবে']
        : ['Complete advance voter registration on services.nidw.gov.bd', 'Provide biometrics and photograph at Upazila Election Office', 'NID card will activate automatically upon turning 18'];
    } else if (answerStr.includes('হারিয়ে') || answerStr.includes('nid_lost')) {
      refinedDocs = isBn
        ? ['নিকটস্থ থানা বা অনলাইনে জিডি (General Diary) এর কপি ও জিডি নম্বর', 'পুরাতন এনআইডি ফটোকপি অথবা এনআইডি নম্বর', 'অনলাইন রি-ইস্যু সরকারি ফি জমার রশিদ']
        : ['Police General Diary (GD) copy & GD number', 'Old NID photocopy or NID number', 'Official government re-issue fee payment receipt'];
      refinedSteps = isBn
        ? ['নিকটস্থ থানা অথবা অনলাইন জিডি পোর্টালে (gd.police.gov.bd) হারানো জিডি করুন', 'services.nidw.gov.bd পোর্টালে লগইন করে "হারানো কার্ড রি-ইস্যু" আবেদন করুন ও চালান ফি দিন', 'আবেদন অনুমোদিত হলে অনলাইন থেকে ডিজিটাল এনআইডি ডাউনলোড করুন']
        : ['File a GD at your local police station or online (gd.police.gov.bd)', 'Log in to services.nidw.gov.bd, select "Lost Card Re-issue" and pay the fee', 'Download digital NID from the portal upon approval'];
    } else if (answerStr.includes('বাবার নাম') || answerStr.includes('মায়ের নাম') || answerStr.includes("Father's Name") || answerStr.includes("Mother's Name")) {
      refinedDocs = isBn
        ? ['পিতা/মাতার এনআইডি কার্ডের ফটোকপি (সংশোধিত)', 'আবেদনকারীর শিক্ষাগত বোর্ড সনদ (SSC/HSC) অথবা পাসপোর্ট', 'ডিজিটাল জন্ম নিবন্ধন সনদ']
        : ["Parent's corrected NID copy", "Applicant's educational certificate (SSC/HSC) or passport", 'Digital birth registration certificate'];
      refinedSteps = isBn
        ? ['services.nidw.gov.bd পোর্টালে পিতা/মাতার নাম সংশোধনের অপশন নির্বাচন করে সঠিক বানান দিন', 'প্রমাণপত্র স্ক্যান করে আপলোড করুন ও মোবাইল ব্যাংকিংয়ে ফি দিন', 'আবেদন প্রিন্ট করে প্রয়োজনবোধে উপজেলা নির্বাচন অফিসে মূল কাগজপত্র প্রদর্শন করুন']
        : ["Select parent's name correction on services.nidw.gov.bd and enter correct spelling", 'Upload scanned supporting proofs and pay fee via mobile banking', 'Print form and verify with original documents at Upazila Election Office if requested'];
    } else if (answerStr.includes('জন্ম তারিখ') || answerStr.includes('Date of Birth')) {
      refinedDocs = isBn
        ? ['শিক্ষাগত বোর্ড সনদ (SSC/সমমান) অথবা পাসপোর্ট', '১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদ', 'সিভিল সার্জন কর্তৃক বয়স নির্ধারণ সনদ (প্রযোজ্য ক্ষেত্রে)']
        : ['Educational board certificate (SSC/equivalent) or passport', '17-digit online birth certificate', 'Civil Surgeon age determination certificate if applicable'];
      refinedSteps = isBn
        ? ['services.nidw.gov.bd পোর্টালে জন্ম তারিখ সংশোধনের আবেদন ফরম পূরণ করুন', 'বোর্ড সনদ স্ক্যান করে আপলোড করুন ও নির্ধারিত ক্যাটাগরি ফি জমা দিন', 'যাচাই শেষে আবেদন অনুমোদিত হলে সংশোধিত এনআইডি অনলাইন থেকে ডাউনলোড করুন']
        : ['Fill out date of birth correction application on services.nidw.gov.bd', 'Upload educational certificate and pay designated correction fee', 'Download corrected NID online once approved by the election commission'];
    }
  }

  // 3. Passport Services
  else if (serviceId === 3 || answerStr.includes('passport_')) {
    if (answerStr.includes('নবায়ন') || answerStr.includes('Renewal') || answerStr.includes('passport_renewal') || answerStr.includes('মেয়াদ') || originalRequest.includes('নবায়ন') || originalRequest.includes('renew')) {
      refinedDocs = isBn
        ? ['পূর্বের মূল পাসপোর্ট ও এর ফটোকপি', 'জাতীয় পরিচয়পত্র (NID) এর ফটোকপি', 'অনলাইন আবেদন সারসংক্ষেপ (Application Summary) ও পেমেন্ট স্লিপ']
        : ['Previous original passport and its photocopy', 'National ID (NID) copy', 'Online application summary printout and bank payment slip'];
      refinedSteps = isBn
        ? ['epassport.gov.bd পোর্টালে লগইন করে পাসপোর্ট নবায়ন আবেদন ফরম পূরণ করুন', 'ব্যাংক বা এ-চালানের মাধ্যমে পাসপোর্টের সরকারি ফি পরিশোধ করুন', 'পূর্বের মূল পাসপোর্টসহ নির্ধারিত দিনে পাসপোর্ট অফিসে গিয়ে বায়োমেট্রিক প্রদান করুন']
        : ['Log in to epassport.gov.bd and complete passport renewal form', 'Pay official fee via accredited banks or e-Challan', 'Visit designated Passport Office with original previous passport for biometric capture'];
    } else {
      refinedDocs = isBn
        ? ['জাতীয় পরিচয়পত্র (NID) অথবা ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদ', 'পাসপোর্ট আবেদন সারসংক্ষেপ (Application Summary)', 'সরকারি ফি জমার এ-চালান / ব্যাংক রসিদ', 'প্রযোজ্য ক্ষেত্রে পেশাগত সনদ / প্রত্যয়নপত্র']
        : ['National ID (NID) or 17-digit online birth registration certificate', 'Application summary printout', 'Government fee e-challan or bank deposit slip', 'Professional proof/certificate if applicable'];
      refinedSteps = isBn
        ? ['epassport.gov.bd পোর্টালে নির্ভুলভাবে নতুন ই-পাসপোর্ট ফরম পূরণ করুন', 'ফি পরিশোধ করে অ্যাপয়েন্টমেন্টের স্লিপ প্রিন্ট করুন', 'নির্ধারিত তারিখে মূল কাগজপত্রসহ পাসপোর্ট অফিসে গিয়ে ফিঙ্গারপ্রিন্ট ও ছবি দিন']
        : ['Fill out the new e-Passport application on epassport.gov.bd accurately', 'Pay requisite fees and print appointment summary', 'Visit the regional passport office on appointment date with originals for biometrics'];
    }
  }

  // 4. e-Mutation (ই-নামজারি)
  else if (serviceId === 4 || answerStr.includes('mutation_')) {
    if (answerStr.includes('ওয়ারিশ') || answerStr.includes('Warishan')) {
      refinedDocs = isBn
        ? ['স্থানীয় কাউন্সিলর/চেয়ারম্যানের ওয়ারিশান সনদপত্র', 'মূল মালিকের মৃত্যু সনদপত্র', 'হালনাগাদ জমির খাজনা দাখিলা', 'খতিয়ান ও পিঠ দলিলের কপি']
        : ['Official Warishan certificate from Chairman/Councilor', 'Death certificate of original land owner', 'Updated land revenue tax slip (dakhila)', 'Khatian and previous deed chain copies'];
      refinedSteps = isBn
        ? ['mutation.land.gov.bd পোর্টালে ওয়ারিশান ক্যাটাগরিতে নামজারি আবেদন করুন', 'ওয়ারিশান সনদ ও খাজনা দাখিলা স্ক্যান করে সিস্টেমে আপলোড করুন', 'সহকারী কমিশনার (ভূমি) কর্তৃক শুনানির তারিখে মূল সনদসহ উপস্থিত থাকুন']
        : ['Submit mutation application under Inheritance category on mutation.land.gov.bd', 'Upload scanned Warishan certificate and tax receipt', 'Attend the AC (Land) hearing with original proofs on the scheduled date'];
    } else {
      refinedDocs = isBn
        ? ['মূল সাফ-কবলা দলিল বা রেজিস্ট্রিকৃত সার্টিফাইড কপি', 'হালনাগাদ ভূমি উন্নয়ন কর (খাজনা দাখিলা)', 'পিঠ দলিল ও বায়া দলিলের ধারাবাহিক কপি', 'খতিয়ানের কপি (CS/SA/RS/BS)']
        : ['Original registered deed (Saf-kabala) or certified copy', 'Updated land development tax receipt (dakhila)', 'Chain deeds and prior ownership deeds', 'Khatian records (CS/SA/RS/BS)'];
      refinedSteps = isBn
        ? ['mutation.land.gov.bd ওয়েবসাইটে গিয়ে সাব-কবলা সূত্রে ই-নামজারি ফরম পূরণ করুন', 'অনলাইনে কোর্ট ফি ও নোটিশ জারি ফি পরিশোধ করুন', 'ইউনিয়ন ভূমি সহকারী কর্মকর্তা (তহশিলদার) প্রতিবেদন দাখিল করলে ডিসিআর ফি দিয়ে খতিয়ান সংগ্রহ করুন']
        : ['Apply for e-Mutation on mutation.land.gov.bd under purchase deed', 'Pay initial court fee and notice issuance fee online', 'After field verification report, pay DCR fee to download certified Mutation Khatian'];
    }
  }

  // 5. Trade License
  else if (serviceId === 5 || answerStr.includes('trade_')) {
    refinedDocs = isBn
      ? ['ব্যবসা প্রতিষ্ঠানের ভাড়ার চুক্তিপত্র (৩০০ টাকার নন-জুডিশিয়াল স্ট্যাম্প) বা মালিকানা দলিল', 'মালিকের জাতীয় পরিচয়পত্র ও পাসপোর্ট সাইজের ২ কপি ছবি', 'হোল্ডিং ট্যাক্স পরিশোধের রশিদ', 'প্রযোজ্য ক্ষেত্রে লিমিটেড কোম্পানির মেমোরেন্ডাম ও টিআইএন']
      : ['Rental agreement on 300 BDT non-judicial stamp or commercial property deed', "Owner's National ID and 2 passport-sized photographs", 'Holding tax receipt of commercial premises', 'TIN certificate and Memorandum of Association (for companies)'];
    refinedSteps = isBn
      ? ['সংশ্লিষ্ট সিটি কর্পোরেশন/পৌরসভা/ইউনিয়ন পরিষদ পোর্টালে ট্রেড লাইসেন্স ফরম পূরণ করুন', 'ভাড়ার চুক্তিপত্র ও এনআইডি স্ক্যান করে সংযুক্ত করুন', 'অনুমোদিত ব্যাংক বা মোবাইল ফিন্যান্সিয়ালে লাইসেন্স ফি ও সাইনবোর্ড কর জমা দিয়ে লাইসেন্স গ্রহণ করুন']
      : ['Complete Trade License application on respective City Corporation / Pourashava / UP portal', 'Attach scanned rental agreement and owner National ID', 'Pay official license fee & signage tax via designated channels to obtain Trade License'];
  }

  // 6. Death Registration
  else if (serviceId === 6 || answerStr.includes('death_')) {
    refinedDocs = isBn
      ? ['হাসপাতালের ডেথ স্লিপ / রেজিস্টার্ড চিকিৎসকের মৃত্যুর প্রত্যয়নপত্র', 'দাফন / সৎকারের আনুষ্ঠানিক রসিদ (গোরস্থান বা শ্মশান কমিটি)', 'মৃত ব্যক্তির জাতীয় পরিচয়পত্র / জন্ম সনদ (যদি থাকে)', 'আবেদনকারীর এনআইডি ও সম্পর্কের প্রমাণ']
      : ['Hospital death slip / Registered doctor demise certificate', 'Burial / Cremation slip from cemetery or crematorium committee', "Deceased person's NID or birth certificate if available", "Applicant's NID and relationship verification proof"];
    refinedSteps = isBn
      ? ['bdris.gov.bd পোর্টালে গিয়ে "মৃত্যু নিবন্ধনের আবেদন" ফরম পূরণ করুন', 'হাসপাতালের মৃত্যু সনদ ও দাফনের রশিদ আপলোড করুন', 'প্রিন্ট কপি সংশ্লিষ্ট পৌরসভা বা ইউনিয়ন পরিষদে জমা দিয়ে মৃত্যু সনদ সংগ্রহ করুন']
      : ['Fill out Death Registration application form on bdris.gov.bd portal', 'Upload hospital certificate and burial/cremation slip', 'Submit hard copy to local Union Parishad / Pourashava office to collect certificate'];
  }

  // 7. Driving License
  else if (serviceId === 7 || answerStr.includes('driving_')) {
    refinedDocs = isBn
      ? ['রেজিস্টার্ড চিকিৎসকের মেডিকেল ফিটনেস সার্টিফিকেট (ফরম খ)', 'জাতীয় পরিচয়পত্র (NID) এর ফটোকপি', 'ন্যূনতম শিক্ষাগত যোগ্যতার সনদ (৮ম শ্রেণি/সমমান)', 'ইউটিলিটি বিলের কপি (ঠিকানার প্রমাণ হিসেবে)']
      : ['Medical Fitness Certificate (Form B) from registered physician', 'National ID (NID) photocopy', 'Minimum educational qualification certificate (JSC/8th grade pass)', 'Utility bill copy for address verification'];
    refinedSteps = isBn
      ? ['bsp.brta.gov.bd (BRTA Service Portal)-এ লার্নার ড্রাইভিং লাইসেন্সের জন্য আবেদন করুন', 'অনলাইনে ফি পরিশোধ করে লার্নার পারমিট ডাউনলোড করুন', 'নির্দিষ্ট তারিখে ফিল্ড টেস্টে (লিখিত, মৌখিক ও প্র্যাকটিকাল) উত্তীর্ণ হয়ে স্মার্ট কার্ড বায়োমেট্রিক দিন']
      : ['Apply for Learner Driving License on bsp.brta.gov.bd (BRTA Service Portal)', 'Pay fees online and download learner permit printout', 'Pass the test (written, oral, driving) on scheduled date and provide biometrics for smart card'];
  }

  // 8. TIN Registration
  else if (serviceId === 8 || answerStr.includes('tin_')) {
    refinedDocs = isBn
      ? ['জাতীয় পরিচয়পত্র (NID)', 'এনআইডি দিয়ে বায়োমেট্রিক নিবন্ধিত মোবাইল নম্বর', 'প্রযোজ্য ক্ষেত্রে কোম্পানির ট্রেড লাইসেন্স ও আরজেএসসি নিবন্ধন']
      : ['National ID (NID)', 'Biometrically registered mobile number linked to applicant NID', 'Trade license & RJSC incorporation (for companies/partnerships)'];
    refinedSteps = isBn
      ? ['incometax.gov.bd পোর্টালে গিয়ে "Register" অপশনে ক্লিক করুন', 'এনআইডি নম্বর, জন্ম তারিখ ও মোবাইল নম্বর দিয়ে ওটিপি যাচাই করুন', 'সফলভাবে যাচাই শেষ হলে সাথে সাথে ১২-সংখ্যার ই-টিআইএন সার্টিফিকেট ডাউনলোড ও প্রিন্ট করুন']
      : ['Visit incometax.gov.bd and click on "Register"', 'Verify NID number, date of birth, and mobile number via SMS OTP', 'Download and print the official 12-digit e-TIN Certificate instantly upon verification'];
  }

  const answeredIds = new Set(Array.isArray(answers) ? answers.map((a) => a.questionId || a.id) : []);
  const remainingQuestions = (previousDiagnosis?.followUpQuestions || [])
    .filter((q) => !answeredIds.has(q.id));

  return {
    serviceId,
    serviceName: previousDiagnosis?.serviceName || 'General Service',
    serviceNameBn: previousDiagnosis?.serviceNameBn || 'সরকারি সেবা',
    confidence: 0.98,
    summary: isBn
      ? `আপনার প্রদত্ত তথ্যের ভিত্তিতে "${previousDiagnosis?.serviceNameBn || 'সেবা'}" এর জন্য সুনির্দিষ্ট করণীয় ও নির্দেশিকা প্রস্তুত করা হয়েছে।`
      : `Refined procedure generated for "${previousDiagnosis?.serviceName || 'Service'}" based on your specific selections.`,
    requiredDocuments: refinedDocs,
    steps: refinedSteps,
    followUpQuestions: remainingQuestions,
    clarifiedDetails: answers,
    aiPowered: false,
    refined: true,
  };
}

module.exports = {
  identifyServiceWithGemini,
  refineServiceWithGemini,
  fallbackClassifier,
  refineFallbackClassifier,
  getCatalogFollowUpQuestions,
  getNidFollowUpBank,
  getBirthRegistrationFollowUpBank,
  getPassportFollowUpBank,
  getMutationFollowUpBank,
  getTradeLicenseFollowUpBank,
  getDeathRegistrationFollowUpBank,
  getDrivingLicenseFollowUpBank,
  getTinRegistrationFollowUpBank,
  GOVERNMENT_CATALOG,
};
