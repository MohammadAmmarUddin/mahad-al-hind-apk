import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';
import '../models/app_update_config.dart';
import '../services/update_service.dart';
import '../../shared/providers/core_providers.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.read(dioClientProvider));
});

final checkUpdateProvider = FutureProvider<AppUpdateConfig?>((ref) async {
  return ref.read(updateServiceProvider).checkForUpdate();
});

final currentVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final adminUpdateConfigProvider = FutureProvider<AppUpdateConfig?>((ref) async {
  try {
    final dio = ref.read(dioClientProvider);
    final res = await dio.get(ApiEndpoints.appVersion);
    final data = res.data;
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
});
