const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const config = require('../config');
const { normalizePhone, BD_PHONE } = require('../validators/authValidators');

// Valid bcrypt hash used to equalise timing when the account doesn't exist.
const DUMMY_HASH = bcrypt.hashSync('timing-equaliser-not-a-real-password', config.bcryptRounds);

const publicUser = (u) => ({
  id: u.id,
  fullName: u.full_name,
  phone: u.phone,
  email: u.email,
  preferredLanguage: u.preferred_language,
  role: u.role,
  createdAt: u.created_at,
});

const signToken = (u) =>
  jwt.sign({ role: u.role }, config.jwt.secret, {
    algorithm: 'HS256',
    subject: String(u.id),
    expiresIn: config.jwt.expiresIn,
  });

async function register(req, res, next) {
  try {
    const { fullName, password, preferredLanguage = 'bn' } = req.body;
    const phone = req.body.phone; // already normalised by validator
    const email = req.body.email || null;

    const [dupes] = await pool.execute(
      'SELECT phone, email FROM users WHERE phone = ? OR (email IS NOT NULL AND email = ?) LIMIT 1',
      [phone, email]
    );
    if (dupes.length) {
      const field = dupes[0].phone === phone ? 'phone' : 'email';
      return res.status(409).json({
        message: 'Account already exists',
        errors: { [field]: `This ${field} is already registered` },
      });
    }

    const passwordHash = await bcrypt.hash(password, config.bcryptRounds);
    const [result] = await pool.execute(
      `INSERT INTO users (full_name, phone, email, password_hash, preferred_language, consent_given_at)
       VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP())`,
      [fullName, phone, email, passwordHash, preferredLanguage]
    );

    const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [result.insertId]);
    const user = rows[0];
    return res.status(201).json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Account already exists' });
    }
    return next(err);
  }
}

async function login(req, res, next) {
  const GENERIC = { message: 'Invalid phone/email or password' };
  try {
    const { identifier, password } = req.body;
    const looksLikePhone = BD_PHONE.test(normalizePhone(identifier));
    const [rows] = looksLikePhone
      ? await pool.execute('SELECT * FROM users WHERE phone = ?', [normalizePhone(identifier)])
      : await pool.execute('SELECT * FROM users WHERE email = ?', [identifier.toLowerCase()]);
    const user = rows[0];

    if (!user) {
      await bcrypt.compare(password, DUMMY_HASH);
      return res.status(401).json(GENERIC);
    }

    if (user.locked_until && new Date(user.locked_until) > new Date()) {
      return res.status(429).json({
        message: 'Too many failed attempts. Try again later.',
      });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      const attempts = user.failed_login_attempts + 1;
      if (attempts >= config.maxFailedLogins) {
        await pool.execute(
          `UPDATE users SET failed_login_attempts = 0,
             locked_until = DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? MINUTE) WHERE id = ?`,
          [config.lockMinutes, user.id]
        );
      } else {
        await pool.execute('UPDATE users SET failed_login_attempts = ? WHERE id = ?', [attempts, user.id]);
      }
      return res.status(401).json(GENERIC);
    }

    await pool.execute(
      'UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = UTC_TIMESTAMP() WHERE id = ?',
      [user.id]
    );
    return res.json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    return next(err);
  }
}

async function me(req, res, next) {
  try {
    const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [req.user.id]);
    if (!rows.length) return res.status(404).json({ message: 'User not found' });
    return res.json({ user: publicUser(rows[0]) });
  } catch (err) {
    return next(err);
  }
}

// FR-03: complete deletion control for the citizen.
async function deleteAccount(req, res, next) {
  try {
    await pool.execute('DELETE FROM users WHERE id = ?', [req.user.id]);
    return res.status(204).send();
  } catch (err) {
    return next(err);
  }
}

// In-memory OTP storage fallback if MySQL otp_codes table is not created
const inMemoryOtps = new Map();

