const mysql = require('mysql2/promise');
const config = require('./config');

// All queries use prepared statements (pool.execute) -> no SQL injection.
const pool = mysql.createPool({
  ...config.db,
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4',
  timezone: 'Z',
  dateStrings: false,
});

module.exports = pool;
