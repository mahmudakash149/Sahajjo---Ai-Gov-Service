const pool = require('../db');

// Escape LIKE wildcards so a user typing "%" or "_" searches for the literal character.
const escapeLike = (s) => s.replace(/[\\%_]/g, '\\$&');

// Comprehensive Bangladesh Government Service Guidelines
// Distinguishes between "New Application" (নতুন আবেদন) and "Correction/Renewal" (তথ্য সংশোধন ও নবায়ন)
const SERVICE_GUIDELINES = {
  1: {
    portalUrl: 'https://bdris.gov.bd',
    tipsBn: 'দালাল পরিহার করুন। আবেদন ফি সর্বদা অনুমোদিত ব্যাংকে বা অনলাইনে জমা দিয়ে চালান রশিদ সংগ্রহ করুন।',
    tipsEn: 'Avoid unauthorized brokers. Always pay official fees through accredited banks or online challan.',
    newApplication: {
      requiredDocumentsBn: [
        'শিশুর ইপিআই (EPI) টিকা কার্ডের মূল কপি ও সত্যায়িত ফটোকপি',
        'পিতা ও মাতার ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন ও এনআইডি কপি',
        'বাসার হোল্ডিং ট্যাক্স রশিদ / হালনাগাদ জমির খাজনা দাখিলা / ভাড়ার চুক্তিপত্র',
        'সরকারি আবেদন ফি জমার রশিদ (চালান কপি)',
      ],
      requiredDocumentsEn: [
        "Child's original EPI immunization card and attested copy",
        "Parents' 17-digit online birth certificates and NID copies",
        'Holding tax payment receipt / Land revenue tax slip / Rental agreement',
        'Official government application fee challan / payment receipt',
      ],
      stepsBn: [
        'bdris.gov.bd ওয়েবসাইটে গিয়ে "জন্ম নিবন্ধনের জন্য আবেদন" ফরমটি নির্ভুলভাবে পূরণ করুন।',
        'আবেদন সম্পন্ন করে আবেদনপত্রের প্রিন্ট কপি ও চালান ফি প্রস্তুত করুন।',
        'স্থানীয় ইউনিয়ন পরিষদ / পৌরসভা / সিটি কর্পোরেশন অফিসে মূল কাগজপত্রসহ প্রিন্ট কপি জমা দিয়ে সনদ গ্রহণ করুন।',
      ],
      stepsEn: [
        'Fill out the online application at the official bdris.gov.bd portal.',
        'Print the submitted application form and pay the designated government fee.',
        'Submit the printed form with original supporting documents to your local Union Parishad / Municipality / City Corporation office to collect the certificate.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান মূল জন্ম নিবন্ধন সনদের ডিজিটাল কপি ও ফটোকপি',
        'নাম বা বয়স প্রমাণের স্বপক্ষে শিক্ষাগত সনদ (JSC/SSC/সমমান) অথবা পাসপোর্ট',
        'পিতা/মাতার নাম সংশোধনের ক্ষেত্রে পিতা-মাতার এনআইডি/সংশোধিত জন্ম সনদ',
        'স্থানীয় ওয়ার্ড কাউন্সিলর / চেয়ারম্যানের সত্যায়িত প্রত্যয়নপত্র',
      ],
      requiredDocumentsEn: [
        'Existing original birth registration certificate and digital copy',
        'Educational certificates (JSC/SSC/equivalent) or Passport as evidence of age/name',
        "Parents' corrected NID or birth certificate (if correcting parental details)",
        'Verification certificate from local Ward Councilor / Union Chairman',
      ],
      stepsBn: [
        'bdris.gov.bd ওয়েবসাইটে "জন্ম তথ্য সংশোধন আবেদন" নির্বাচন করে প্রয়োজনীয় তথ্য আপডেট করুন।',
        'প্রমাণের স্বপক্ষে প্রয়োজনীয় কাগজপত্রাদি স্ক্যান করে সিস্টেমে আপলোড করুন।',
        'আবেদন ফরম প্রিন্ট করে সংশ্লিষ্ট নিবন্ধক কার্যালয়ে মূল কাগজপত্রসহ যাচাইয়ের জন্য জমা দিন।',
      ],
      stepsEn: [
        "Choose 'Birth Information Correction Application' on bdris.gov.bd.",
        'Scan and upload verified supporting proof documents.',
        'Print the application and present it with original documents to the registrar office for verification.',
      ],
    },
  },
  2: {
    portalUrl: 'https://services.nidw.gov.bd',
    tipsBn: 'এনআইডি সংশোধনে প্রমাণের ক্ষেত্রে শিক্ষাগত সনদ বা পাসপোর্ট অত্যন্ত নির্ভরযোগ্য প্রমাণ হিসেবে বিবেচিত হয়।',
    tipsEn: 'Educational board certificates or Passports are considered primary conclusive evidence for NID corrections.',
    newApplication: {
      requiredDocumentsBn: [
        '১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন সনদপত্র (ডিজিটাল কপি)',
        'শিক্ষাগত যোগ্যতার সনদপত্র (SSC/HSC বা সমমানের বোর্ড সনদ)',
        'পিতা ও মাতার জাতীয় পরিচয়পত্র (NID) এর ফটোকপি',
        'নাগরিকত্ব সনদপত্র / চেয়ারম্যান প্রত্যয়নপত্র',
        'বিদ্যুৎ বিল / পানির বিল / হোল্ডিং ট্যাক্সের রসিদ (ঠিকানার প্রমাণ হিসেবে)',
      ],
      requiredDocumentsEn: [
        '17-digit verified online birth registration certificate',
        'Educational qualification certificates (SSC/HSC/equivalent board cert)',
        "Photocopy of parents' National ID cards",
        'Citizenship certificate from local Ward Councilor / Chairman',
        'Utility bill copy (electricity/water) or holding tax slip as residence proof',
      ],
      stepsBn: [
        'services.nidw.gov.bd ওয়েবসাইটে নতুন ভোটার নিবন্ধনের অনলাইন ফর্ম পূরণ করুন।',
        'ফরম প্রিন্ট করে প্রয়োজনীয় কাগজপত্রসহ নিকটস্থ উপজেলা/থানা নির্বাচন অফিসে বায়োমেট্রিক ও ছবি প্রদান করুন।',
        'নির্বাচন কমিশন থেকে যাচাই ও অনুমোদন শেষে অনলাইন থেকে স্মার্ট/ডিজিটাল এনআইডি ডাউনলোড করুন।',
      ],
      stepsEn: [
        'Fill out the new voter registration form on services.nidw.gov.bd.',
        'Print the form and visit your Upazila/Thana Election Office for biometric scanning and photograph.',
        'Upon verification and approval, log into the portal to download your digital NID.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান মূল এনআইডি কার্ড / ডিজিটাল কপি',
        'নাম বা বয়স সংশোধনে: এসএসসি/বোর্ড সনদপত্র অথবা পাসপোর্ট/ড্রাইভিং লাইসেন্স',
        'বৈবাহিক অবস্থা সংশোধনে: নিকাহনামা / তালাকনামা / ম্যারিজ সার্টিফিকেট',
        'প্রযোজ্য সরকারি ফি (বিকাশ/রকেট/নগদ এর মাধ্যমে চালান কোডে প্রদেয়)',
      ],
      requiredDocumentsEn: [
        'Current original National ID card / digital copy',
        'For Name/DOB change: SSC or board certificate, Passport, or Driving License',
        'For Marital status: Nikahnama / Marriage certificate or Divorce deed',
        'Government amendment fee payment slip (via bKash, Rocket, or Nagad)',
      ],
      stepsBn: [
        'services.nidw.gov.bd এ নিজস্ব প্রোফাইলে লগইন করে "তথ্য সংশোধন" অপশন বেছে নিন।',
        'নির্ধারিত ফি মোবাইল ব্যাংকিংয়ের মাধ্যমে পরিশোধ করে সঠিক তথ্য এন্ট্রি করুন।',
        'সংশোধনের সপক্ষে নথিপত্র আপলোড করে সাবমিট করুন এবং অনুমোদন শেষে সংশোধিত এনআইডি ডাউনলোড করুন।',
      ],
      stepsEn: [
        "Log in to your citizen profile at services.nidw.gov.bd and navigate to 'Information Correction'.",
        'Pay the required government amendment fee through mobile banking.',
        'Upload verified supporting documents, submit the request, and download the revised NID after approval.',
      ],
    },
  },
  3: {
    portalUrl: 'https://epassport.gov.bd',
    tipsBn: 'পাসপোর্ট আবেদনের তথ্য যেন অবশ্যই আপনার এনআইডি বা জন্ম নিবন্ধনের সাথে শতভাগ মিল থাকে।',
    tipsEn: 'Ensure all personal details strictly match your National ID or 17-digit online birth certificate.',
    newApplication: {
      requiredDocumentsBn: [
        'জাতীয় পরিচয়পত্র (NID) মূল ও ফটোকপি (প্রাপ্তবয়স্কদের জন্য) অথবা ১৭ ডিজিটের অনলাইন জন্ম নিবন্ধন (অপ্রাপ্তবয়স্কদের জন্য)',
        'আবেদন সারাংশ প্রিন্ট কপি (Application Summary with Barcode)',
        'ব্যাংকে বা অনলাইনে এ-চালান (A-Challan) এর মাধ্যমে পাসপোর্ট ফি জমার রশিদ',
        'সরকারি চাকরিজীবী হলে জিও (GO) / এনওসি (NOC) কপি',
      ],
      requiredDocumentsEn: [
        'Original NID and photocopy (for adults) or 17-digit online birth certificate (for minors)',
        'Online application summary with barcode',
        'Passport fee payment receipt through A-Challan or accredited bank',
        'Government Order (GO) / NOC (if government employee)',
      ],
      stepsBn: [
        'epassport.gov.bd পোর্টালে গিয়ে ই-পাসপোর্টের অনলাইন আবেদন সম্পূর্ণ করুন।',
        'নির্ধারিত ব্যাংকে বা এ-চালানে সরকারি ফি পরিশোধ করে সময়সূচি নির্ধারণ করুন।',
        'নির্দিষ্ট তারিখে আঞ্চলিক পাসপোর্ট অফিসে গিয়ে বায়োমেট্রিক ও ছবি প্রদান করে ডেলিভারি স্লিপ নিন।',
      ],
      stepsEn: [
        'Complete the online e-Passport application at epassport.gov.bd.',
        'Pay the designated passport fees via A-Challan / online banking and select an appointment date.',
        'Visit your Regional Passport Office with documents for biometric capture, photo, and collect the delivery slip.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'পূর্ববর্তী মূল পাসপোর্ট ও ডেটা পেইজের ফটোকপি',
        'জাতীয় পরিচয়পত্র (NID) এর ফটোকপি',
        'তথ্য পরিবর্তনের সপক্ষে সরকারি গ্যাজেট বিজ্ঞপ্তি / আদালতের হলফনামা / নিকাহনামা (প্রযোজ্য ক্ষেত্রে)',
        'পাসপোর্ট নবায়ন/রি-ইস্যু ফি প্রদানের রশিদ',
      ],
      requiredDocumentsEn: [
        'Previous original passport and photocopy of data pages',
        'National ID card photocopy',
        'Official government gazette / court affidavit / marriage certificate (if modifying major details)',
        'Re-issue / renewal fee payment receipt',
      ],
      stepsBn: [
        'epassport.gov.bd ওয়েবসাইটে "রি-ইস্যু / নবায়ন" অপশন বেছে নিয়ে তথ্য পূরণ করুন।',
        'সরকারি রি-ইস্যু ফি পরিশোধ করে অ্যাপয়েন্টমেন্ট তারিখ নিন।',
        'পূর্বের পাসপোর্ট ও প্রয়োজনীয় প্রমাণপত্রসহ পাসপোর্ট অফিসে যাচাই শেষ করে ডেলিভারি নিন।',
      ],
      stepsEn: [
        "Select 'Passport Re-issue / Renewal' on epassport.gov.bd and enter details.",
        'Pay the re-issue fee and book your appointment slot.',
        'Submit your old passport and supporting documents at the passport office for verification.',
      ],
    },
  },
  4: {
    portalUrl: 'https://mutation.land.gov.bd',
    tipsBn: 'নামজারির শুনানিতে মূল দলিলের সকল মূল কপি সাথে নিয়ে উপস্থিত থাকতে হবে।',
    tipsEn: 'All original title deeds must be produced physically before the Assistant Commissioner (Land) during hearings.',
    newApplication: {
      requiredDocumentsBn: [
        'মূল রেজিস্ট্রার্ড দলিলের কপি (সাব-কবলা / হেবা / বণ্টননামা ইত্যাদি)',
        'সংশ্লিষ্ট খতিয়ানের কপি (CS, SA, RS বা সিটি জরিপ খতিয়ান)',
        'হালনাগাদ ভূমি উন্নয়ন কর (খাজনা) পরিশোধের দাখিলা',
        'ওয়ারিশান সনদ (ওয়ারিশসূত্রে মালিকানা হলে) ও আবেদনকারীর এনআইডি কপি',
      ],
      requiredDocumentsEn: [
        'Registered deed copy (Sub-Kabala, Heba, Deed of Partition, etc.)',
        'Relevant Khatian records (CS, SA, RS, or City Survey Khatian)',
        'Up-to-date land development tax (Khajna) payment receipt',
        "Succession certificate (Warishan Sanad, if inherited) & applicant's NID",
      ],
      stepsBn: [
        'mutation.land.gov.bd পোর্টালে নাগরিক হিসেবে অ্যাকাউন্ট খুলে নামজারি আবেদন করুন।',
        'কোর্ট ফি ও নোটিশ জারি ফি (৭০ টাকা) অনলাইনে পরিশোধ করুন।',
        'এসি ল্যান্ড (AC Land) শুনানিতে মূল দলিল প্রদর্শন করুন এবং ডিসিআর ও নতুন খতিয়ান ফি প্রদান করে খতিয়ান সংগ্রহ করুন।',
      ],
      stepsEn: [
        'Open a citizen account at mutation.land.gov.bd and file the mutation request.',
        'Pay initial court and notice service fees (BDT 70) online.',
        'Attend the Assistant Commissioner (Land) hearing with original deeds and pay the DCR fee to receive the final Khatian.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান ভুল নামজারি খতিয়ানের কপি ও ডিসিআর রশিদ',
        'মূল মালিকানা ও স্বত্ব প্রমাণকারী দলিল',
        'সংশ্লিষ্ট এলাকার মাঠ পর্চা / সিএস-আরএস খতিয়ান কপি',
        'আবেদনকারীর এনআইডি ও সংশোধনীর যৌক্তিক বিবরণী',
      ],
      requiredDocumentsEn: [
        'Copy of existing erroneous mutation Khatian and DCR receipt',
        'Original title deeds confirming authentic land ownership',
        'Relevant Mauza map / CS-RS Khatian records demonstrating clerical error',
        "Applicant's NID and formal petition detailing requested correction",
      ],
      stepsBn: [
        'সহকারী কমিশনার (ভূমি) বরাবর নামজারি সংশোধনের জন্য মিস কেস (Mis-case) আবেদন দায়ের করুন।',
        'ইউনিয়ন ভূমি সহকারী কর্মকর্তার তদন্ত প্রতিবেদন সাপেক্ষে শুনানির তারিখ গ্রহণ করুন।',
        'শুনানিতে সমস্ত সঠিক রেকর্ড প্রদর্শন করে সংশোধিত নামজারি খতিয়ান অনুমোদন করান।',
      ],
      stepsEn: [
        'File a Miss-case (amendment petition) with the Assistant Commissioner (Land) office.',
        'Receive the field investigation report and official hearing date from the Union Land Office.',
        'Present all primary authentic deeds during the hearing to approve the corrected mutation record.',
      ],
    },
  },
  5: {
    portalUrl: 'https://etradelicense.gov.bd',
    tipsBn: 'ব্যবসা শুরু করার পূর্বে ট্রেড লাইসেন্স সংগ্রহ করা আইনত বাধ্যতামূলক।',
    tipsEn: 'Obtaining a trade license is legally mandatory prior to initiating commercial business operations.',
    newApplication: {
      requiredDocumentsBn: [
        'ব্যবসায়ী প্রতিষ্ঠানের ভাড়ার চুক্তিপত্র অথবা নিজস্ব জায়গার হোল্ডিং ট্যাক্স রশিদ',
        'আবেদনকারী/স্বত্বাধিকারীর জাতীয় পরিচয়পত্র (NID) ও পাসপোর্ট সাইজ ছবি',
        'অংশীদারি ব্যবসার ক্ষেত্রে পার্টনারশিপ ডিড (Partnership Deed)',
        'লিমিটেড কোম্পানির ক্ষেত্রে মেমোরেন্ডাম অব আর্টিকেলস (MoA) ও ইনকর্পোরেশন সনদ',
      ],
      requiredDocumentsEn: [
        'Rental agreement of business premises or holding tax slip of owned property',
        "Applicant/owner's National ID copy and passport-sized photographs",
        'Partnership deed (for partnership business entities)',
        'Memorandum of Association (MoA) & Certificate of Incorporation (for limited companies)',
      ],
      stepsBn: [
        'সিটি কর্পোরেশন / পৌরসভা / ইউনিয়ন পরিষদের ই-ট্রেড লাইসেন্স পোর্টালে আবেদন ফর্ম পূরণ করুন।',
        'প্রয়োজনীয় কাগজপত্র ও প্রতিষ্ঠানের সাইনবোর্ডের ছবি আপলোড করুন।',
        'ট্রেড লাইসেন্স ফি ও সাইনবোর্ড ট্যাক্স পরিশোধ করে তাৎক্ষণিক ডিজিটাল লাইসেন্স ডাউনলোড করুন।',
      ],
      stepsEn: [
        'Fill out the online application on the local City Corporation / Pourashava / UP e-Trade License portal.',
        'Upload tenant agreement, NID, and signage photograph.',
        'Pay the prescribed trade license fees and tax online to instantly download the validated digital license.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'পূর্ববর্তী বছরের মূল ট্রেড লাইসেন্স কপি ও ফি জমার রশিদ',
        'হালনাগাদ ভাড়ার চুক্তিপত্র / পৌর কর বা হোল্ডিং ট্যাক্স রশিদ',
        'নাম, মালিকানা বা ঠিকানা পরিবর্তনের ক্ষেত্রে রেজিস্টার্ড এফিডেভিট / সংবিধিবদ্ধ দলিল',
      ],
      requiredDocumentsEn: [
        "Previous year's original Trade License and challan receipt",
        'Updated rental agreement / local holding tax receipt',
        'Registered affidavit or amended company deed (if changing business name, owner, or premises)',
      ],
      stepsBn: [
        'অনলাইন পোর্টালে বিদ্যমান ট্রেড লাইসেন্স নম্বর দিয়ে "নবায়ন/সংশোধন" অপশন বেছে নিন।',
        'পরিবর্তিত তথ্য প্রদান করে প্রমাণপত্র আপলোড করুন।',
        'নবায়ন ফি পরিশোধ করে হালনাগাদ ট্রেড লাইসেন্স গ্রহণ করুন।',
      ],
      stepsEn: [
        "Enter your existing Trade License number on the online portal and select 'Renew/Amend'.",
        'Input amended data and upload corresponding supporting documentation.',
        'Pay the annual renewal fee and download the newly renewed license.',
      ],
    },
  },
  6: {
    portalUrl: 'https://bdris.gov.bd',
    tipsBn: 'মৃত্যুর ৪৫ দিনের মধ্যে মৃত্যু নিবন্ধন করালে সরকারি কোনো বিলম্ব ফি লাগে না।',
    tipsEn: 'Registering death within 45 days of occurrence incurs zero delay penalties.',
    newApplication: {
      requiredDocumentsBn: [
        'রেজিস্টার্ড ডাক্তার বা হাসপাতালের অফিসিয়াল ডেথ সার্টিফিকেট (মৃত্যু সনদ)',
        'মৃত ব্যক্তির মূল জাতীয় পরিচয়পত্র (NID) অথবা অনলাইন জন্ম নিবন্ধন সনদ',
        'কবরস্থান বা শ্মশান কমিটি কর্তৃক প্রদত্ত দাফন/সৎকার প্রত্যয়নপত্র',
        'আবেদনকারীর (ওয়ারিশের) এনআইডি ও সম্পর্ক প্রমাণের ওয়ারিশান প্রত্যয়ন',
      ],
      requiredDocumentsEn: [
        'Registered medical practitioner or hospital official death certificate',
        "Deceased person's National ID card or online birth registration certificate",
        'Burial / cremation confirmation certificate from cemetery or crematorium authority',
        "Applicant's (heir's) NID and relationship proof / inheritance certificate",
      ],
      stepsBn: [
        'bdris.gov.bd পোর্টালে গিয়ে মৃত্যু নিবন্ধনের আবেদন ফর্মটি পূরণ করুন।',
        'আবেদনপত্র প্রিন্ট করে চিকিৎসকের সনদ ও আবেদনকারীর প্রমাণপত্র সংযুক্ত করুন।',
        'স্থানীয় ইউনিয়ন পরিষদ / পৌরসভা / সিটি কর্পোরেশন কার্যালয়ে জমা দিয়ে সরকারি মৃত্যু সনদ গ্রহণ করুন।',
      ],
      stepsEn: [
        'Complete the online death registration application form at bdris.gov.bd.',
        'Print the form and attach medical death verification and identity documents.',
        'Submit to the local Union Parishad / Municipality / City Corporation office to obtain the official certificate.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান মূল মৃত্যু নিবন্ধন সনদপত্র',
        'সংশোধনের সপক্ষে অফিসিয়াল মেডিকেল রেকর্ড অথবা স্থানীয় চেয়ারম্যানের সংশোধনী প্রত্যয়ন',
        'আবেদনকারী বৈধ উত্তরাধিকারীর জাতীয় পরিচয়পত্র',
      ],
      requiredDocumentsEn: [
        'Existing issued death registration certificate',
        "Official medical records or Chairman's affidavit validating the typographical/clerical correction",
        "Valid legal heir's National ID",
      ],
      stepsBn: [
        'bdris.gov.bd ওয়েবসাইটে "মৃত্যু নিবন্ধন তথ্য সংশোধন" অপশনে গিয়ে ফর্ম পূরণ করুন।',
        'সঠিক তথ্যের সপক্ষে প্রমাণাদি আপলোড করুন।',
        'প্রিন্ট কপি ও মূল কাগজপত্র নিয়ে নিবন্ধক কার্যালয়ে উপস্থিত হয়ে সংশোধিত সনদ সংগ্রহ করুন।',
      ],
      stepsEn: [
        "Go to bdris.gov.bd and choose 'Death Registration Information Correction'.",
        'Upload supporting documentation for the corrected fields.',
        'Submit printed form and original records to the registrar office to collect the amended certificate.',
      ],
    },
  },
  7: {
    portalUrl: 'https://bsp.brta.gov.bd',
    tipsBn: 'বিআরটিএ লার্নার কার্ড সংগ্রহের পর নির্দিষ্ট মেয়াদ শেষে ব্যবহারিক ড্রাইভিং পরীক্ষায় অংশ নিতে হয়।',
    tipsEn: 'After receiving your BRTA learner card, appear for the scheduled practical driving test.',
    newApplication: {
      requiredDocumentsBn: [
        'রেজিস্টার্ড ডাক্তারের নিকট থেকে নির্ধারিত ফরম্যাটে মেডিকেল ফিটনেস সার্টিফিকেট',
        'জাতীয় পরিচয়পত্র (NID) এর সত্যায়িত ফটোকপি',
        'ন্যূনতম শিক্ষাগত যোগ্যতার সনদপত্র (কমপক্ষে ৮ম শ্রেণী বা জেএসসি/সমমান)',
        'সাম্প্রতিক পাসপোর্ট সাইজ ছবি ও ইউটিলিটি বিলের কপি',
      ],
      requiredDocumentsEn: [
        "Registered physician's medical fitness certificate on standard BRTA format",
        'Attested photocopy of National ID card',
        'Minimum educational qualification certificate (at least 8th grade / JSC / equivalent)',
        'Recent passport-sized color photographs & utility bill copy',
      ],
      stepsBn: [
        'bsp.brta.gov.bd পোর্টালে গিয়ে "শিক্ষানবিস (লার্নার) ড্রাইভিং লাইসেন্স" এর আবেদন করুন ও ফি প্রদান করুন।',
        'নির্ধারিত তারিখে বিআরটিএ টেস্ট ভেন্যুতে লিখিত, মৌখিক ও ফিল্ড টেস্ট পরীক্ষায় অংশ নিন।',
        'পরীক্ষায় উত্তীর্ণ হয়ে স্মার্ট কার্ড লাইসেন্স ফি প্রদান করুন এবং বায়োমেট্রিক দিয়ে লাইসেন্স গ্রহণ করুন।',
      ],
      stepsEn: [
        'Register at bsp.brta.gov.bd and apply for the Learner Driving License with fee payment.',
        'Appear at the designated BRTA venue for written, oral, and practical field driving examinations.',
        'Upon passing, pay smart card fees, provide biometrics, and receive the digital driving license.',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান মূল ড্রাইভিং লাইসেন্স কার্ড ও ফটোকপি',
        'হালনাগাদ মেডিকেল সার্টিফিকেট (ফরম বিআরটিএ নির্ধারিত)',
        'জাতীয় পরিচয়পত্রের ফটোকপি',
        'নাম বা ঠিকানা পরিবর্তনের স্বপক্ষে হলফনামা / ম্যারিজ সার্টিফিকেট / হোল্ডিং ট্যাক্স রশিদ',
        'নবায়ন ফি প্রদানের এ-চালান / ব্যাংক রশিদ',
      ],
      requiredDocumentsEn: [
        'Existing original driving license smart card and photocopy',
        'Fresh medical fitness certificate from an accredited doctor',
        'National ID card photocopy',
        'Supporting affidavit / marriage deed / utility bill (if updating name or address)',
        'Renewal fee payment challan / transaction slip',
      ],
      stepsBn: [
        'বিআরটিএ সার্ভিস পোর্টালে (BSP) লগইন করে "লাইসেন্স নবায়ন/সংশোধন" ফর্ম পূরণ করুন।',
        'নির্ধারিত নবায়ন ফি অনলাইনে বা ব্যাংকে পরিশোধ করুন।',
        'বায়োমেট্রিক ও প্রয়োজনীয় নথিপত্র যাচাই শেষে নতুন স্মার্ট কার্ড ড্রাইভিং লাইসেন্স গ্রহণ করুন।',
      ],
      stepsEn: [
        "Log in to the BRTA Service Portal (BSP) and choose 'License Renewal / Correction'.",
        'Pay the official renewal fee through authorized payment gateways.',
        'Complete biometric re-verification (if required) and obtain the renewed driving license.',
      ],
    },
  },
  8: {
    portalUrl: 'https://secure.incometax.gov.bd',
    tipsBn: 'ই-টিআইএন সম্পূর্ণ বিনামূল্যে অনলাইনে তাৎক্ষণিকভাবে পাওয়া যায়। কোনো ফি প্রয়োজন হয় না।',
    tipsEn: 'e-TIN is completely free of cost and generated instantly online without any service fees.',
    newApplication: {
      requiredDocumentsBn: [
        'জাতীয় পরিচয়পত্র (NID) নম্বর ও সঠিক জন্ম তারিখ',
        'সক্রিয় ও নিবন্ধিত ব্যক্তিগত মোবাইল নম্বর (ভেরিফিকেশন OTP এর জন্য)',
        'ব্যবসায়িক টিআইএন হলে হালনাগাদ ট্রেড লাইসেন্স ও কোম্পানির ইনকর্পোরেশন নম্বর',
      ],
      requiredDocumentsEn: [
        'National ID card number and exact date of birth',
        'Active personal mobile number for one-time password (OTP) verification',
        'Up-to-date trade license and registration details (for commercial entities)',
      ],
      stepsBn: [
        'secure.incometax.gov.bd পোর্টালে গিয়ে "Register" বাটনে ক্লিক করে অ্যাকাউন্ট খুলুন।',
        'করদাতার ধরন ও এনআইডি নম্বর ইনপুট দিয়ে তাৎক্ষণিক তথ্য যাচাই করুন।',
        'সম্পূর্ণ বিনামূল্যে কোনো সরকারি ফি ছাড়াই ১২ ডিজিটের ই-টিআইএন সার্টিফিকেট ডাউনলোড ও প্রিন্ট করুন।',
      ],
      stepsEn: [
        "Visit secure.incometax.gov.bd and click 'Register' to create a taxpayer account.",
        'Input taxpayer classification, purpose, and NID for instant automated database verification.',
        'Instantly download and print the official 12-digit e-TIN certificate (completely free of cost).',
      ],
    },
    correction: {
      requiredDocumentsBn: [
        'বিদ্যমান ই-টিআইএন সনদের কপি বা ১২ ডিজিটের টিআইএন নম্বর',
        'সংশোধিত জাতীয় পরিচয়পত্র (NID) কপি',
        'কর অঞ্চলের উপ-কর কমিশনার (DCT) বরাবর লিখিত সংশোধনী দরখাস্ত (গুরুতর পরিবর্তনের ক্ষেত্রে)',
      ],
      requiredDocumentsEn: [
        'Current 12-digit TIN number or old certificate copy',
        'Updated National ID card copy',
        'Written petition addressed to Deputy Commissioner of Taxes (DCT) for formal amendments',
      ],
      stepsBn: [
        'secure.incometax.gov.bd পোর্টালে পূর্বের ইউজার আইডি ও পাসওয়ার্ড দিয়ে লগইন করুন।',
        '"View/Print Certificate" থেকে সরাসরি পুনরায় সার্টিফিকেট ডাউনলোড করুন।',
        'নাম বা তথ্য পরিবর্তনের জন্য এনআইডি ডাটাবেজ আপডেট হওয়ার পর পোর্টালে স্বয়ংক্রিয় রিফ্রেশ অথবা সংশ্লিষ্ট কর সার্কেলে আবেদন জমা দিন।',
      ],
      stepsEn: [
        'Log in with your registered username and password at secure.incometax.gov.bd.',
        "Choose 'View/Print Certificate' to immediately reprint a lost certificate.",
        'If amending personal details, sync with the updated NID registry or submit a request to your assigned tax circle.',
      ],
    },
  },
};

