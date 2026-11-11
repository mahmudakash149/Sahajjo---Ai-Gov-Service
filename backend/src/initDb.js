const pool = require('./db');

const CREATE_USERS_TABLE = `
CREATE TABLE IF NOT EXISTS users (
  id                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  full_name             VARCHAR(100)     NOT NULL,
  phone                 VARCHAR(15)      NOT NULL,
  email                 VARCHAR(254)     NULL,
  password_hash         VARCHAR(255)     NOT NULL,
  preferred_language    ENUM('bn','en')  NOT NULL DEFAULT 'bn',
  role                  ENUM('citizen','admin') NOT NULL DEFAULT 'citizen',
  consent_given_at      DATETIME         NOT NULL,
  failed_login_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  locked_until          DATETIME         NULL,
  last_login_at         DATETIME         NULL,
  created_at            TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_phone (phone),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;
`;

const CREATE_OTP_TABLE = `
CREATE TABLE IF NOT EXISTS otp_codes (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  phone       VARCHAR(15)     NOT NULL,
  otp_hash    VARCHAR(255)    NOT NULL,
  expires_at  DATETIME        NOT NULL,
  consumed    BOOLEAN         NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_otp_phone_active (phone, consumed, expires_at)
) ENGINE=InnoDB;
`;

const CREATE_CATEGORIES_TABLE = `
CREATE TABLE IF NOT EXISTS service_categories (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name_bn        VARCHAR(100) NOT NULL,
  name_en        VARCHAR(100) NOT NULL,
  description_bn VARCHAR(255) NULL,
  description_en VARCHAR(255) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

const CREATE_SERVICES_TABLE = `
CREATE TABLE IF NOT EXISTS services (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id    INT UNSIGNED NOT NULL,
  name_bn        VARCHAR(150) NOT NULL,
  name_en        VARCHAR(150) NOT NULL,
  description_bn VARCHAR(500) NOT NULL,
  description_en VARCHAR(500) NOT NULL,
  is_priority    TINYINT(1)   NOT NULL DEFAULT 0,
  status         ENUM('active','archived') NOT NULL DEFAULT 'active',
  PRIMARY KEY (id),
  KEY idx_services_category (category_id),
  CONSTRAINT fk_services_category FOREIGN KEY (category_id)
    REFERENCES service_categories (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

const CREATE_REQUESTS_TABLE = `
CREATE TABLE IF NOT EXISTS service_requests (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  request_text TEXT            NOT NULL,
  language     VARCHAR(10)     NOT NULL DEFAULT 'bn',
  status       VARCHAR(30)     NOT NULL DEFAULT 'submitted',
  ai_diagnosis JSON            NULL,
  created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_requests_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

const SEED_CATEGORIES = [
  [1, 'পরিচয় ও নিবন্ধন', 'Identity & Registration', 'জন্ম, মৃত্যু ও জাতীয় পরিচয়পত্র সংক্রান্ত সেবা', 'Birth, death and national ID services'],
  [2, 'ভ্রমণ ও যানবাহন',  'Travel & Transport',      'পাসপোর্ট ও ড্রাইভিং লাইসেন্স সংক্রান্ত সেবা', 'Passport and driving license services'],
  [3, 'ভূমি সেবা',        'Land Services',           'জমির নামজারি ও ভূমি সংক্রান্ত সেবা', 'Land mutation and land-related services'],
  [4, 'ব্যবসা',           'Business',                'ট্রেড লাইসেন্স ও ব্যবসা নিবন্ধন সংক্রান্ত সেবা', 'Trade license and business registration']
];

const SEED_SERVICES = [
  [1, 1, 'জন্ম নিবন্ধন',       'Birth Registration',   'নতুন জন্ম নিবন্ধন করা বা জন্ম নিবন্ধন সনদ সংশোধন করা।', 'Register a new birth or correct a birth registration certificate.', 1],
  [2, 1, 'এনআইডি তথ্য সংশোধন', 'NID Correction',       'জাতীয় পরিচয়পত্রের নাম, ঠিকানা বা অন্য তথ্য সংশোধন করা।', 'Correct the name, address or other details on a National ID card.', 1],
  [3, 2, 'পাসপোর্ট সেবা',      'Passport Services',    'নতুন পাসপোর্টের আবেদন, নবায়ন বা তথ্য সংশোধন।', 'Apply for a new passport, renew it, or correct its details.', 1],
  [4, 3, 'ই-নামজারি',          'e-Mutation',           'জমির মালিকানা পরিবর্তনের পর অনলাইনে নামজারির আবেদন।', 'Apply online for land mutation after a change of ownership.', 1],
  [5, 4, 'ট্রেড লাইসেন্স',      'Trade License',        'ব্যবসা চালানোর জন্য নতুন ট্রেড লাইসেন্স বা নবায়ন।', 'Get a new trade license or renew one to run a business.', 1],
  [6, 1, 'মৃত্যু নিবন্ধন',      'Death Registration',   'মৃত্যুর ঘটনা নিবন্ধন করা ও মৃত্যু সনদ সংগ্রহ।', 'Register a death and obtain a death certificate.', 0],
  [7, 2, 'ড্রাইভিং লাইসেন্স',   'Driving License',      'নতুন ড্রাইভিং লাইসেন্স বা নবায়নের আবেদন।', 'Apply for a new driving license or renewal.', 0],
  [8, 4, 'টিআইএন নিবন্ধন',     'TIN Registration',     'কর শনাক্তকরণ নম্বর (TIN) পাওয়ার জন্য নিবন্ধন।', 'Register to get a Taxpayer Identification Number (TIN).', 0]
];

async function ensureRequestsTable() {
  try {
    await pool.execute(CREATE_REQUESTS_TABLE);
    return true;
  } catch (err) {
    console.warn('[initDb] Could not ensure service_requests table:', err.message);
    return false;
  }
}

async function initDatabase() {
  try {
    // 1. Ensure core auth & users tables
    await pool.execute(CREATE_USERS_TABLE);
    await pool.execute(CREATE_OTP_TABLE);

    // 2. Ensure categories & services tables
    await pool.execute(CREATE_CATEGORIES_TABLE);
    await pool.execute(CREATE_SERVICES_TABLE);

    // 3. Seed default categories if empty
    const [catRows] = await pool.execute('SELECT COUNT(*) AS count FROM service_categories');
    if (catRows[0].count === 0) {
      for (const cat of SEED_CATEGORIES) {
        await pool.execute(
          'INSERT IGNORE INTO service_categories (id, name_bn, name_en, description_bn, description_en) VALUES (?, ?, ?, ?, ?)',
          cat
        );
      }
    }

    // 4. Seed default services if empty
    const [svcRows] = await pool.execute('SELECT COUNT(*) AS count FROM services');
    if (svcRows[0].count === 0) {
      for (const s of SEED_SERVICES) {
        await pool.execute(
          'INSERT IGNORE INTO services (id, category_id, name_bn, name_en, description_bn, description_en, is_priority) VALUES (?, ?, ?, ?, ?, ?, ?)',
          s
        );
      }
    }

    // 5. Ensure service_requests table
    await pool.execute(CREATE_REQUESTS_TABLE);

    console.log('[initDb] Database schema and tables verified successfully.');
    return true;
  } catch (err) {
    console.warn('[initDb] Database initialization warning:', err.message);
    return false;
  }
}

module.exports = {
  initDatabase,
  ensureRequestsTable,
  CREATE_REQUESTS_TABLE,
};
