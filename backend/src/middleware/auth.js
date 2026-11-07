const jwt = require('jsonwebtoken');
const config = require('../config');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  try {
    const payload = jwt.verify(token, config.jwt.secret, { algorithms: ['HS256'] });
    req.user = { id: payload.sub, role: payload.role };
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth };
