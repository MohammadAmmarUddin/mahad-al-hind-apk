const config = require('../config');

async function verifyGoogleAccessToken(accessToken) {
  const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error('Invalid Google access token');
  }

  const payload = await response.json();

  if (!payload.email) {
    throw new Error('Email not available from Google');
  }

  return {
    googleId: payload.sub,
    email: payload.email,
    name: payload.name || '',
    picture: payload.picture || '',
    emailVerified: payload.email_verified || false,
  };
}

module.exports = { verifyGoogleAccessToken };
