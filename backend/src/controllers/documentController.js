const fs = require('fs');
const path = require('path');
const pool = require('../db');
const { ensureDocumentsTable } = require('../initDb');
const s3Service = require('../services/s3Service');
const { extractDocumentFields } = require('../services/ocrService');
const { evaluateReadiness } = require('../services/readinessService');

const STORE_PATH = path.join(__dirname, '../../database/documents_store.json');

function loadFallbackStore() {
  try {
    if (fs.existsSync(STORE_PATH)) {
      const list = JSON.parse(fs.readFileSync(STORE_PATH, 'utf8'));
      if (Array.isArray(list)) return list;
    }
  } catch (e) {
    console.warn('[Document Controller] Error loading documents_store.json:', e.message);
  }
  return [];
}

function saveFallbackStore(list) {
  try {
    const dir = path.dirname(STORE_PATH);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(STORE_PATH, JSON.stringify(list, null, 2), 'utf8');
  } catch (e) {
    console.warn('[Document Controller] Error saving documents_store.json:', e.message);
  }
}

const inMemoryDocs = loadFallbackStore();
let memoryDocId = inMemoryDocs.reduce((max, d) => Math.max(max, Number(d.id) || 0), 0) + 1;

function sanitizeFileName(name) {
  return String(name || 'document')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .slice(0, 120);
}

function buildObjectKey(userId, requestId, fileName) {
  return `requests/${userId}/${requestId}/${Date.now()}_${sanitizeFileName(fileName)}`;
}

async function persistDocument(record) {
  try {
    const ocrJson = JSON.stringify(record.ocrData || {});
    let insertResult;
    try {
      const [result] = await pool.execute(
        `INSERT INTO request_documents
         (request_id, user_id, doc_type, file_name, file_size, mime_type, s3_bucket, s3_key, ocr_data, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP())`,
        [
          record.requestId,
          record.userId,
          record.docType,
          record.fileName,
          record.fileSize,
          record.mimeType,
          record.s3Bucket,
          record.s3Key,
          ocrJson,
        ]
      );
      insertResult = result;
    } catch (err) {
      if (err.code === 'ER_NO_SUCH_TABLE' || err.errno === 1146) {
        await ensureDocumentsTable();
        const [result] = await pool.execute(
          `INSERT INTO request_documents
           (request_id, user_id, doc_type, file_name, file_size, mime_type, s3_bucket, s3_key, ocr_data, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP())`,
          [
            record.requestId,
            record.userId,
            record.docType,
            record.fileName,
            record.fileSize,
            record.mimeType,
            record.s3Bucket,
            record.s3Key,
            ocrJson,
          ]
        );
        insertResult = result;
      } else {
        throw err;
      }
    }

    const saved = { ...record, id: insertResult.insertId, createdAt: new Date().toISOString() };
    if (!inMemoryDocs.some((d) => d.id === saved.id)) {
      inMemoryDocs.push(saved);
      saveFallbackStore(inMemoryDocs);
    }
    return saved;
  } catch (dbErr) {
    console.warn('[Document Controller] DB unavailable (' + dbErr.message + '). Storing in documents_store.json.');
    const fallbackItem = { ...record, id: memoryDocId++, createdAt: new Date().toISOString() };
    inMemoryDocs.push(fallbackItem);
    saveFallbackStore(inMemoryDocs);
    return fallbackItem;
  }
}

async function fetchDocumentsForRequest(userId, requestId) {
  try {
    let rows;
    try {
      const [dbRows] = await pool.execute(
        `SELECT id, request_id AS requestId, user_id AS userId, doc_type AS docType,
                file_name AS fileName, file_size AS fileSize, mime_type AS mimeType,
                s3_bucket AS s3Bucket, s3_key AS s3Key, ocr_data AS ocrData, created_at AS createdAt
         FROM request_documents
         WHERE user_id = ? AND request_id = ?
         ORDER BY id ASC`,
        [userId, requestId]
      );
      rows = dbRows;
    } catch (err) {
      if (err.code === 'ER_NO_SUCH_TABLE' || err.errno === 1146) {
        await ensureDocumentsTable();
        const [dbRows] = await pool.execute(
          `SELECT id, request_id AS requestId, user_id AS userId, doc_type AS docType,
                  file_name AS fileName, file_size AS fileSize, mime_type AS mimeType,
                  s3_bucket AS s3Bucket, s3_key AS s3Key, ocr_data AS ocrData, created_at AS createdAt
           FROM request_documents
           WHERE user_id = ? AND request_id = ?
           ORDER BY id ASC`,
          [userId, requestId]
        );
        rows = dbRows;
      } else {
        throw err;
      }
    }

    return rows.map((r) => ({
      ...r,
      ocrData: typeof r.ocrData === 'string' ? JSON.parse(r.ocrData) : r.ocrData,
    }));
  } catch (_dbErr) {
    return inMemoryDocs.filter(
      (d) => Number(d.userId) === Number(userId) && String(d.requestId) === String(requestId)
    );
  }
}

