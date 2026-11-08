const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/authController');
const {
  registerRules,
  loginRules,
  sendOtpRules,
  verifyOtpRules,
  verifyResetOtpRules,
  resetPasswordRules,
  validate,
} = require('../validators/authValidators');
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

// Password Reset endpoints (FR1 / Security)
router.post('/reset-password/send-otp', authLimiter, sendOtpRules, validate, ctrl.sendOtp);
router.post('/reset-password/verify-otp', authLimiter, verifyResetOtpRules, validate, ctrl.verifyResetOtp);
router.post('/reset-password', authLimiter, resetPasswordRules, validate, ctrl.resetPassword);

router.get('/me', requireAuth, ctrl.me);
router.delete('/me', requireAuth, ctrl.deleteAccount);

module.exports = router;
