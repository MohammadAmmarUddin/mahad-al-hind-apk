import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../models/app_update_config.dart';

class UpdateService {
  final DioClient _dio;
  UpdateService(this._dio);

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
    } catch (_) {
      return null;
    }
  }

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
