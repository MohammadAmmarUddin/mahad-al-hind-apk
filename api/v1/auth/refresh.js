const connectDB = require('../../_lib/db/connect');
const User = require('../../_lib/auth/models/user');
const { verifyRefreshToken, generateAccessToken, generateRefreshToken } = require('../../_lib/auth/services/jwt');
const { validateRefresh } = require('../../_lib/auth/middleware/validate');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });

  try {
    await connectDB();

    const errors = validateRefresh(req.body || {});
    if (errors.length > 0) {
      return res.status(400).json({ success: false, error: errors.join(', ') });
    }

    const { refreshToken } = req.body;

    const decoded = verifyRefreshToken(refreshToken);

    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ success: false, error: 'User not found' });
    }

    if (decoded.version !== user.refreshTokenVersion) {
      return res.status(401).json({ success: false, error: 'Token revoked' });
    }

    const storedToken = user.refreshTokens.find(t => t.token === refreshToken);
    if (!storedToken) {
      user.refreshTokens = [];
      await user.save();
      return res.status(401).json({ success: false, error: 'Invalid refresh token' });
    }

    if (new Date(storedToken.expiresAt) < new Date()) {
      user.refreshTokens = user.refreshTokens.filter(t => t.token !== refreshToken);
      await user.save();
      return res.status(401).json({ success: false, error: 'Refresh token expired' });
    }

    user.refreshTokens = user.refreshTokens.filter(t => t.token !== refreshToken);

    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);

    const expiry = new Date();
    expiry.setDate(expiry.getDate() + 7);
    user.refreshTokens.push({
      token: newRefreshToken,
      expiresAt: expiry,
      userAgent: req.headers['user-agent'] || '',
    });

    if (user.refreshTokens.length > 5) {
      user.refreshTokens = user.refreshTokens.slice(-5);
    }
    await user.save();

    return res.status(200).json({
      success: true,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (err) {
    if (err.name === 'TokenExpiredError' || err.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, error: 'Invalid refresh token' });
    }
    return res.status(500).json({ success: false, error: 'Token refresh failed' });
  }
};
