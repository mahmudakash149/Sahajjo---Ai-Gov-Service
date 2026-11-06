-- Sahajjo Phase 1: Authentication Module
-- MySQL 8.0+  |  Run: mysql -u <user> -p < database/schema.sql

CREATE DATABASE IF NOT EXISTS sahajjo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sahajjo;

-- USER entity from the SRS ERD: "Accounts, language & settings".
-- Data minimisation (FR-03): only name, phone, optional email, language, consent.
CREATE TABLE IF NOT EXISTS users (
  id                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  full_name             VARCHAR(100)     NOT NULL,
  phone                 VARCHAR(15)      NOT NULL,            -- normalised BD format: 01XXXXXXXXX
  email                 VARCHAR(254)     NULL,
  password_hash         VARCHAR(255)     NOT NULL,            -- bcrypt hash only, never plaintext
  preferred_language    ENUM('bn','en')  NOT NULL DEFAULT 'bn',
  role                  ENUM('citizen','admin') NOT NULL DEFAULT 'citizen',
  consent_given_at      DATETIME         NOT NULL,            -- explicit privacy consent (FR-03)
  failed_login_attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  locked_until          DATETIME         NULL,
  last_login_at         DATETIME         NULL,
  created_at            TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_phone (phone),
  UNIQUE KEY uq_users_email (email)       -- NULLs allowed multiple times in MySQL
) ENGINE=InnoDB;
