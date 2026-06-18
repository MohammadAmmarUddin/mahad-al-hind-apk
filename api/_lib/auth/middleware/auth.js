const { verifyAccessToken } = require('../services/jwt');
const User = require('../models/user');
const connectDB = require('../../db/connect');

async function authMiddleware(req, res, next) {
  try {
    await connectDB();

    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'No token provided' });
    }

    const token = header.split(' ')[1];
    const decoded = verifyAccessToken(token);

    const user = await User.findById(decoded.userId).select('-refreshTokens -__v');
    if (!user) {
      return res.status(401).json({ success: false, error: 'User not found' });
    }

    if (user.isSuspended) {
      return res.status(403).json({ success: false, error: 'Account suspended' });
    }

    if (decoded.version !== user.refreshTokenVersion) {
      return res.status(401).json({ success: false, error: 'Token revoked' });
    }

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Token expired' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, error: 'Invalid token' });
    }
    return res.status(500).json({ success: false, error: 'Auth error' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Insufficient permissions' });
    }
    next();
  };
}

module.exports = { authMiddleware, requireRole };
