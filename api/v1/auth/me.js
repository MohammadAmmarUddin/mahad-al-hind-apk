const connectDB = require('../../_lib/db/connect');
const User = require('../../_lib/auth/models/user');
const { verifyAccessToken } = require('../../_lib/auth/services/jwt');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ success: false, error: 'Method not allowed' });

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
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    if (user.isSuspended) {
      return res.status(403).json({ success: false, error: 'Account suspended' });
    }

    return res.status(200).json({ success: true, user });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Token expired' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, error: 'Invalid token' });
    }
    return res.status(500).json({ success: false, error: 'Failed to get user' });
  }
};
