const pool = require('../db');

// Escape LIKE wildcards so a user typing "%" or "_" searches for the literal character.
const escapeLike = (s) => s.replace(/[\\%_]/g, '\\$&');

// Predefined service catalog (mirrors database/services.sql)
const FALLBACK_SERVICES = [
  {
    id: 1,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'জন্ম নিবন্ধন',
    nameEn: 'Birth Registration',
    descriptionBn: 'নতুন জন্ম নিবন্ধন করা বা জন্ম নিবন্ধন সনদ সংশোধন করা।',
    descriptionEn: 'Register a new birth or correct a birth registration certificate.',
    isPriority: true,
  },
  {
    id: 2,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'এনআইডি তথ্য সংশোধন',
    nameEn: 'NID Correction',
    descriptionBn: 'জাতীয় পরিচয়পত্রের নাম, ঠিকানা বা অন্য তথ্য সংশোধন করা।',
    descriptionEn: 'Correct the name, address or other details on a National ID card.',
    isPriority: true,
  },
  {
    id: 3,
    categoryId: 2,
    categoryNameBn: 'ভ্রমণ ও যানবাহন',
    categoryNameEn: 'Travel & Transport',
    nameBn: 'পাসপোর্ট সেবা',
    nameEn: 'Passport Services',
    descriptionBn: 'নতুন পাসপোর্টের আবেদন, নবায়ন বা তথ্য সংশোধন।',
    descriptionEn: 'Apply for a new passport, renew it, or correct its details.',
    isPriority: true,
  },
  {
    id: 4,
    categoryId: 3,
    categoryNameBn: 'ভূমি সেবা',
    categoryNameEn: 'Land Services',
    nameBn: 'ই-নামজারি',
    nameEn: 'e-Mutation',
    descriptionBn: 'জমির মালিকানা পরিবর্তনের পর অনলাইনে নামজারির আবেদন।',
    descriptionEn: 'Apply online for land mutation after a change of ownership.',
    isPriority: true,
  },
  {
    id: 5,
    categoryId: 4,
    categoryNameBn: 'ব্যবসা',
    categoryNameEn: 'Business',
    nameBn: 'ট্রেড লাইসেন্স',
    nameEn: 'Trade License',
    descriptionBn: 'ব্যবসা চালানোর জন্য নতুন ট্রেড লাইসেন্স বা নবায়ন।',
    descriptionEn: 'Get a new trade license or renew one to run a business.',
    isPriority: true,
  },
  {
    id: 6,
    categoryId: 1,
    categoryNameBn: 'পরিচয় ও নিবন্ধন',
    categoryNameEn: 'Identity & Registration',
    nameBn: 'মৃত্যু নিবন্ধন',
    nameEn: 'Death Registration',
    descriptionBn: 'মৃত্যুর ঘটনা নিবন্ধন করা ও মৃত্যু সনদ সংগ্রহ।',
    descriptionEn: 'Register a death and obtain a death certificate.',
    isPriority: false,
  },
  {
    id: 7,
    categoryId: 2,
    categoryNameBn: 'ভ্রমণ ও যানবাহন',
    categoryNameEn: 'Travel & Transport',
    nameBn: 'ড্রাইভিং লাইসেন্স',
    nameEn: 'Driving License',
    descriptionBn: 'নতুন ড্রাইভিং লাইসেন্স বা নবায়নের আবেদন।',
    descriptionEn: 'Apply for a new driving license or renewal.',
    isPriority: false,
  },
  {
    id: 8,
    categoryId: 4,
    categoryNameBn: 'ব্যবসা',
    categoryNameEn: 'Business',
    nameBn: 'টিআইএন নিবন্ধন',
    nameEn: 'TIN Registration',
    descriptionBn: 'কর শনাক্তকরণ নম্বর (TIN) পাওয়ার জন্য নিবন্ধন।',
    descriptionEn: 'Register to get a Taxpayer Identification Number (TIN).',
    isPriority: false,
  },
];

function filterFallback(q) {
  if (!q) return FALLBACK_SERVICES;
  const lower = q.toLowerCase();
  return FALLBACK_SERVICES.filter(
    (s) =>
      s.nameBn.includes(q) ||
      s.nameEn.toLowerCase().includes(lower) ||
      s.descriptionBn.includes(q) ||
      s.descriptionEn.toLowerCase().includes(lower)
  );
}

// FR3: service catalog grouped by category, with search.
// GET /api/services            -> all active services
// GET /api/services?q=passport -> search in names and descriptions (Bangla or English)
async function listServices(req, res, next) {
  const q = String(req.query.q || '').trim().slice(0, 100);
  try {
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
    if (err.code === 'ER_NO_SUCH_TABLE') {
      console.warn('[Service Catalog] MySQL tables not found. Serving built-in default catalog.');
      return res.json({ services: filterFallback(q) });
    }
    return next(err);
  }
}

module.exports = { listServices };
