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

  const docsWithName = uploadedDocs.filter((d) => d.ocrData && d.ocrData.fullName);
  if (docsWithName.length >= 2) {
    const baseline = docsWithName[0];
    const baseNorm = normalizeText(baseline.ocrData.fullName);
    for (let i = 1; i < docsWithName.length; i++) {
      const other = docsWithName[i];
      if (normalizeText(other.ocrData.fullName) !== baseNorm) {
        mismatches.push({
          field: 'fullName',
          firstDoc: baseline.docType,
          firstValue: baseline.ocrData.fullName,
          secondDoc: other.docType,
          secondValue: other.ocrData.fullName,
          messageBn: `নামের বানানে অমিল পাওয়া গেছে: ${baseline.docType} ("${baseline.ocrData.fullName}") বনাম ${other.docType} ("${other.ocrData.fullName}")।`,
          messageEn: `Name mismatch detected between ${baseline.docType} ("${baseline.ocrData.fullName}") and ${other.docType} ("${other.ocrData.fullName}").`,
        });
      }
    }
  }

  const docsWithDob = uploadedDocs.filter((d) => d.ocrData && d.ocrData.dateOfBirth);
  if (docsWithDob.length >= 2) {
    const baseline = docsWithDob[0];
    const baseDob = normalizeText(baseline.ocrData.dateOfBirth);
    for (let i = 1; i < docsWithDob.length; i++) {
      const other = docsWithDob[i];
      if (normalizeText(other.ocrData.dateOfBirth) !== baseDob) {
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
