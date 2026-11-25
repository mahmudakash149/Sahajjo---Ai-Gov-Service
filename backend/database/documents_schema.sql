-- Sahajjo FR11-FR15: Uploaded Documents & OCR Schema
-- Run once (safe to rerun): mysql -u root -p sahajjo < backend/database/documents_schema.sql

USE sahajjo;

CREATE TABLE IF NOT EXISTS request_documents (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  request_id   BIGINT UNSIGNED NOT NULL,
  user_id      BIGINT UNSIGNED NOT NULL,
  doc_type     VARCHAR(50)     NOT NULL,
  file_name    VARCHAR(255)    NOT NULL,
  file_size    INT UNSIGNED    NOT NULL DEFAULT 0,
  mime_type    VARCHAR(100)    NOT NULL,
  s3_bucket    VARCHAR(100)    NOT NULL,
  s3_key       VARCHAR(500)    NOT NULL,
  ocr_data     JSON            NULL,
  created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_docs_request (request_id),
  KEY idx_docs_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
