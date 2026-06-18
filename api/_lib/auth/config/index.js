module.exports = {
  google: {
    clientIds: (process.env.GOOGLE_CLIENT_IDS || '449725978000-eea576epbteq5e8um8nc11cm2742blce.apps.googleusercontent.com')
      .split(',')
      .map(id => id.trim())
      .filter(Boolean),
    issuer: 'https://accounts.google.com',
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES || '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES || '7d',
  },
  mongo: {
    uri: process.env.MONGODB_URI,
  },
  adminApiKey: process.env.ADMIN_API_KEY,
};
