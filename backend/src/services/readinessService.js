const DOC_TYPE_KEYWORDS = {
  NID: ['nid', 'national id', 'voter', 'smart card', 'জাতীয় পরিচয়পত্র', 'এনআইডি', 'ভোটার'],
  BIRTH_CERT: ['birth', 'bdris', 'জন্ম', 'নিবন্ধন সনদ'],
  EDUCATIONAL: ['ssc', 'hsc', 'educational', 'academic', 'marksheet', 'শিক্ষাগত', 'এসএসসি', 'এইচএসসি'],
  CITIZENSHIP: ['citizenship', 'chairman', 'ward', 'নাগরিকত্ব', 'প্রত্যয়ন'],
  UTILITY_BILL: ['utility', 'electricity', 'water', 'gas', 'holding', 'rental', 'বিল', 'ঠিকানা', 'হোল্ডিং'],
  OTHER: [],
};

function normalizeText(value) {
  return String(value || '')
    .trim()
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

function hasBangla(str) {
  return /[\u0980-\u09FF]/.test(String(str || ''));
}

function hasLatin(str) {
  return /[A-Za-z]/.test(String(str || ''));
}

/**
 * Normalize dates like DD-MM-YYYY, DD/MM/YYYY, YYYY-MM-DD to YYYY-MM-DD when possible.
 */
function normalizeDate(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw;
  const dmy = raw.match(/^(\d{2})[\/\-](\d{2})[\/\-](\d{4})$/);
  if (dmy) return `${dmy[3]}-${dmy[2]}-${dmy[1]}`;
  return normalizeText(raw);
}

/**
 * Pick the best comparable English name from ocrData, falling back to fullName.
 */
function getComparableName(ocrData) {
  if (!ocrData) return null;
  return ocrData.fullNameEn || ocrData.fullName || null;
}

/**
 * Check if two names are comparable and actually mismatched.
 * Avoids false mismatch when one document only extracted Bangla and the other only English.
 */
function namesMismatch(ocrA, ocrB) {
  // If both have English names, compare them directly
  if (ocrA.fullNameEn && ocrB.fullNameEn) {
    return normalizeText(ocrA.fullNameEn) !== normalizeText(ocrB.fullNameEn);
  }
  // If both have Bangla names, compare them directly
  if (ocrA.fullNameBn && ocrB.fullNameBn) {
    return normalizeText(ocrA.fullNameBn) !== normalizeText(ocrB.fullNameBn);
  }
  const nameA = getComparableName(ocrA);
  const nameB = getComparableName(ocrB);
  if (!nameA || !nameB) return false;

  // Different scripts (one pure Bangla, one pure English) without transliteration -> do not false-flag
  if ((hasBangla(nameA) && !hasLatin(nameA) && hasLatin(nameB) && !hasBangla(nameB)) ||
      (hasLatin(nameA) && !hasBangla(nameA) && hasBangla(nameB) && !hasLatin(nameB))) {
    return false;
  }

  return normalizeText(nameA) !== normalizeText(nameB);
}

function matchesRequiredDoc(requiredText, docType) {
  const lower = normalizeText(requiredText);
  const keywords = DOC_TYPE_KEYWORDS[docType] || [];
  return keywords.some((kw) => lower.includes(kw.toLowerCase()));
}

/**
 * Evaluate FR13 (Missing Documents), FR14 (Information Mismatch), and FR15 (Readiness Report).
 */
function evaluateReadiness({ requiredDocuments = [], uploadedDocs = [] }) {
  const uploadedTypes = new Set(uploadedDocs.map((d) => d.docType));

  // FR13: Missing Document Detection
  const missingDocuments = [];
  if (Array.isArray(requiredDocuments) && requiredDocuments.length > 0) {
    for (const reqDoc of requiredDocuments) {
      const satisfied = Array.from(uploadedTypes).some((t) => matchesRequiredDoc(reqDoc, t));
      if (!satisfied) {
        missingDocuments.push(reqDoc);
      }
    }
  } else if (uploadedDocs.length === 0) {
    missingDocuments.push('At least one supporting document is required');
  }

  // FR14: Cross-document Mismatch Detection
  const mismatches = [];

  const docsWithName = uploadedDocs.filter((d) => d.ocrData && getComparableName(d.ocrData));
  if (docsWithName.length >= 2) {
    const baseline = docsWithName[0];
    for (let i = 1; i < docsWithName.length; i++) {
      const other = docsWithName[i];
      if (namesMismatch(baseline.ocrData, other.ocrData)) {
        const valA = getComparableName(baseline.ocrData);
        const valB = getComparableName(other.ocrData);
        mismatches.push({
          field: 'fullName',
          firstDoc: baseline.docType,
          firstValue: valA,
          secondDoc: other.docType,
          secondValue: valB,
          messageBn: `নামের বানানে অমিল পাওয়া গেছে: ${baseline.docType} ("${valA}") বনাম ${other.docType} ("${valB}")।`,
          messageEn: `Name mismatch detected between ${baseline.docType} ("${valA}") and ${other.docType} ("${valB}").`,
        });
      }
    }
  }

  const docsWithDob = uploadedDocs.filter((d) => d.ocrData && d.ocrData.dateOfBirth);
  if (docsWithDob.length >= 2) {
    const baseline = docsWithDob[0];
    const baseDob = normalizeDate(baseline.ocrData.dateOfBirth);
    for (let i = 1; i < docsWithDob.length; i++) {
      const other = docsWithDob[i];
      if (normalizeDate(other.ocrData.dateOfBirth) !== baseDob) {
        mismatches.push({
          field: 'dateOfBirth',
          firstDoc: baseline.docType,
          firstValue: baseline.ocrData.dateOfBirth,
          secondDoc: other.docType,
          secondValue: other.ocrData.dateOfBirth,
          messageBn: `জন্ম তারিখে অমিল পাওয়া গেছে: ${baseline.docType} ("${baseline.ocrData.dateOfBirth}") বনাম ${other.docType} ("${other.ocrData.dateOfBirth}")।`,
          messageEn: `Date of birth mismatch between ${baseline.docType} ("${baseline.ocrData.dateOfBirth}") and ${other.docType} ("${other.ocrData.dateOfBirth}").`,
        });
      }
    }
  }

  const isReady = uploadedDocs.length > 0 && missingDocuments.length === 0 && mismatches.length === 0;

  return {
    status: isReady ? 'ready' : 'action_needed',
    isReady,
    totalRequired: requiredDocuments.length,
    totalUploaded: uploadedDocs.length,
    missingDocuments,
    mismatches,
    disclaimerBn: 'সতর্কতা: এটি শুধুমাত্র একটি প্রাথমিক যাচাইকরণ এবং কোনো অফিশিয়াল সরকারি অনুমোদন নয়।',
    disclaimerEn: 'Disclaimer: This is a preliminary check only and not an official government approval.',
  };
}

module.exports = {
  evaluateReadiness,
};
