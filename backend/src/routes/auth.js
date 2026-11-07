const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/authController');
const { registerRules, loginRules, validate } = require('../validators/authValidators');
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
router.get('/me', requireAuth, ctrl.me);
router.delete('/me', requireAuth, ctrl.deleteAccount);

module.exports = router;
