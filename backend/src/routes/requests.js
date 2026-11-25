const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/requestController');
const { createRequestRules, followUpRules, validate } = require('../validators/requestValidators');
const { requireAuth } = require('../middleware/auth');

const requestLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests submitted. Please wait a few minutes.' },
});

// FR4: Citizen Service Request Routes
router.post('/', requireAuth, requestLimiter, createRequestRules, validate, ctrl.createRequest);
router.get('/my', requireAuth, ctrl.listMyRequests);

// FR6: Follow-up Questions and Refined Guidance Route
router.post('/:id/follow-up', requireAuth, requestLimiter, followUpRules, validate, ctrl.submitFollowUp);

module.exports = router;
