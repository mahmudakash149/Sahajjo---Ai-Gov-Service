const fs = require('fs');
const path = require('path');
const pool = require('../db');
const { identifyServiceWithGemini } = require('../services/geminiService');
const { ensureRequestsTable } = require('../initDb');

// Persistent store fallback file path
const STORE_PATH = path.join(__dirname, '../../database/requests_store.json');

function loadFallbackStore() {
  try {
    if (fs.existsSync(STORE_PATH)) {
      const data = fs.readFileSync(STORE_PATH, 'utf8');
      const list = JSON.parse(data);
      if (Array.isArray(list)) return list;
    }
  } catch (e) {
    console.warn('[Request Controller] Error loading requests_store.json:', e.message);
  }
  return [];
}

function saveFallbackStore(list) {
  try {
    const dir = path.dirname(STORE_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(STORE_PATH, JSON.stringify(list, null, 2), 'utf8');
  } catch (e) {
    console.warn('[Request Controller] Error saving requests_store.json:', e.message);
  }
}

// In-memory cache synced with persistent file
const inMemoryRequests = loadFallbackStore();
let memoryReqId = inMemoryRequests.reduce((max, r) => Math.max(max, Number(r.id) || 0), 0) + 1;

// FR4 + Service Identification: Accept request & identify service using Gemini
// POST /api/requests
async function createRequest(req, res, next) {
  try {
    const userId = req.user.id;
    const requestText = req.body.requestText.trim();
    const language = req.body.language || 'bn';

    // 1. Identify service and generate guidelines with Gemini AI
    const aiDiagnosis = await identifyServiceWithGemini(requestText, language);
    const diagnosisJson = JSON.stringify(aiDiagnosis);

    try {
      let insertResult;
      try {
        const [result] = await pool.execute(
          `INSERT INTO service_requests (user_id, request_text, language, status, ai_diagnosis, created_at)
           VALUES (?, ?, ?, 'processed', ?, UTC_TIMESTAMP())`,
          [userId, requestText, language, diagnosisJson]
        );
        insertResult = result;
      } catch (err) {
        if (err.code === 'ER_NO_SUCH_TABLE' || err.errno === 1146) {
          console.warn('[Request Controller] Table service_requests missing. Auto-creating...');
          await ensureRequestsTable();
          const [result] = await pool.execute(
            `INSERT INTO service_requests (user_id, request_text, language, status, ai_diagnosis, created_at)
             VALUES (?, ?, ?, 'processed', ?, UTC_TIMESTAMP())`,
            [userId, requestText, language, diagnosisJson]
          );
          insertResult = result;
        } else {
          throw err;
        }
      }

      const reqData = {
        id: insertResult.insertId,
        userId,
        requestText,
        language,
        status: 'processed',
        aiDiagnosis,
        createdAt: new Date().toISOString(),
      };

      // Keep persistent backup updated
      if (!inMemoryRequests.some((r) => r.id === reqData.id)) {
        inMemoryRequests.push(reqData);
        saveFallbackStore(inMemoryRequests);
      }

      return res.status(201).json({
        message: 'Service request submitted and analyzed successfully',
        request: reqData,
      });
    } catch (dbErr) {
      console.warn('[Request Controller] DB unavailable (' + dbErr.message + '). Storing in persistent file fallback.');
      const fallbackItem = {
        id: memoryReqId++,
        userId,
        requestText,
        language,
        status: 'processed',
        aiDiagnosis,
        createdAt: new Date().toISOString(),
      };
      inMemoryRequests.push(fallbackItem);
      saveFallbackStore(inMemoryRequests);

      return res.status(201).json({
        message: 'Service request submitted and analyzed successfully',
        request: fallbackItem,
      });
    }
  } catch (err) {
    return next(err);
  }
}

// GET /api/requests/my - Get citizen's recent submitted service requests
async function listMyRequests(req, res, next) {
  try {
    const userId = req.user.id;

    try {
      let rows;
      try {
        const [dbRows] = await pool.execute(
          `SELECT id, user_id AS userId, request_text AS requestText, language, status, ai_diagnosis AS aiDiagnosis, created_at AS createdAt
           FROM service_requests
           WHERE user_id = ?
           ORDER BY id DESC
           LIMIT 50`,
          [userId]
        );
        rows = dbRows;
      } catch (err) {
        if (err.code === 'ER_NO_SUCH_TABLE' || err.errno === 1146) {
          console.warn('[Request Controller] Table service_requests missing. Auto-creating...');
          await ensureRequestsTable();
          const [dbRows] = await pool.execute(
            `SELECT id, user_id AS userId, request_text AS requestText, language, status, ai_diagnosis AS aiDiagnosis, created_at AS createdAt
             FROM service_requests
             WHERE user_id = ?
             ORDER BY id DESC
             LIMIT 50`,
            [userId]
          );
          rows = dbRows;
        } else {
          throw err;
        }
      }

      if (rows && rows.length > 0) {
        return res.json({
          requests: rows.map((r) => {
            let parsedDiagnosis = null;
            if (r.aiDiagnosis) {
              try {
                parsedDiagnosis = typeof r.aiDiagnosis === 'string' ? JSON.parse(r.aiDiagnosis) : r.aiDiagnosis;
              } catch (_) {}
            }
            return {
              id: r.id,
              userId: r.userId,
              requestText: r.requestText,
              language: r.language,
              status: r.status,
              aiDiagnosis: parsedDiagnosis,
              createdAt: r.createdAt,
            };
          }),
        });
      }

      // If DB had 0 rows for this user, check if we have persistent fallback items
      const userItems = inMemoryRequests
        .filter((r) => r.userId === userId)
        .slice(-50)
        .reverse();

      return res.json({ requests: userItems });
    } catch (dbErr) {
      console.warn('[Request Controller] DB unavailable (' + dbErr.message + '). Returning from persistent file store.');
      const userItems = inMemoryRequests
        .filter((r) => r.userId === userId)
        .slice(-50)
        .reverse();

      return res.json({ requests: userItems });
    }
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createRequest,
  listMyRequests,
};
