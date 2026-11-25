const { body, validationResult } = require('express-validator');

// FR4: Validation for citizen service request input in Bangla or English
const createRequestRules = [
  body('requestText')
    .isString().withMessage('Request text must be a string')
    .trim()
    .notEmpty().withMessage('Please describe the service or problem you need help with')
    .isLength({ min: 3, max: 1500 }).withMessage('Request must be between 3 and 1500 characters'),
  body('language')
    .optional()
    .isIn(['bn', 'en']).withMessage('Language must be either bn or en'),
];

// FR6: Validation for follow-up question responses
const followUpRules = [
  body('answers')
    .custom((value) => {
      if (!value) {
        throw new Error('Answers must be provided');
      }
      if (Array.isArray(value)) {
        if (value.length === 0) throw new Error('Answers list cannot be empty');
        return true;
      }
      if (typeof value === 'object' && Object.keys(value).length > 0) {
        return true;
      }
      throw new Error('Answers must be an array or key-value object');
    }),
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

module.exports = {
  createRequestRules,
  followUpRules,
  validate,
};
