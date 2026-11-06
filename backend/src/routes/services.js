const router = require('express').Router();
const ctrl = require('../controllers/serviceController');
const { requireAuth } = require('../middleware/auth');

router.get('/', requireAuth, ctrl.listServices);

module.exports = router;