// Attaches comprehensive guidelines (New Application + Correction) to a service object
function attachGuidelines(svc) {
  const guide = SERVICE_GUIDELINES[svc.id] || null;
  return {
    ...svc,
    portalUrl: guide?.portalUrl || '',
    tipsBn: guide?.tipsBn || '',
    tipsEn: guide?.tipsEn || '',
    guidelines: guide
      ? {
          newApplication: guide.newApplication,
          correction: guide.correction,
        }
      : null,
  };
}

// Predefined service catalog (mirrors database/services.sql)
const FALLBACK_SERVICES = [
  {
    id: 1,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'জন্ম নিবন্ধন',
    nameEn: 'Birth Registration',
    descriptionBn: 'নতুন জন্ম নিবন্ধন করা বা জন্ম নিবন্ধন সনদ সংশোধন করা।',
    descriptionEn: 'Register a new birth or correct a birth registration certificate.',
    isPriority: true,
  },
  {
    id: 2,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'এনআইডি তথ্য সংশোধন',
    nameEn: 'NID Correction',
    descriptionBn: 'জাতীয় পরিচয়পত্রের নাম, ঠিকানা বা অন্য তথ্য সংশোধন করা।',
    descriptionEn: 'Correct the name, address or other details on a National ID card.',
    isPriority: true,
  },
  {
    id: 3,
    categoryId: 2,
    categoryNameBn: 'ভ্রমণ ও যানবাহন',
    categoryNameEn: 'Travel & Transport',
    nameBn: 'পাসপোর্ট সেবা',
    nameEn: 'Passport Services',
    descriptionBn: 'নতুন পাসপোর্টের আবেদন, নবায়ন বা তথ্য সংশোধন।',
    descriptionEn: 'Apply for a new passport, renew it, or correct its details.',
    isPriority: true,
  },
  {
    id: 4,
    categoryId: 3,
    categoryNameBn: 'ভূমি সেবা',
    categoryNameEn: 'Land Services',
    nameBn: 'ই-নামজারি',
    nameEn: 'e-Mutation',
    descriptionBn: 'জমির মালিকানা পরিবর্তনের পর অনলাইনে নামজারির আবেদন।',
    descriptionEn: 'Apply online for land mutation after a change of ownership.',
    isPriority: true,
  },
  {
    id: 5,
    categoryId: 4,
    categoryNameBn: 'ব্যবসা',
    categoryNameEn: 'Business',
    nameBn: 'ট্রেড লাইসেন্স',
    nameEn: 'Trade License',
    descriptionBn: 'ব্যবসা চালানোর জন্য নতুন ট্রেড লাইসেন্স বা নবায়ন।',
    descriptionEn: 'Get a new trade license or renew one to run a business.',
    isPriority: true,
  },
  {
    id: 6,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'মৃত্যু নিবন্ধন',
    nameEn: 'Death Registration',
    descriptionBn: 'মৃত্যুর ঘটনা নিবন্ধন করা ও মৃত্যু সনদ সংগ্রহ।',
    descriptionEn: 'Register a death and obtain a death certificate.',
    isPriority: false,
  },
  {
    id: 7,
    categoryId: 2,
    categoryNameBn: 'ভ্রমণ ও যানবাহন',
    categoryNameEn: 'Travel & Transport',
    nameBn: 'ড্রাইভিং লাইসেন্স',
    nameEn: 'Driving License',
    descriptionBn: 'নতুন ড্রাইভিং লাইসেন্স বা নবায়নের আবেদন।',
    descriptionEn: 'Apply for a new driving license or renewal.',
    isPriority: false,
  },
  {
    id: 8,
    categoryId: 4,
    categoryNameBn: 'ব্যবসা',
    categoryNameEn: 'Business',
    nameBn: 'টিআইএন নিবন্ধন',
    nameEn: 'TIN Registration',
    descriptionBn: 'কর শনাক্তকরণ নম্বর (TIN) পাওয়ার জন্য নিবন্ধন।',
    descriptionEn: 'Register to get a Taxpayer Identification Number (TIN).',
    isPriority: false,
  },
].map(attachGuidelines);

