USE sahajjo;

-- OTP entity for passwordless SMS/OTP login
CREATE TABLE IF NOT EXISTS otp_codes (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  phone       VARCHAR(15)     NOT NULL,            -- normalised BD format: 01XXXXXXXXX
  otp_hash    VARCHAR(255)    NOT NULL,            -- bcrypt hash of the 6-digit code
  expires_at  DATETIME        NOT NULL,            -- 5-minute validity window
  consumed    BOOLEAN         NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_otp_phone_active (phone, consumed, expires_at)
) ENGINE=InnoDB;