// POST /api/documents/presign
async function presignUpload(req, res, next) {
  try {
    const userId = req.user.id;
    const { requestId, docType = 'OTHER', fileName, mimeType = 'image/jpeg' } = req.body;

    if (!requestId || !fileName) {
      return res.status(400).json({ message: 'requestId and fileName are required' });
    }

    const objectKey = buildObjectKey(userId, requestId, fileName);
    const uploadUrl = await s3Service.createPresignedUploadUrl(objectKey, mimeType, 300);

    return res.json({
      uploadUrl,
      objectKey,
      bucket: s3Service.BUCKET,
      docType,
      expiresIn: 300,
    });
  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      return res.status(503).json({
        message: 'Object storage (SeaweedFS S3) is not running. Start it with storage/start-s3.ps1.',
      });
    }
    return next(err);
  }
}

// POST /api/documents/confirm
async function confirmUpload(req, res, next) {
  try {
    const userId = req.user.id;
    const {
      requestId,
      docType = 'OTHER',
      objectKey,
      fileName,
      fileSize = 0,
      mimeType = 'image/jpeg',
      language = 'bn',
    } = req.body;

    if (!requestId || !objectKey || !fileName) {
      return res.status(400).json({ message: 'requestId, objectKey, and fileName are required' });
    }

    const buffer = await s3Service.getObjectBuffer(objectKey);
    const ocrData = await extractDocumentFields(buffer, mimeType, docType, language);

    const saved = await persistDocument({
      requestId: Number(requestId),
      userId,
      docType,
      fileName,
      fileSize: Number(fileSize) || buffer.length,
      mimeType,
      s3Bucket: s3Service.BUCKET,
      s3Key: objectKey,
      ocrData,
    });

    return res.status(201).json({
      message: 'Document confirmed and OCR processed successfully',
      document: saved,
    });
  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      return res.status(503).json({
        message: 'Object storage (SeaweedFS S3) is not running. Start it with storage/start-s3.ps1.',
      });
    }
    return next(err);
  }
}

// POST /api/documents/upload (multipart direct upload -> S3 -> OCR)
async function uploadDirect(req, res, next) {
  try {
    const userId = req.user.id;
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const requestId = req.body.requestId;
    const docType = req.body.docType || 'OTHER';
    const language = req.body.language || 'bn';
    const resolvedMime =
      req.body.mimeType ||
      (req.file.mimetype !== 'application/octet-stream' ? req.file.mimetype : 'image/jpeg');

    if (!requestId) {
      return res.status(400).json({ message: 'requestId is required' });
    }

    const objectKey = buildObjectKey(userId, requestId, req.file.originalname);
    await s3Service.uploadBuffer(objectKey, req.file.buffer, resolvedMime);

    const ocrData = await extractDocumentFields(
      req.file.buffer,
      resolvedMime,
      docType,
      language
    );

    const saved = await persistDocument({
      requestId: Number(requestId),
      userId,
      docType,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: resolvedMime,
      s3Bucket: s3Service.BUCKET,
      s3Key: objectKey,
      ocrData,
    });

    return res.status(201).json({
      message: 'Document uploaded to S3 and OCR processed successfully',
      document: saved,
    });
  } catch (err) {
    if (err.code === 'ECONNREFUSED') {
      return res.status(503).json({
        message: 'Object storage (SeaweedFS S3) is not running. Start it with storage/start-s3.ps1.',
      });
    }
    return next(err);
  }
}

// GET /api/documents/request/:requestId
async function listByRequest(req, res, next) {
  try {
    const userId = req.user.id;
    const requestId = req.params.requestId;
    const documents = await fetchDocumentsForRequest(userId, requestId);
    return res.json({ documents });
  } catch (err) {
    return next(err);
  }
}

// POST /api/documents/request/:requestId/readiness
async function getReadinessReport(req, res, next) {
  try {
    const userId = req.user.id;
    const requestId = req.params.requestId;
    const requiredDocuments = Array.isArray(req.body.requiredDocuments)
      ? req.body.requiredDocuments
      : [];

    const uploadedDocs = await fetchDocumentsForRequest(userId, requestId);
    const report = evaluateReadiness({ requiredDocuments, uploadedDocs });
    return res.json({ report });
  } catch (err) {
    return next(err);
  }
}

// DELETE /api/documents/:id
async function deleteDocument(req, res, next) {
  try {
    const userId = req.user.id;
    const docId = Number(req.params.id);
    let s3Key = null;

    try {
      const [rows] = await pool.execute(
        'SELECT id, s3_key AS s3Key FROM request_documents WHERE id = ? AND user_id = ?',
        [docId, userId]
      );
      if (rows.length > 0) {
        s3Key = rows[0].s3Key;
        await pool.execute('DELETE FROM request_documents WHERE id = ? AND user_id = ?', [
          docId,
          userId,
        ]);
      }
    } catch (_dbErr) {
      // Fallback to in-memory store
    }

    const idx = inMemoryDocs.findIndex((d) => Number(d.id) === docId && Number(d.userId) === Number(userId));
    if (idx !== -1) {
      if (!s3Key) s3Key = inMemoryDocs[idx].s3Key;
      inMemoryDocs.splice(idx, 1);
      saveFallbackStore(inMemoryDocs);
    }

    if (s3Key) {
      await s3Service.deleteObject(s3Key);
    }

    return res.json({ message: 'Document deleted' });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  presignUpload,
  confirmUpload,
  uploadDirect,
  listByRequest,
  getReadinessReport,
  deleteDocument,
};
