-- Sahajjo FR3: Service Catalog
-- Run once (safe to run again):  mysql -u root -p < backend/database/services.sql

USE sahajjo;

-- SERVICE_CATEGORY entity from the SRS ERD (Bangla + English text)
CREATE TABLE IF NOT EXISTS service_categories (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name_bn        VARCHAR(100) NOT NULL,
  name_en        VARCHAR(100) NOT NULL,
  description_bn VARCHAR(255) NULL,
  description_en VARCHAR(255) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SERVICE entity from the SRS ERD
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

-- Sample data (INSERT IGNORE + fixed ids, so running again does not duplicate)
INSERT IGNORE INTO service_categories (id, name_bn, name_en, description_bn, description_en) VALUES
  (1, 'পরিচয় ও নিবন্ধন', 'Identity & Registration', 'জন্ম, মৃত্যু ও জাতীয় পরিচয়পত্র সংক্রান্ত সেবা', 'Birth, death and national ID services'),
  (2, 'ভ্রমণ ও যানবাহন',  'Travel & Transport',      'পাসপোর্ট ও ড্রাইভিং লাইসেন্স সংক্রান্ত সেবা', 'Passport and driving license services'),
  (3, 'ভূমি সেবা',        'Land Services',           'জমির নামজারি ও ভূমি সংক্রান্ত সেবা', 'Land mutation and land-related services'),
  (4, 'ব্যবসা',           'Business',                'ট্রেড লাইসেন্স ও ব্যবসা নিবন্ধন সংক্রান্ত সেবা', 'Trade license and business registration');

INSERT IGNORE INTO services (id, category_id, name_bn, name_en, description_bn, description_en, is_priority) VALUES
  (1, 1, 'জন্ম নিবন্ধন',            'Birth Registration',   'নতুন জন্ম নিবন্ধন করা বা জন্ম নিবন্ধন সনদ সংশোধন করা।', 'Register a new birth or correct a birth registration certificate.', 1),
  (2, 1, 'এনআইডি তথ্য সংশোধন',      'NID Correction',       'জাতীয় পরিচয়পত্রের নাম, ঠিকানা বা অন্য তথ্য সংশোধন করা।', 'Correct the name, address or other details on a National ID card.', 1),
  (3, 2, 'পাসপোর্ট সেবা',           'Passport Services',    'নতুন পাসপোর্টের আবেদন, নবায়ন বা তথ্য সংশোধন।', 'Apply for a new passport, renew it, or correct its details.', 1),
  (4, 3, 'ই-নামজারি',               'e-Mutation',           'জমির মালিকানা পরিবর্তনের পর অনলাইনে নামজারির আবেদন।', 'Apply online for land mutation after a change of ownership.', 1),
  (5, 4, 'ট্রেড লাইসেন্স',           'Trade License',        'ব্যবসা চালানোর জন্য নতুন ট্রেড লাইসেন্স বা নবায়ন।', 'Get a new trade license or renew one to run a business.', 1),
  (6, 1, 'মৃত্যু নিবন্ধন',           'Death Registration',   'মৃত্যুর ঘটনা নিবন্ধন করা ও মৃত্যু সনদ সংগ্রহ।', 'Register a death and obtain a death certificate.', 0),
  (7, 2, 'ড্রাইভিং লাইসেন্স',        'Driving License',      'নতুন ড্রাইভিং লাইসেন্স বা নবায়নের আবেদন।', 'Apply for a new driving license or renewal.', 0),
  (8, 4, 'টিআইএন নিবন্ধন',          'TIN Registration',     'কর শনাক্তকরণ নম্বর (TIN) পাওয়ার জন্য নিবন্ধন।', 'Register to get a Taxpayer Identification Number (TIN).', 0);
