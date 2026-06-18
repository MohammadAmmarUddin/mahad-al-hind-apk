/**
 * GET /api/app/version
 * 
 * Public endpoint — returns the current app update config.
 * Used by the Flutter app to check for updates.
 * 
 * Response:
 * {
 *   "latestVersion": "1.0.0",
 *   "minVersion": "1.0.0",
 *   "forceUpdate": false,
 *   "apkUrl": "https://github.com/...",
 *   "releaseNotes": "Bug fixes",
 *   "updateEnabled": true,
 *   "updatedAt": "2025-01-01T00:00:00.000Z"
 * }
 */

const { getConfig } = require('../_lib/store');

module.exports = async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const config = await getConfig();
    return res.status(200).json(config);
  } catch (error) {
    console.error('Error fetching version:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};