function filterFallback(q) {
  if (!q) return FALLBACK_SERVICES;
  const lower = q.toLowerCase();
  return FALLBACK_SERVICES.filter(
    (s) =>
      s.nameBn.includes(q) ||
      s.nameEn.toLowerCase().includes(lower) ||
      s.descriptionBn.includes(q) ||
      s.descriptionEn.toLowerCase().includes(lower)
  );
}

// FR3: service catalog grouped by category, with search and detailed application & correction guidelines.
// GET /api/services            -> all active services
// GET /api/services?q=passport -> search in names and descriptions (Bangla or English)
async function listServices(req, res, next) {
  const q = String(req.query.q || '').trim().slice(0, 100);
  try {
    let sql = `
      SELECT s.id, s.name_bn, s.name_en, s.description_bn, s.description_en, s.is_priority,
             c.id AS category_id, c.name_bn AS category_name_bn, c.name_en AS category_name_en
      FROM services s
      JOIN service_categories c ON c.id = s.category_id
      WHERE s.status = 'active'`;
    const params = [];

    if (q) {
      sql += ` AND (s.name_bn LIKE ? OR s.name_en LIKE ?
                 OR s.description_bn LIKE ? OR s.description_en LIKE ?)`;
      const like = `%${escapeLike(q)}%`;
      params.push(like, like, like, like);
    }
    sql += ' ORDER BY c.id, s.is_priority DESC, s.id';

    const [rows] = await pool.execute(sql, params);
    return res.json({
      services: rows.map((r) =>
        attachGuidelines({
          id: r.id,
          nameBn: r.name_bn,
          nameEn: r.name_en,
          descriptionBn: r.description_bn,
          descriptionEn: r.description_en,
          isPriority: !!r.is_priority,
          categoryId: r.category_id,
          categoryNameBn: r.category_name_bn,
          categoryNameEn: r.category_name_en,
        })
      ),
    });
  } catch (err) {
    if (err.code === 'ER_NO_SUCH_TABLE') {
      console.warn('[Service Catalog] MySQL tables not found. Serving built-in default catalog.');
      return res.json({ services: filterFallback(q) });
    }
    return next(err);
  }
}

module.exports = {
  listServices,
  filterFallback,
  escapeLike,
  FALLBACK_SERVICES,
  SERVICE_GUIDELINES,
  attachGuidelines,
};
