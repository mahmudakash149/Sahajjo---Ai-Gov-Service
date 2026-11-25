const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
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
} = require('../src/services/geminiService');

describe('FR6 Follow-up Questions - Complete All-Service Question Bank Test Suite', () => {
  describe('1. Birth Registration Question Bank', () => {
    it('1.1 should return 3 questions for New Birth Registration', () => {
      const q = getBirthRegistrationFollowUpBank('আমার বাচ্চার নতুন জন্ম নিবন্ধন করব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'birth_new_age');
      assert.deepEqual(q[0].options, ['নবজাতক (০–৪৫ দিন)', 'শিশু (৪৬ দিন থেকে ৫ বছর)', 'প্রাপ্তবয়স্ক (৫ বছরের ঊর্ধ্বে)', 'নিশ্চিত নই']);
      assert.equal(q[1].id, 'birth_parents_cert');
      assert.equal(q[2].id, 'birth_new_docs');
    });

    it('1.2 should return 3 questions for Birth Information Correction', () => {
      const q = getBirthRegistrationFollowUpBank('জন্ম নিবন্ধন সনদে নামের বানান ভুল সংশোধন', 'en');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'birth_corr_which');
      assert.equal(q[1].id, 'birth_corr_proof');
      assert.equal(q[2].id, 'birth_corr_original');
    });

    it('1.3 should return common question with subQuestionsByOption when generic', () => {
      const q = getBirthRegistrationFollowUpBank('জন্ম নিবন্ধন', 'bn');
      assert.equal(q.length, 1);
      assert.equal(q[0].id, 'birth_service_type');
      assert.ok(q[0].subQuestionsByOption);
    });
  });

  describe('2. NID Question Bank (Verified)', () => {
    it('2.1 New NID: should return 3 questions', () => {
      const q = getNidFollowUpBank('নতুন ভোটার হতে চাই', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'nid_new_age');
    });

    it('2.2 Lost NID: should return 2 questions', () => {
      const q = getNidFollowUpBank('এনআইডি হারিয়ে গেছে', 'bn');
      assert.equal(q.length, 2);
      assert.equal(q[0].id, 'nid_lost_number');
    });

    it('2.3 Name Correction: should skip Q1 if person is identified', () => {
      const q = getNidFollowUpBank('বাবার নাম সংশোধন করব', 'bn');
      assert.equal(q.length, 2);
      assert.equal(q[0].id, 'nid_name_docs');
    });
  });

  describe('3. Passport Services Question Bank', () => {
    it('3.1 New e-Passport: should return 3 questions', () => {
      const q = getPassportFollowUpBank('নতুন ই-পাসপোর্ট আবেদন করতে চাই', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'passport_age_group');
      assert.equal(q[1].id, 'passport_id_type');
      assert.equal(q[2].id, 'passport_pages_validity');
    });

    it('3.2 Passport Renewal: should return 2 questions', () => {
      const q = getPassportFollowUpBank('আমার পাসপোর্টের মেয়াদ শেষ নবায়ন করব', 'en');
      assert.equal(q.length, 2);
      assert.equal(q[0].id, 'passport_renewal_reason');
      assert.equal(q[1].id, 'passport_has_old_copy');
    });
  });

  describe('4. e-Mutation (ই-নামজারি) Question Bank', () => {
    it('4.1 Purchase Deed based: should return 3 questions', () => {
      const q = getMutationFollowUpBank('জমি কিনেছি সাব-কবলা দলিল দিয়ে নামজারি করব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'mutation_has_deed');
      assert.equal(q[1].id, 'mutation_tax_cleared');
      assert.equal(q[2].id, 'mutation_khatian_chain');
    });

    it('4.2 Inheritance based: should return 2 questions', () => {
      const q = getMutationFollowUpBank('বাবার মৃত্যুর পর পৈতৃক সম্পত্তি ওয়ারিশ সূত্রে খারিজ', 'bn');
      assert.equal(q.length, 2);
      assert.equal(q[0].id, 'mutation_has_warishan');
      assert.equal(q[1].id, 'mutation_heir_agreement');
    });
  });

  describe('5. Trade License Question Bank', () => {
    it('5.1 New Trade License: should return 3 questions', () => {
      const q = getTradeLicenseFollowUpBank('দোকানের জন্য নতুন ট্রেড লাইসেন্স চালু করব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'trade_area_jurisdiction');
      assert.equal(q[1].id, 'trade_business_structure');
      assert.equal(q[2].id, 'trade_rental_agreement');
    });

    it('5.2 Trade License Renewal: should return 2 questions', () => {
      const q = getTradeLicenseFollowUpBank('ট্রেড লাইসেন্স নবায়ন করব', 'en');
      assert.equal(q.length, 2);
      assert.equal(q[0].id, 'trade_previous_doc');
      assert.equal(q[1].id, 'trade_due_status');
    });
  });

  describe('6. Death Registration Question Bank', () => {
    it('6.1 New Death Registration: should return 3 questions', () => {
      const q = getDeathRegistrationFollowUpBank('আমার আত্মীয় মারা গেছেন মৃত্যু নিবন্ধন করব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'death_timeline_passed');
      assert.equal(q[1].id, 'death_place_occurred');
      assert.equal(q[2].id, 'death_proof_docs');
    });
  });

  describe('7. Driving License Question Bank', () => {
    it('7.1 New Driving License / Learner: should return 3 questions', () => {
      const q = getDrivingLicenseFollowUpBank('নতুন ড্রাইভিং লাইসেন্স ও লার্নার পারমিট করব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'driving_license_class');
      assert.equal(q[1].id, 'driving_medical_fitness');
      assert.equal(q[2].id, 'driving_learner_status');
    });
  });

  describe('8. TIN Registration Question Bank', () => {
    it('8.1 New e-TIN Registration: should return 3 questions', () => {
      const q = getTinRegistrationFollowUpBank('আয়কর রিটার্ন দেওয়ার জন্য নতুন টিন সার্টিফিকেট বানাব', 'bn');
      assert.equal(q.length, 3);
      assert.equal(q[0].id, 'tin_purpose_type');
      assert.equal(q[1].id, 'tin_applicant_type');
      assert.equal(q[2].id, 'tin_biometric_sim');
    });
  });

  describe('9. Refinement & End-to-End Fallback', () => {
    it('9.1 should refine Birth Registration for newborn', () => {
      const initial = fallbackClassifier('বাচ্চার জন্ম নিবন্ধন করব', 'bn');
      const refined = refineFallbackClassifier('বাচ্চার জন্ম নিবন্ধন করব', initial, [{ questionId: 'birth_new_age', answer: 'নবজাতক (০–৪৫ দিন)' }], 'bn');
      assert.ok(refined.refined);
      assert.ok(refined.requiredDocuments.some((d) => d.includes('ইপিআই') || d.includes('ছাড়পত্র')));
    });

    it('9.2 should refine Passport for renewal', () => {
      const initial = fallbackClassifier('পাসপোর্ট নবায়ন', 'bn');
      const refined = refineFallbackClassifier('পাসপোর্ট নবায়ন', initial, [{ questionId: 'passport_renewal_reason', answer: 'মেয়াদোত্তীর্ণ' }], 'bn');
      assert.ok(refined.refined);
      assert.ok(refined.requiredDocuments.some((d) => d.includes('পূর্বের মূল পাসপোর্ট')));
    });

    it('9.3 should refine Trade License for business', () => {
      const initial = fallbackClassifier('নতুন ট্রেড লাইসেন্স', 'bn');
      const refined = refineFallbackClassifier('নতুন ট্রেড লাইসেন্স', initial, [{ questionId: 'trade_area_jurisdiction', answer: 'সিটি কর্পোরেশন' }], 'bn');
      assert.ok(refined.refined);
      assert.ok(refined.requiredDocuments.some((d) => d.includes('চুক্তিপত্র') || d.includes('স্ট্যাম্প')));
    });
  });
});
