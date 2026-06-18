# 🚀 Mahad Al Hind — App Update System

Complete production-ready app update system. Admin pastes an APK link + version → users automatically get update prompts.

## Architecture

```
Flutter App → Vercel API → Vercel KV (Redis) → Update Dialog in App
                                    ↑
                           Admin Panel (Web)
```

## 📁 Files Created / Modified

### Vercel Backend (Deploy to Vercel)
| File | Purpose |
|------|---------|
| `vercel.json` | Vercel deployment configuration |
| `package.json` | Node.js dependencies for Vercel functions |
| `api/_lib/store.js` | Vercel KV store helper (persistent storage) |
| `api/app/version.js` | **Public GET** — Flutter app calls this to check for updates |
| `api/admin/app-update.js` | **Admin PATCH/GET** — Protected endpoint for updating config |
| `admin/index.html` | **Web Admin Panel** — Beautiful single-page UI for managing updates |

### Flutter App (Modified)
| File | Changes |
|------|---------|
| `lib/core/services/update_service.dart` | Added `isUpdateAvailable()`, `isBelowMinVersion()`, `getCurrentVersion()` |
| `lib/core/services/update_provider.dart` | Existing — no changes needed |
| `lib/core/models/app_update_config.dart` | Existing — no changes needed |
| `lib/core/widgets/update_dialog.dart` | Existing — no changes needed |
| `lib/features/splash/presentation/pages/splash_page.dart` | Fixed force update flow (blocks app until updated) |

---

## 🛠 Deployment Steps

### Step 1: Set Up Vercel KV (Database)

1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select your project (or create a new one linked to this repo)
3. Go to **Storage** tab → Click **Create Database** → Select **KV** (Redis)
4. Choose a region close to your users (e.g., `iad1` for US, `hnd1` for Asia)
5. Click **Create** — Vercel auto-links the env vars (`KV_REST_API_URL`, `KV_REST_API_TOKEN`)

### Step 2: Set Admin API Key

1. In your Vercel project, go to **Settings** → **Environment Variables**
2. Add a new variable:
   - **Key**: `ADMIN_API_KEY`
   - **Value**: Choose a strong secret key (e.g., `my-super-secret-key-123`)
   - **Environments**: Check all (Production, Preview, Development)
3. Click **Save**

> ⚠️ **Important**: Save this key! You'll need it to access the admin panel.
> If you don't set this key, the admin panel works without authentication (dev mode only).

### Step 3: Deploy to Vercel

**Option A: Deploy via CLI**
```bash
# Install Vercel CLI (if not installed)
npm i -g vercel

# Deploy from project root
vercel --prod
```

**Option B: Deploy via Git**
1. Push all changes to your GitHub repo
2. In Vercel dashboard, click **Deployments** → **Deploy**
3. Vercel auto-detects the project and deploys

### Step 4: Verify Deployment

After deployment, test the API:

```bash
# Replace YOUR-VERCEL-URL with your actual Vercel URL
curl https://your-app.vercel.app/api/app/version

# Expected response:
{
  "latestVersion": "1.0.0",
  "minVersion": "1.0.0",
  "forceUpdate": false,
  "apkUrl": "",
  "releaseNotes": "",
  "updateEnabled": true,
  "updatedAt": null
}
```

### Step 5: Access Admin Panel

Open in browser: `https://your-app.vercel.app/admin`

1. Enter your `ADMIN_API_KEY` when prompted
2. Fill in the update details:
   - **Latest Version**: e.g., `1.2.0`
   - **Min Version**: e.g., `1.0.0` (users below this are forced to update)
   - **APK URL**: Paste your GitHub Release APK link
   - **Release Notes**: Write changes (one per line)
   - **Force Update**: Toggle ON/OFF
3. Click **Save & Publish Update**

---

## 📱 How It Works (User Flow)

1. **Admin** publishes an update via the web panel
2. **User** opens the Flutter app
3. App calls `GET /api/app/version` on the splash screen
4. App compares installed version with `latestVersion`
5. If update available:
   - **Optional**: Shows update dialog with "Later" button → user can skip
   - **Force**: Shows update dialog WITHOUT "Later" button → user **must** update
6. User taps **"Update Now"** → APK downloads from GitHub Release link
7. User installs the APK manually (sideload)

---

## 📋 API Reference

### Public: Check Version
```
GET /api/app/version

Response:
{
  "latestVersion": "1.2.0",
  "minVersion": "1.0.0",
  "forceUpdate": false,
  "apkUrl": "https://github.com/.../app-release.apk",
  "releaseNotes": "- Bug fixes\n- New features",
  "updateEnabled": true,
  "updatedAt": "2025-01-15T10:30:00.000Z"
}
```

### Admin: Update Config
```
PATCH /api/admin/app-update
Headers: { "X-Admin-Key": "YOUR_SECRET_KEY" }

Body:
{
  "latestVersion": "1.2.0",
  "minVersion": "1.0.0",
  "apkUrl": "https://github.com/.../app-release.apk",
  "releaseNotes": "Bug fixes and improvements",
  "forceUpdate": false,
  "updateEnabled": true
}

Response:
{
  "success": true,
  "data": { ...config }
}
```

### Admin: Get Current Config
```
GET /api/admin/app-update
Headers: { "X-Admin-Key": "YOUR_SECRET_KEY" }

Response:
{
  "success": true,
  "data": { ...config }
}
```

---

## 📦 GitHub Release APK Setup

1. Build your Flutter APK:
   ```bash
   flutter build apk --release
   ```
2. Go to your GitHub repo → **Releases** → **Create a new release**
3. Tag: `v1.2.0` (match your version)
4. Upload the APK: `build/app/outputs/flutter-apk/app-release.apk`
5. Add release notes
6. Publish the release
7. Copy the APK download URL and paste it in the admin panel

The APK URL format:
```
https://github.com/USERNAME/REPO/releases/download/v1.2.0/app-release.apk
```

---

## 🔒 Security Notes

- The `/api/app/version` endpoint is **public** (no auth needed) — this is by design so the Flutter app can check for updates
- The `/api/admin/app-update` endpoint is **protected** by the `ADMIN_API_KEY`
- Vercel KV data is encrypted at rest
- Consider rotating your admin key periodically

---

## 🧪 Local Development

```bash
# Install dependencies
npm install

# Run Vercel dev server
vercel dev

# The API will be available at http://localhost:3000
# Admin panel at http://localhost:3000/admin
```

> Without Vercel KV configured locally, the API uses an in-memory store (data resets on restart).

---

## 🔄 Flutter App Integration

The Flutter app is already fully integrated. Here's what happens:

1. **Splash Screen** (`splash_page.dart`) calls the API on app start
2. **UpdateService** (`update_service.dart`) handles version comparison
3. **UpdateDialog** (`update_dialog.dart`) shows a beautiful update prompt
4. **Force Update** blocks the app completely until user updates
5. **Admin Page** (`admin_app_update_page.dart`) provides in-app admin controls

### Version Comparison Logic
- Semantic versioning: `major.minor.patch` (e.g., `1.2.3`)
- `1.0.0` < `1.0.1` < `1.1.0` < `2.0.0`
- If current version < min version → **forced update** (regardless of forceUpdate toggle)