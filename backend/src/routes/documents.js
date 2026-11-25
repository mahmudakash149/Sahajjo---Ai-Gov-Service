const router = require('express').Router();
const multer = require('multer');
const ctrl = require('../controllers/documentController');
const { requireAuth } = require('../middleware/auth');

const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'application/pdf',
]);

const ALLOWED_EXTENSIONS = /\.(jpe?g|png|webp|pdf)$/i;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (_req, file, cb) => {
    if (
      ALLOWED_MIME_TYPES.has(file.mimetype) ||
      (file.mimetype === 'application/octet-stream' && ALLOWED_EXTENSIONS.test(file.originalname))
    ) {
      cb(null, true);
    } else {
      cb(new Error('Unsupported file type. Allowed: JPG, PNG, WEBP, PDF'));
    }
  },
});

router.post('/presign', requireAuth, ctrl.presignUpload);
router.post('/confirm', requireAuth, ctrl.confirmUpload);
router.post('/upload', requireAuth, upload.single('file'), ctrl.uploadDirect);
router.get('/request/:requestId', requireAuth, ctrl.listByRequest);
router.post('/request/:requestId/readiness', requireAuth, ctrl.getReadinessReport);
router.delete('/:id', requireAuth, ctrl.deleteDocument);

module.exports = router;
