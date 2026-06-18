const connectDB = require('../../_lib/db/connect');
const User = require('../../_lib/auth/models/user');
const { verifyGoogleAccessToken } = require('../../_lib/auth/services/google');
const { generateAccessToken, generateRefreshToken } = require('../../_lib/auth/services/jwt');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });

  try {
    await connectDB();

    const { accessToken } = req.body || {};
    if (!accessToken) {
      return res.status(400).json({ success: false, error: 'accessToken is required' });
    }

    const googleUser = await verifyGoogleAccessToken(accessToken);

    if (!googleUser.email) {
      return res.status(400).json({ success: false, error: 'Email not available from Google' });
    }

    let user = await User.findOne({ email: googleUser.email.toLowerCase() });

    if (user) {
      user.name = googleUser.name || user.name;
      user.avatar = googleUser.picture || user.avatar;
      user.emailVerified = googleUser.emailVerified || user.emailVerified;
      user.googleId = googleUser.googleId || user.googleId;
      user.lastLoginAt = new Date();
      await user.save();
    } else {
      user = await User.create({
        name: googleUser.name || 'Google User',
        email: googleUser.email.toLowerCase(),
        googleId: googleUser.googleId,
        avatar: googleUser.picture,
        provider: 'google',
        emailVerified: googleUser.emailVerified,
        lastLoginAt: new Date(),
      });
    }

    const jwtAccessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    const refreshTokenExpiry = new Date();
    refreshTokenExpiry.setDate(refreshTokenExpiry.getDate() + 7);

    user.refreshTokens.push({
      token: refreshToken,
      expiresAt: refreshTokenExpiry,
      userAgent: req.headers['user-agent'] || '',
    });

    if (user.refreshTokens.length > 5) {
      user.refreshTokens = user.refreshTokens.slice(-5);
    }
    await user.save();

    return res.status(200).json({
      success: true,
      accessToken: jwtAccessToken,
      refreshToken,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        role: user.role,
        provider: user.provider,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    console.error('Google auth error:', err.message);
    return res.status(500).json({ success: false, error: 'Authentication failed' });
  }
};