// OTP verification for passwordless login & password reset
async function sendOtp(req, res, next) {
  try {
    const { phone } = req.body;

    // Verify user exists with this phone
    const [users] = await pool.execute('SELECT id, full_name, phone FROM users WHERE phone = ?', [phone]);
    if (!users.length) {
      return res.status(404).json({
        message: 'No account registered with this phone number. Please register first.',
      });
    }

    // Generate 6-digit random code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHashed = await bcrypt.hash(code, 10);

    // Attempt saving to DB with fallback to memory
    try {
      const [recent] = await pool.execute(
        'SELECT id FROM otp_codes WHERE phone = ? AND created_at > DATE_SUB(UTC_TIMESTAMP(), INTERVAL 60 SECOND) LIMIT 1',
        [phone]
      );
      if (recent.length) {
        return res.status(429).json({
          message: 'Please wait a minute before requesting another OTP code.',
        });
      }
      await pool.execute(
        'INSERT INTO otp_codes (phone, otp_hash, expires_at) VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 5 MINUTE))',
        [phone, otpHashed]
      );
    } catch (_dbErr) {
      const existing = inMemoryOtps.get(phone);
      if (existing && Date.now() - existing.createdAt < 60 * 1000) {
        return res.status(429).json({
          message: 'Please wait a minute before requesting another OTP code.',
        });
      }
      inMemoryOtps.set(phone, {
        otpHashed,
        expiresAt: Date.now() + 5 * 60 * 1000,
        createdAt: Date.now(),
        consumed: false,
      });
    }

    // Output to server terminal for development/testing
    console.log(`\n==================================================`);
    console.log(`[SMS OTP SERVICE] To: +880${phone.replace(/^0/, '')}`);
    console.log(`Your Sahajjo verification code is: ${code}`);
    console.log(`(Valid for 5 minutes)`);
    console.log(`==================================================\n`);

    const isProd = process.env.NODE_ENV === 'production';
    return res.json({
      message: 'OTP sent successfully',
      devCode: isProd ? undefined : code,
    });
  } catch (err) {
    return next(err);
  }
}

async function verifyOtp(req, res, next) {
  try {
    const { phone, otp } = req.body;
    let verified = false;

    try {
      const [rows] = await pool.execute(
        'SELECT * FROM otp_codes WHERE phone = ? AND consumed = FALSE AND expires_at > UTC_TIMESTAMP() ORDER BY id DESC LIMIT 1',
        [phone]
      );
      if (rows.length) {
        const valid = await bcrypt.compare(otp, rows[0].otp_hash);
        if (!valid) {
          return res.status(401).json({
            message: 'Invalid OTP code. Please check and try again.',
          });
        }
        await pool.execute('UPDATE otp_codes SET consumed = TRUE WHERE id = ?', [rows[0].id]);
        verified = true;
      }
    } catch (_dbErr) {
      // DB table not available; proceed to in-memory check
    }

    if (!verified) {
      const mem = inMemoryOtps.get(phone);
      if (!mem || mem.consumed || Date.now() > mem.expiresAt) {
        return res.status(400).json({
          message: 'OTP has expired or is invalid. Please request a new one.',
        });
      }
      const valid = await bcrypt.compare(otp, mem.otpHashed);
      if (!valid) {
        return res.status(401).json({
          message: 'Invalid OTP code. Please check and try again.',
        });
      }
      mem.consumed = true;
    }

    // Fetch user and log them in
    const [userRows] = await pool.execute('SELECT * FROM users WHERE phone = ?', [phone]);
    if (!userRows.length) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = userRows[0];
    await pool.execute(
      'UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = UTC_TIMESTAMP() WHERE id = ?',
      [user.id]
    );

    return res.json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    return next(err);
  }
}

