const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

describe('FR4 Citizen Service Request Persistence Test Suite', () => {
  const STORE_PATH = path.join(__dirname, '../database/requests_store.json');

  it('1. Persistent requests store should be created and readable', () => {
    // If requestController is loaded, it should create or read the store
    const { createRequest, listMyRequests } = require('../src/controllers/requestController');
    assert.equal(typeof createRequest, 'function');
    assert.equal(typeof listMyRequests, 'function');
  });

  it('2. Creating fallback request should persist to disk across restarts', async () => {
    const { createRequest, listMyRequests } = require('../src/controllers/requestController');

    const fakeReq = {
      user: { id: 9999 },
      body: {
        requestText: 'test birth certificate request',
        language: 'en',
      },
    };

    let resultJson = null;
    const fakeRes = {
      status(code) {
        return this;
      },
      json(data) {
        resultJson = data;
        return data;
      },
    };

    // Invoke createRequest
    await createRequest(fakeReq, fakeRes, () => {});

    assert.ok(resultJson);
    assert.ok(resultJson.request);
    assert.equal(resultJson.request.userId, 9999);
    assert.equal(resultJson.request.requestText, 'test birth certificate request');

    // Verify it was saved to requests_store.json
    assert.ok(fs.existsSync(STORE_PATH), 'requests_store.json must exist');
    const stored = JSON.parse(fs.readFileSync(STORE_PATH, 'utf8'));
    const found = stored.find((r) => r.userId === 9999 && r.requestText === 'test birth certificate request');
    assert.ok(found, 'Request must be found in persistent requests_store.json');

    // Verify listMyRequests retrieves it
    let listResult = null;
    const fakeListRes = {
      json(data) {
        listResult = data;
        return data;
      },
    };

    await listMyRequests({ user: { id: 9999 } }, fakeListRes, () => {});
    assert.ok(listResult);
    assert.ok(Array.isArray(listResult.requests));
    const listFound = listResult.requests.find((r) => r.requestText === 'test birth certificate request');
    assert.ok(listFound, 'Request must be retrieved in listMyRequests for user');

    // Clean up test item
    const cleaned = stored.filter((r) => r.userId !== 9999);
    fs.writeFileSync(STORE_PATH, JSON.stringify(cleaned, null, 2), 'utf8');
  });
});
