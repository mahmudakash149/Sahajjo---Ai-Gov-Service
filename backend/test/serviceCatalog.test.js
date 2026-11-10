const test = require('node:test');
const assert = require('node:assert/strict');
const {
  filterFallback,
  escapeLike,
  FALLBACK_SERVICES,
} = require('../src/controllers/serviceController');

test('FR3 Service Catalog Test Suite', async (t) => {
  await t.test('1. Should return all 8 services when search query is empty', () => {
    const results = filterFallback('');
    assert.equal(results.length, 8);
    assert.deepEqual(results, FALLBACK_SERVICES);
  });

  await t.test('2. Should filter services by Bangla keyword (পাসপোর্ট)', () => {
    const results = filterFallback('পাসপোর্ট');
    assert.ok(results.length >= 1);
    const found = results.some((s) => s.id === 3 && s.nameBn.includes('পাসপোর্ট'));
    assert.equal(found, true, 'Passport service should be found in Bangla search');
  });

  await t.test('3. Should filter services by English keyword case-insensitively (passport)', () => {
    const resultsLower = filterFallback('passport');
    const resultsUpper = filterFallback('PASSPORT');
    assert.ok(resultsLower.length >= 1);
    assert.equal(resultsLower.length, resultsUpper.length);
    assert.equal(resultsLower[0].id, 3);
  });

  await t.test('4. Should find NID Correction by Bangla or English keyword', () => {
    const byBn = filterFallback('এনআইডি');
    const byEn = filterFallback('nid');
    assert.ok(byBn.some((s) => s.id === 2));
    assert.ok(byEn.some((s) => s.id === 2));
  });

  await t.test('5. Should return an empty array when no services match query', () => {
    const results = filterFallback('non_existent_govt_service_xyz_123');
    assert.equal(results.length, 0);
  });

  await t.test('6. Should safely escape SQL LIKE wildcards (% and _)', () => {
    assert.equal(escapeLike('100%'), '100\\%');
    assert.equal(escapeLike('test_name'), 'test\\_name');
    assert.equal(escapeLike('100%_guaranteed'), '100\\%\\_guaranteed');
  });

  await t.test('7. Should verify all services have valid category mappings (FR3 Grouping)', () => {
    const services = filterFallback('');
    for (const service of services) {
      assert.ok(typeof service.id === 'number', 'Service must have an id');
      assert.ok(typeof service.categoryId === 'number', 'Service must have a categoryId');
      assert.ok(service.categoryNameBn.length > 0, 'Category Bangla name must not be empty');
      assert.ok(service.categoryNameEn.length > 0, 'Category English name must not be empty');
      assert.ok(service.nameBn.length > 0, 'Service Bangla name must not be empty');
      assert.ok(service.nameEn.length > 0, 'Service English name must not be empty');
    }
  });

  await t.test('8. Should verify priority services are properly identified', () => {
    const priorityServices = FALLBACK_SERVICES.filter((s) => s.isPriority);
    assert.ok(priorityServices.length > 0, 'There should be at least one priority service');
    const priorityNames = priorityServices.map((s) => s.nameEn);
    assert.ok(priorityNames.includes('Birth Registration'));
    assert.ok(priorityNames.includes('NID Correction'));
    assert.ok(priorityNames.includes('Passport Services'));
  });

  await t.test('9. Should verify comprehensive guidelines for New Application and Correction for each service', () => {
    for (const service of FALLBACK_SERVICES) {
      assert.ok(service.guidelines, `Service ${service.id} must have guidelines attached`);
      const { newApplication, correction } = service.guidelines;
      
      // New Application assertions
      assert.ok(newApplication, `Service ${service.id} must have newApplication guide`);
      assert.ok(newApplication.requiredDocumentsBn.length >= 2, `Service ${service.id} needs Bn docs for new application`);
      assert.ok(newApplication.requiredDocumentsEn.length >= 2, `Service ${service.id} needs En docs for new application`);
      assert.ok(newApplication.stepsBn.length >= 2, `Service ${service.id} needs Bn steps for new application`);
      assert.ok(newApplication.stepsEn.length >= 2, `Service ${service.id} needs En steps for new application`);

      // Correction assertions
      assert.ok(correction, `Service ${service.id} must have correction guide`);
      assert.ok(correction.requiredDocumentsBn.length >= 2, `Service ${service.id} needs Bn docs for correction`);
      assert.ok(correction.requiredDocumentsEn.length >= 2, `Service ${service.id} needs En docs for correction`);
      assert.ok(correction.stepsBn.length >= 2, `Service ${service.id} needs Bn steps for correction`);
      assert.ok(correction.stepsEn.length >= 2, `Service ${service.id} needs En steps for correction`);

      // Official portal and advice
      assert.ok(service.portalUrl.startsWith('http'), `Service ${service.id} must have a valid portal URL`);
      assert.ok(service.tipsBn.length > 5, `Service ${service.id} must have tips in Bangla`);
      assert.ok(service.tipsEn.length > 5, `Service ${service.id} must have tips in English`);
    }
  });
});
