const pool = require('../db');

// Escape LIKE wildcards so a user typing "%" or "_" searches for the literal character.
const escapeLike = (s) => s.replace(/[\\%_]/g, '\\$&');

// FR3: service catalog grouped by category, with search.
// GET /api/services            -> all active services
// GET /api/services?q=passport -> search in names and descriptions (Bangla or English)
async function listServices(req, res, next) {
  try {
    const q = String(req.query.q || '').trim().slice(0, 100);

    let sql = `
      SELECT s.id, s.name_bn, s.name_en, s.description_bn, s.description_en, s.is_priority,
             c.id AS category_id, c.name_bn AS category_name_bn, c.name_en AS category_name_en
      FROM services s
      JOIN service_categories c ON c.id = s.category_id
      WHERE s.status = 'active'`;
    const params = [];

    if (q) {
      sql += ` AND (s.name_bn LIKE ? OR s.name_en LIKE ?
                 OR s.description_bn LIKE ? OR s.description_en LIKE ?)`;
      const like = `%${escapeLike(q)}%`;
      params.push(like, like, like, like);
    }
    sql += ' ORDER BY c.id, s.is_priority DESC, s.id';

    const [rows] = await pool.execute(sql, params);
    return res.json({
      services: rows.map((r) => ({
        id: r.id,
        nameBn: r.name_bn,
        nameEn: r.name_en,
        descriptionBn: r.description_bn,
        descriptionEn: r.description_en,
        isPriority: !!r.is_priority,
        categoryId: r.category_id,
        categoryNameBn: r.category_name_bn,
        categoryNameEn: r.category_name_en,
      })),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listServices };
