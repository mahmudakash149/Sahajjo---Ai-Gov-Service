const test = require('node:test');
const assert = require('node:assert/strict');
const { evaluateReadiness } = require('../src/services/readinessService');
const { parseBasicFieldsFromText } = require('../src/services/ocrService');

test('evaluateReadiness detects missing documents and name mismatches (FR13-FR15)', () => {
  const report = evaluateReadiness({
    requiredDocuments: [
      'National ID (NID)',
      '17-digit online birth certificate',
      'SSC / Educational qualification certificate',
    ],
    uploadedDocs: [
      {
        docType: 'NID',
        ocrData: { fullName: 'Md. Akash Mahmud', dateOfBirth: '1998-05-12' },
      },
      {
        docType: 'EDUCATIONAL',
        ocrData: { fullName: 'Akash Mahmud', dateOfBirth: '1998-05-12' },
      },
    ],
  });

  assert.equal(report.isReady, false);
  assert.equal(report.status, 'action_needed');
  assert.deepEqual(report.missingDocuments, ['17-digit online birth certificate']);
  assert.equal(report.mismatches.length, 1);
  assert.equal(report.mismatches[0].field, 'fullName');
});

test('evaluateReadiness returns ready when all required docs match across Bangla/English and DD-MM-YYYY', () => {
  const report = evaluateReadiness({
    requiredDocuments: ['National ID (NID)', 'Online Birth Certificate'],
    uploadedDocs: [
      {
        docType: 'NID',
        ocrData: { fullName: 'Mahmud Akash', fullNameEn: 'Mahmud Akash', dateOfBirth: '2001-01-01' },
      },
      {
        docType: 'BIRTH_CERT',
        ocrData: { fullName: 'মাহমুদ আকাশ', fullNameBn: 'মাহমুদ আকাশ', dateOfBirth: '01-01-2001' },
      },
    ],
  });

  assert.equal(report.isReady, true);
  assert.equal(report.status, 'ready');
  assert.equal(report.missingDocuments.length, 0);
  assert.equal(report.mismatches.length, 0);
});

test('evaluateReadiness matches PHOTO and CHALLAN against passport-size photo and receipt requirements', () => {
  const report = evaluateReadiness({
    requiredDocuments: [
      'National ID / Birth Certificate',
      'Passport size photographs',
      'Payment receipt/challan',
    ],
    uploadedDocs: [
      { docType: 'NID', ocrData: { fullNameEn: 'Mahmud Akash', dateOfBirth: '2001-01-01' } },
      { docType: 'PHOTO', ocrData: {} },
      { docType: 'CHALLAN', ocrData: {} },
    ],
  });

  assert.equal(report.isReady, true);
  assert.equal(report.missingDocuments.length, 0);
  assert.equal(report.mismatches.length, 0);
});

test('parseBasicFieldsFromText extracts name, DOB (ignoring Issue Date), and 10/17-digit ID', () => {
  const fields = parseBasicFieldsFromText(
    'Government of Bangladesh\nDate of Issue: 15-02-2021\nName: Md. Akash Mahmud\nDate of Birth: 1998-05-12\nNID No: 1234567890'
  );
  assert.equal(fields.fullName, 'Md. Akash Mahmud');
  assert.equal(fields.dateOfBirth, '1998-05-12');
  assert.equal(fields.documentNumber, '1234567890');
});
