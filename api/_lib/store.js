/**
 * App Update Config Store
 * 
 * Uses Vercel KV (Redis) for persistent storage.
 * Falls back to in-memory storage for local development.
 * 
 * Environment Variables (auto-linked in Vercel):
 *   KV_REST_API_URL   - Vercel KV REST API URL
 *   KV_REST_API_TOKEN - Vercel KV REST API Token
 *   ADMIN_API_KEY     - Secret key for admin operations
 */

const STORAGE_KEY = 'mahad:app-update-config';

const DEFAULT_CONFIG = {
  latestVersion: '1.0.0',
  minVersion: '1.0.0',
  forceUpdate: false,
  apkUrl: '',
  releaseNotes: '',
  updateEnabled: true,
  updatedAt: null,
};

// In-memory fallback for local development
let memoryStore = { ...DEFAULT_CONFIG };

/**
 * Get the Vercel KV instance (if available)
 */
function getKV() {
  try {
    if (process.env.KV_REST_API_URL && process.env.KV_REST_API_TOKEN) {
      const { kv } = require('@vercel/kv');
      return kv;
    }
  } catch (e) {
    console.warn('Vercel KV not available, using in-memory store:', e.message);
  }
  return null;
}

/**
 * Get the current app update config
 */
async function getConfig() {
  const kv = getKV();

  if (kv) {
    try {
      const data = await kv.get(STORAGE_KEY);
      if (data) {
        return { ...DEFAULT_CONFIG, ...data };
      }
      // First time: initialize with defaults
      await kv.set(STORAGE_KEY, DEFAULT_CONFIG);
      return { ...DEFAULT_CONFIG };
    } catch (e) {
      console.error('KV read error:', e.message);
      return { ...memoryStore };
    }
  }

  // Fallback to in-memory
  return { ...memoryStore };
}

/**
 * Update the app update config
 */
async function updateConfig(updates) {
  const kv = getKV();
  const current = await getConfig();
  const newConfig = {
    ...current,
    ...updates,
    updatedAt: new Date().toISOString(),
  };

  if (kv) {
    try {
      await kv.set(STORAGE_KEY, newConfig);
      return newConfig;
    } catch (e) {
      console.error('KV write error:', e.message);
      throw new Error('Failed to save configuration');
    }
  }

  // Fallback to in-memory
  memoryStore = { ...newConfig };
  return newConfig;
}

/**
 * Validate admin API key
 */
function validateAdminKey(providedKey) {
  const expectedKey = process.env.ADMIN_API_KEY;
  if (!expectedKey) {
    // If no key is configured, allow access (development mode)
    console.warn('ADMIN_API_KEY not set — allowing access in development mode');
    return true;
  }
  return providedKey === expectedKey;
}

module.exports = {
  getConfig,
  updateConfig,
  validateAdminKey,
  DEFAULT_CONFIG,
};