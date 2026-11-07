const pool = require('../db');
const { identifyServiceWithGemini } = require('../services/geminiService');

// In-memory fallback if MySQL service_requests table is not available
const inMemoryRequests = [];
let memoryReqId = 1;

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
      const [result] = await pool.execute(
        `INSERT INTO service_requests (user_id, request_text, language, status, ai_diagnosis, created_at)
         VALUES (?, ?, ?, 'processed', ?, UTC_TIMESTAMP())`,
        [userId, requestText, language, diagnosisJson]
      );

      return res.status(201).json({
        message: 'Service request submitted and analyzed successfully',
        request: {
          id: result.insertId,
          userId,
          requestText,
          language,
          status: 'processed',
          aiDiagnosis,
          createdAt: new Date().toISOString(),
        },
      });
    } catch (dbErr) {
      console.warn('[Request Controller] DB unavailable (' + dbErr.message + '). Storing in memory fallback.');
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
      const [rows] = await pool.execute(
        `SELECT id, user_id AS userId, request_text AS requestText, language, status, ai_diagnosis AS aiDiagnosis, created_at AS createdAt
         FROM service_requests
         WHERE user_id = ?
         ORDER BY id DESC
         LIMIT 50`,
        [userId]
      );

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
    } catch (dbErr) {
      console.warn('[Request Controller] DB unavailable (' + dbErr.message + '). Returning from memory.');
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
