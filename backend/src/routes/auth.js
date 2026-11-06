const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/authController');
const { registerRules, loginRules, sendOtpRules, verifyOtpRules, validate } = require('../validators/authValidators');
const { requireAuth } = require('../middleware/auth');

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later.' },
});

router.post('/register', authLimiter, registerRules, validate, ctrl.register);
router.post('/login', authLimiter, loginRules, validate, ctrl.login);
router.post('/otp/send', authLimiter, sendOtpRules, validate, ctrl.sendOtp);
router.post('/otp/verify', authLimiter, verifyOtpRules, validate, ctrl.verifyOtp);
router.get('/me', requireAuth, ctrl.me);
router.delete('/me', requireAuth, ctrl.deleteAccount);

module.exports = router;
