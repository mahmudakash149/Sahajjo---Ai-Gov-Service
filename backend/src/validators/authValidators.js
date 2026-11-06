const { body, validationResult } = require('express-validator');

// Bangladesh mobile: 01[3-9]XXXXXXXX, optionally prefixed with +88 / 88.
const BD_PHONE = /^(?:\+?88)?01[3-9]\d{8}$/;

function normalizePhone(value) {
  return String(value).trim().replace(/[\s-]/g, '').replace(/^\+?88/, '');
}

const passwordRules = body('password')
  .isString().withMessage('Password is required')
  .isLength({ min: 8, max: 72 }).withMessage('Password must be 8-72 characters')
  .matches(/[a-z]/).withMessage('Password needs a lowercase letter')
  .matches(/[A-Z]/).withMessage('Password needs an uppercase letter')
  .matches(/\d/).withMessage('Password needs a digit')
  .matches(/[^A-Za-z0-9]/).withMessage('Password needs a special character');

const registerRules = [
  body('fullName')
    .isString().trim()
    .isLength({ min: 2, max: 100 }).withMessage('Full name must be 2-100 characters')
    .matches(/^[\p{L}\p{M}][\p{L}\p{M}\s.'-]*$/u).withMessage('Full name contains invalid characters'),
  body('phone')
    .isString().withMessage('Phone is required')
    .customSanitizer(normalizePhone)
    .matches(BD_PHONE).withMessage('Enter a valid Bangladeshi mobile number (01XXXXXXXXX)'),
  body('email')
    .optional({ values: 'falsy' })
    .isString().trim()
    .isEmail().withMessage('Enter a valid email address')
    .isLength({ max: 254 })
    .normalizeEmail({ gmail_remove_dots: false }),
  passwordRules,
  body('confirmPassword')
    .custom((v, { req }) => v === req.body.password)
    .withMessage('Passwords do not match'),
  body('preferredLanguage')
    .optional()
    .isIn(['bn', 'en']).withMessage('Language must be bn or en'),
  body('consent')
    .custom((v) => v === true)
    .withMessage('You must accept the privacy consent to register'),
];

const loginRules = [
  body('identifier')
    .isString().trim()
    .notEmpty().withMessage('Phone or email is required')
    .isLength({ max: 254 }),
  body('password')
    .isString().withMessage('Password is required')
    .notEmpty().withMessage('Password is required')
    .isLength({ max: 72 }),
];

function validate(req, res, next) {
  const result = validationResult(req);
  if (result.isEmpty()) return next();
  const errors = {};
  for (const e of result.array()) {
    if (!errors[e.path]) errors[e.path] = e.msg;
  }
  return res.status(422).json({ message: 'Validation failed', errors });
}

module.exports = { registerRules, loginRules, validate, normalizePhone, BD_PHONE };