// Verify OTP specifically for Password Reset flow -> returns a 15-minute resetToken
async function verifyResetOtp(req, res, next) {
  try {
    const { phone, otp } = req.body;

    const [userRows] = await pool.execute('SELECT id, phone FROM users WHERE phone = ?', [phone]);
    if (!userRows.length) {
      return res.status(404).json({ message: 'No account registered with this phone number.' });
    }

    let verified = false;
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM otp_codes WHERE phone = ? AND consumed = FALSE AND expires_at > UTC_TIMESTAMP() ORDER BY id DESC LIMIT 1',
        [phone]
      );
      if (rows.length) {
        const valid = await bcrypt.compare(otp, rows[0].otp_hash);
        if (!valid) {
          return res.status(401).json({ message: 'Invalid OTP code. Please check and try again.' });
        }
        await pool.execute('UPDATE otp_codes SET consumed = TRUE WHERE id = ?', [rows[0].id]);
        verified = true;
      }
    } catch (_dbErr) {
      // Proceed to memory fallback
    }

    if (!verified) {
      const mem = inMemoryOtps.get(phone);
      if (!mem || mem.consumed || Date.now() > mem.expiresAt) {
        return res.status(400).json({ message: 'OTP has expired or is invalid. Please request a new one.' });
      }
      const valid = await bcrypt.compare(otp, mem.otpHashed);
      if (!valid) {
        return res.status(401).json({ message: 'Invalid OTP code. Please check and try again.' });
      }
      mem.consumed = true;
    }

    // Generate secure resetToken
    const resetToken = jwt.sign(
      { phone, purpose: 'password_reset' },
      config.jwt.secret,
      { algorithm: 'HS256', expiresIn: '15m' }
    );

    return res.json({
      message: 'OTP verified successfully. You can now set your new password.',
      resetToken,
    });
  } catch (err) {
    return next(err);
  }
}

// Reset / Change Password and update database
async function resetPassword(req, res, next) {
  try {
    const { phone, resetToken, otp, newPassword } = req.body;

    // Check authorization: either a valid resetToken or a direct valid OTP
    let authorized = false;

    if (resetToken) {
      try {
        const decoded = jwt.verify(resetToken, config.jwt.secret, { algorithms: ['HS256'] });
        if (decoded.phone === phone && decoded.purpose === 'password_reset') {
          authorized = true;
        }
      } catch (_tokenErr) {
        return res.status(401).json({
          message: 'Password reset session has expired or is invalid. Please verify OTP again.',
        });
      }
    }

    if (!authorized && otp) {
      // Direct OTP verification fallback
      try {
        const [rows] = await pool.execute(
          'SELECT * FROM otp_codes WHERE phone = ? AND consumed = FALSE AND expires_at > UTC_TIMESTAMP() ORDER BY id DESC LIMIT 1',
          [phone]
        );
        if (rows.length) {
          const valid = await bcrypt.compare(otp, rows[0].otp_hash);
          if (valid) {
            await pool.execute('UPDATE otp_codes SET consumed = TRUE WHERE id = ?', [rows[0].id]);
            authorized = true;
          }
        }
      } catch (_dbErr) {}

      if (!authorized) {
        const mem = inMemoryOtps.get(phone);
        if (mem && !mem.consumed && Date.now() <= mem.expiresAt) {
          const valid = await bcrypt.compare(otp, mem.otpHashed);
          if (valid) {
            mem.consumed = true;
            authorized = true;
          }
        }
      }
    }

    if (!authorized) {
      return res.status(401).json({
        message: 'Unauthorized password reset attempt. Valid OTP or reset token is required.',
      });
    }

    // Verify user exists
    const [users] = await pool.execute('SELECT id, phone FROM users WHERE phone = ?', [phone]);
    if (!users.length) {
      return res.status(404).json({ message: 'User account not found.' });
    }
    const user = users[0];

    // Hash the new password securely
    const passwordHash = await bcrypt.hash(newPassword, config.bcryptRounds);

    // Update database
    await pool.execute(
      `UPDATE users 
       SET password_hash = ?, failed_login_attempts = 0, locked_until = NULL, updated_at = UTC_TIMESTAMP() 
       WHERE id = ?`,
      [passwordHash, user.id]
    );

    return res.json({
      message: 'Password has been updated successfully. You can now log in with your new password.',
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  register,
  login,
  me,
  deleteAccount,
  sendOtp,
  verifyOtp,
  verifyResetOtp,
  resetPassword,
};
