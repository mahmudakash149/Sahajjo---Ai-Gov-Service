-- Sahajjo FR4: Service Request Input Schema
-- Run once (safe to rerun): mysql -u root -p sahajjo < backend/database/requests_schema.sql

USE sahajjo;

CREATE TABLE IF NOT EXISTS service_requests (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  request_text TEXT            NOT NULL,
  language     ENUM('bn','en') NOT NULL DEFAULT 'bn',
  status       ENUM('submitted','under_review','processed') NOT NULL DEFAULT 'submitted',
  created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_requests_user (user_id),
  CONSTRAINT fk_requests_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
