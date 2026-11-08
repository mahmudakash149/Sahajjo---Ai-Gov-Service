const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { validationResult } = require('express-validator');
const config = require('../src/config');
const {
  normalizePhone,
  BD_PHONE,
  resetPasswordRules,
  verifyResetOtpRules,
} = require('../src/validators/authValidators');

test('Password Reset & OTP Security Test Suite', async (t) => {
  await t.test('1. Should validate and normalize Bangladeshi phone numbers for reset', () => {
    assert.equal(normalizePhone('+8801712345678'), '01712345678');
    assert.equal(normalizePhone('8801812345678'), '01812345678');
    assert.equal(normalizePhone('01912-345678'), '01912345678');
    assert.ok(BD_PHONE.test(normalizePhone('01712345678')));
    assert.ok(!BD_PHONE.test(normalizePhone('01212345678'))); // 012 is invalid operator
    assert.ok(!BD_PHONE.test(normalizePhone('12345')));
  });

  await t.test('2. Should issue and verify a valid password_reset JWT token', () => {
    const phone = '01712345678';
    const resetToken = jwt.sign(
      { phone, purpose: 'password_reset' },
      config.jwt.secret,
      { algorithm: 'HS256', expiresIn: '15m' }
    );

    const decoded = jwt.verify(resetToken, config.jwt.secret, { algorithms: ['HS256'] });
    assert.equal(decoded.phone, phone);
    assert.equal(decoded.purpose, 'password_reset');
  });

  await t.test('3. Should reject tampered or expired password_reset tokens', () => {
    const fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature';
    assert.throws(() => {
      jwt.verify(fakeToken, config.jwt.secret);
    });

    const wrongSecretToken = jwt.sign(
      { phone: '01712345678', purpose: 'password_reset' },
      'wrong-secret'
    );
    assert.throws(() => {
      jwt.verify(wrongSecretToken, config.jwt.secret);
    });
  });

  await t.test('4. Should reject tokens generated for a different purpose (e.g. login session)', () => {
    const sessionToken = jwt.sign(
      { sub: '123', role: 'citizen' },
      config.jwt.secret,
      { algorithm: 'HS256', expiresIn: '1h' }
    );

    const decoded = jwt.verify(sessionToken, config.jwt.secret);
    assert.notEqual(decoded.purpose, 'password_reset');
  });

  await t.test('5. Should verify new password hashing matches bcrypt work factor', async () => {
    const newPassword = 'NewSecretPassword123@';
    const hash = await bcrypt.hash(newPassword, config.bcryptRounds);
    assert.ok(hash.startsWith('$2'));

    const match = await bcrypt.compare(newPassword, hash);
    assert.equal(match, true);

    const mismatch = await bcrypt.compare('WrongPassword123@', hash);
    assert.equal(mismatch, false);
  });

  await t.test('6. Should validate resetPasswordRules rejects invalid inputs', async () => {
    const req = {
      body: {
        phone: '12345',
        newPassword: 'weak',
        confirmPassword: 'not-matching',
      },
    };
    for (const rule of resetPasswordRules) {
      await rule.run(req);
    }
    const result = validationResult(req);
    assert.equal(result.isEmpty(), false);
    const errMap = result.mapped();
    assert.ok(errMap.phone, 'Should flag invalid phone');
    assert.ok(errMap.newPassword, 'Should flag weak password');
    assert.ok(errMap.confirmPassword, 'Should flag mismatched password');
  });

  await t.test('7. Should accept valid resetPassword inputs meeting all security constraints', async () => {
    const req = {
      body: {
        phone: '01712345678',
        resetToken: 'some-token',
        newPassword: 'ValidPassword123@',
        confirmPassword: 'ValidPassword123@',
      },
    };
    for (const rule of resetPasswordRules) {
      await rule.run(req);
    }
    const result = validationResult(req);
    assert.equal(result.isEmpty(), true, 'Valid password reset payload should pass validation');
  });

  await t.test('8. Should validate verifyResetOtpRules requirements', async () => {
    const reqBad = {
      body: { phone: '01712345678', otp: '12' }, // bad otp length
    };
    for (const rule of verifyResetOtpRules) {
      await rule.run(reqBad);
    }
    const resBad = validationResult(reqBad);
    assert.equal(resBad.isEmpty(), false);
    assert.ok(resBad.mapped().otp);

    const reqGood = {
      body: { phone: '01712345678', otp: '123456' },
    };
    for (const rule of verifyResetOtpRules) {
      await rule.run(reqGood);
    }
    const resGood = validationResult(reqGood);
    assert.equal(resGood.isEmpty(), true);
  });
});
