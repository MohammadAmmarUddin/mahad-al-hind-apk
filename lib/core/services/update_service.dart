import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../models/app_update_config.dart';

class UpdateService {
  final DioClient _dio;
  UpdateService(this._dio);

  // ─── SharedPreferences Keys ───
  static const String _lastCheckKey = 'update_last_check_time';
  static const String _lastInstalledVersionKey = 'update_last_installed_version';
  static const String _lastDismissedVersionKey = 'update_last_dismissed_version';
  static const String _updateCompletedAtKey = 'update_completed_at';
  static const String _lastNotifiedVersionKey = 'update_last_notified_version';
  static const Duration _checkInterval = Duration(hours: 4);

  // ─────────────────────────────────────────────────────
  // FETCH CONFIG
  // ─────────────────────────────────────────────────────

  /// Fetches the latest update config from the server.
  Future<AppUpdateConfig?> checkForUpdate() async {
    try {
      final response = await _dio.get(ApiEndpoints.appVersion);
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return AppUpdateConfig.fromJson(Map<String, dynamic>.from(data['data']));
      }
      if (data is Map && data['latestVersion'] != null) {
        return AppUpdateConfig.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('[UpdateService] checkForUpdate error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  // SMART CHECK INTERVAL
  // ─────────────────────────────────────────────────────

  /// Checks if enough time has passed since the last check.
  Future<bool> shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastCheck) >= _checkInterval.inMilliseconds;
  }

  /// Records that a check was just performed.
  Future<void> recordCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ─────────────────────────────────────────────────────
  // POST-UPDATE STATE MANAGEMENT
  // ─────────────────────────────────────────────────────

  /// Returns the current installed app version string (e.g. "1.2.0").
  /// Strips the build number suffix (e.g. "1.2.0+1" → "1.2.0").
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;
    if (version.contains('+')) {
      return version.split('+').first;
    }
    return version;
  }

  /// Detects if this is a post-update launch.
  /// Returns true if the current installed version differs from the last recorded version.
  Future<bool> isPostUpdateLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final lastInstalled = prefs.getString(_lastInstalledVersionKey) ?? '';
    final currentVersion = await getCurrentVersion();

    // If we have a stored version and it's different from current, this is post-update
    if (lastInstalled.isNotEmpty && lastInstalled != currentVersion) {
      return true;
    }
    // If no stored version at all, this is first install (not post-update)
    return false;
  }

  /// Records the current version as installed and clears all update state.
  /// Called after detecting a successful update.
  static Future<void> recordUpdateCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await getCurrentVersion();

    await prefs.setString(_lastInstalledVersionKey, currentVersion);
    await prefs.setInt(_updateCompletedAtKey, DateTime.now().millisecondsSinceEpoch);

    // Clear all update flags so same version never triggers popup again
    await prefs.remove(_lastDismissedVersionKey);
    await prefs.remove(_lastNotifiedVersionKey);
    // Reset check timer so next launch checks fresh
    await prefs.setInt(_lastCheckKey, 0);

    print('[UpdateService] Update completed for v$currentVersion — all flags cleared');
  }

  /// Records the current installed version without clearing flags.
  /// Used on every normal launch to track what version is running.
  static Future<void> recordCurrentVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastInstalledVersionKey, version);
  }

  /// Detects if this is a post-update launch.
  /// Returns true if the current installed version differs from the last recorded version.
  static Future<bool> isPostUpdateLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final lastInstalled = prefs.getString(_lastInstalledVersionKey) ?? '';
    final currentVersion = await getCurrentVersion();

    // If we have a stored version and it's different from current, this is post-update
    if (lastInstalled.isNotEmpty && lastInstalled != currentVersion) {
      return true;
    }
    return false;
  }

  /// Records that the user dismissed (not updated) a specific version.
  static Future<void> recordDismissedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDismissedVersionKey, version);
  }

  /// Returns the version the user last dismissed.
  static Future<String?> getLastDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDismissedVersionKey);
  }

  /// Records that we notified the user about a specific version.
  static Future<void> recordNotifiedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifiedVersionKey, version);
  }

  /// Checks if we already notified the user about this exact version.
  static Future<bool> alreadyNotifiedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotifiedVersionKey) == version;
  }

  /// Records the current installed version without clearing flags.
  /// Used on every normal launch to track what version is running.
  Future<void> recordCurrentVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastInstalledVersionKey, version);
  }

  /// Records that the user dismissed (not updated) a specific version.
  Future<void> recordDismissedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDismissedVersionKey, version);
  }

  /// Returns the version the user last dismissed.
  Future<String?> getLastDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDismissedVersionKey);
  }

  /// Records that we notified the user about a specific version.
  Future<void> recordNotifiedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifiedVersionKey, version);
  }

  /// Checks if we already notified the user about this exact version.
  Future<bool> alreadyNotifiedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotifiedVersionKey) == version;
  }

  /// Gets the timestamp when the last update was completed.
  Future<DateTime?> getUpdateCompletedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_updateCompletedAtKey);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  /// Clears the last installed version record (for testing/reset).
  Future<void> clearInstalledVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastInstalledVersionKey);
    await prefs.remove(_updateCompletedAtKey);
  }

  // ─────────────────────────────────────────────────────
  // VERSION COMPARISON
  // ─────────────────────────────────────────────────────

  /// Checks if an update is available (current < latest).
  static bool isUpdateAvailable(String currentVersion, AppUpdateConfig config) {
    if (!config.updateEnabled) return false;
    if (config.latestVersion.isEmpty) return false;
    return compareVersions(currentVersion, config.latestVersion) < 0;
  }

  /// Checks if the current version is below the minimum required version.
  static bool isBelowMinVersion(String currentVersion, AppUpdateConfig config) {
    if (config.minVersion.isEmpty) return false;
    return compareVersions(currentVersion, config.minVersion) < 0;
  }

  /// Checks if current version matches or exceeds the latest (up to date).
  static bool isUpToDate(String currentVersion, AppUpdateConfig config) {
    if (config.latestVersion.isEmpty) return true;
    return compareVersions(currentVersion, config.latestVersion) >= 0;
  }

  /// Semantic version comparison.
  /// Returns -1 if current < target, 0 if equal, 1 if current > target.
  static int compareVersions(String current, String target) {
    final cParts = current.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final tParts = target.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final len = cParts.length > tParts.length ? cParts.length : tParts.length;
    for (var i = 0; i < len; i++) {
      final c = i < cParts.length ? cParts[i] : 0;
      final t = i < tParts.length ? tParts[i] : 0;
      if (c < t) return -1;
      if (c > t) return 1;
    }
    return 0;
  }
}
