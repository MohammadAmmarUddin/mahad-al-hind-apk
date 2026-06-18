const connectDB = require('../../_lib/db/connect');
const User = require('../../_lib/auth/models/user');
const { verifyAccessToken } = require('../../_lib/auth/services/jwt');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });

  try {
    await connectDB();

    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(200).json({ success: true, message: 'Logged out' });
    }

    const token = header.split(' ')[1];
    try {
      const decoded = verifyAccessToken(token);
      const user = await User.findById(decoded.userId);
      if (user) {
        user.refreshTokens = [];
        user.refreshTokenVersion += 1;
        await user.save();
      }
    } catch (_) {
      // Token might be expired — still invalidate
      try {
        const jwt = require('jsonwebtoken');
        const decoded = jwt.decode(token);
        if (decoded && decoded.userId) {
          await User.findByIdAndUpdate(decoded.userId, {
            $inc: { refreshTokenVersion: 1 },
            $set: { refreshTokens: [] },
          });
        }
      } catch (_) {}
    }

    return res.status(200).json({ success: true, message: 'Logged out' });
  } catch (err) {
    return res.status(200).json({ success: true, message: 'Logged out' });
  }
};
