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

module.exports = { register, login, me, deleteAccount };
