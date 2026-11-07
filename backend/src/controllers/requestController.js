const pool = require('../db');

// In-memory fallback if MySQL service_requests table is not available
const inMemoryRequests = [];
let memoryReqId = 1;

// FR4: Accept service request typed in Bangla or English
// POST /api/requests
async function createRequest(req, res, next) {
  try {
    const userId = req.user.id;
    const requestText = req.body.requestText.trim();
    const language = req.body.language || 'bn';

    try {
      const [result] = await pool.execute(
        `INSERT INTO service_requests (user_id, request_text, language, status, created_at)
         VALUES (?, ?, ?, 'submitted', UTC_TIMESTAMP())`,
        [userId, requestText, language]
      );

      return res.status(201).json({
        message: 'Service request submitted successfully',
        request: {
          id: result.insertId,
          userId,
          requestText,
          language,
          status: 'submitted',
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
        status: 'submitted',
        createdAt: new Date().toISOString(),
      };
      inMemoryRequests.push(fallbackItem);

      return res.status(201).json({
        message: 'Service request submitted successfully',
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
        `SELECT id, user_id AS userId, request_text AS requestText, language, status, created_at AS createdAt
         FROM service_requests
         WHERE user_id = ?
         ORDER BY id DESC
         LIMIT 50`,
        [userId]
      );

      return res.json({
        requests: rows.map((r) => ({
          id: r.id,
          userId: r.userId,
          requestText: r.requestText,
          language: r.language,
          status: r.status,
          createdAt: r.createdAt,
        })),
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
