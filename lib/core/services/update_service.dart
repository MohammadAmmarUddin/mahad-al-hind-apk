import 'package:package_info_plus/package_info_plus.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../models/app_update_config.dart';

class UpdateService {
  final DioClient _dio;
  UpdateService(this._dio);

  /// Fetches the latest update config from the server.
  Future<AppUpdateConfig?> checkForUpdate() async {
    try {
      final response = await _dio.get(ApiEndpoints.appVersion);
      final data = response.data;
      print('[UpdateService] Response: $data');
      // Handle wrapped response: { data: { ... } }
      if (data is Map && data['data'] is Map) {
        return AppUpdateConfig.fromJson(Map<String, dynamic>.from(data['data']));
      }
      // Handle flat response: { latestVersion: ..., ... }
      if (data is Map && data['latestVersion'] != null) {
        return AppUpdateConfig.fromJson(Map<String, dynamic>.from(data));
      }
      print('[UpdateService] Unexpected response format: $data');
      return null;
    } catch (e) {
      print('[UpdateService] checkForUpdate error: $e');
      return null;
    }
  }

  /// Returns the current installed app version string (e.g. "1.0.0").
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Checks if an update is available (current < latest).
  static bool isUpdateAvailable(String currentVersion, AppUpdateConfig config) {
    if (!config.updateEnabled) return false;
    if (config.latestVersion.isEmpty) return false;
    return compareVersions(currentVersion, config.latestVersion) < 0;
  }

  /// Checks if the current version is below the minimum required version.
  /// If true, the app must be force-updated (user cannot proceed).
  static bool isBelowMinVersion(String currentVersion, AppUpdateConfig config) {
    if (config.minVersion.isEmpty) return false;
    return compareVersions(currentVersion, config.minVersion) < 0;
  }

  /// Semantic version comparison.
  /// Returns -1 if current < target, 0 if equal, 1 if current > target.
  static int compareVersions(String current, String target) {
    final cParts = current.split('.').map(int.tryParse).toList();
    final tParts = target.split('.').map(int.tryParse).toList();
    final len = cParts.length > tParts.length ? cParts.length : tParts.length;
    for (var i = 0; i < len; i++) {
      final c = i < cParts.length ? (cParts[i] ?? 0) : 0;
      final t = i < tParts.length ? (tParts[i] ?? 0) : 0;
      if (c < t) return -1;
      if (c > t) return 1;
    }
    return 0;
  }
}
