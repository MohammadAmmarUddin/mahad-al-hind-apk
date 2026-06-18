/**
 * PATCH /api/admin/app-update  — Update the app version config
 * GET  /api/admin/app-update  — Get current config (admin view)
 * 
 * Protected endpoint — requires X-Admin-Key header.
 * 
 * PATCH Body:
 * {
 *   "latestVersion": "1.2.0",
 *   "minVersion": "1.0.0",
 *   "forceUpdate": false,
 *   "apkUrl": "https://github.com/.../releases/download/v1.2.0/app-release.apk",
 *   "releaseNotes": "New features and improvements",
 *   "updateEnabled": true
 * }
 */

const { getConfig, updateConfig, validateAdminKey } = require('../_lib/store');

module.exports = async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Admin-Key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Authenticate
  const adminKey = req.headers['x-admin-key'];
  if (!validateAdminKey(adminKey)) {
    return res.status(401).json({ error: 'Unauthorized — invalid or missing admin key' });
  }

  try {
    if (req.method === 'GET') {
      const config = await getConfig();
      return res.status(200).json({ success: true, data: config });
    }

    if (req.method === 'PATCH') {
      const {
        latestVersion,
        minVersion,
        forceUpdate,
        apkUrl,
        releaseNotes,
        updateEnabled,
      } = req.body || {};

      // Validate required fields
      if (!latestVersion || latestVersion.trim() === '') {
        return res.status(400).json({ error: 'latestVersion is required' });
      }
      if (!apkUrl || apkUrl.trim() === '') {
        return res.status(400).json({ error: 'apkUrl is required' });
      }

      const updates = {};
      if (latestVersion !== undefined) updates.latestVersion = latestVersion.trim();
      if (minVersion !== undefined) updates.minVersion = minVersion.trim();
      if (forceUpdate !== undefined) updates.forceUpdate = !!forceUpdate;
      if (apkUrl !== undefined) updates.apkUrl = apkUrl.trim();
      if (releaseNotes !== undefined) updates.releaseNotes = releaseNotes.trim();
      if (updateEnabled !== undefined) updates.updateEnabled = !!updateEnabled;

      const newConfig = await updateConfig(updates);
      return res.status(200).json({ success: true, data: newConfig });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Admin app-update error:', error);
    return res.status(500).json({ error: error.message || 'Internal server error' });
  }
};