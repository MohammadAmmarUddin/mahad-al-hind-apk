import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../storage/hive_storage.dart';
import '../../shared/providers/core_providers.dart';

class FeatureFlags {
  Map<String, bool> _flags = {};

  Map<String, bool> get flags => Map.unmodifiable(_flags);

  // Default flags (all enabled)
  static const Map<String, bool> _defaultFlags = {
    'courses': true,
    'audioLibrary': true,
    'videoLibrary': true,
    'attendance': true,
    'feeManagement': true,
    'gallery': true,
    'certificates': true,
    'aiAssistant': false,
    'notifications': true,
    'reviews': true,
    'shayekh': true,
    'studentManagement': true,
    'enrollment': true,
    'dashboard': true,
    'liveClasses': false,
    'offlineMode': true,
  };

  bool isEnabled(String flag) {
    return _flags[flag] ?? _defaultFlags[flag] ?? false;
  }

  Future<void> fetchFlags(DioClient dioClient) async {
    try {
      final response = await dioClient.get(ApiEndpoints.siteSettings);
      final data = response.data['data'];
      if (data != null && data is Map) {
        final featureFlags = data['featureFlags'];
        if (featureFlags != null && featureFlags is Map) {
          _flags = Map<String, bool>.from(featureFlags.map((k, v) => MapEntry(k.toString(), v == true)));
        }
      }
      // Cache flags
      await HiveStorage.cacheData('feature_flags', _flags, expiry: const Duration(hours: 6));
    } catch (_) {
      // Load from cache
      final cached = HiveStorage.getCachedData('feature_flags');
      if (cached != null) {
        _flags = Map<String, bool>.from(cached.map((k, v) => MapEntry(k.toString(), v == true)));
      } else {
        _flags = Map.from(_defaultFlags);
      }
    }
  }

  void setFlag(String key, bool value) {
    _flags[key] = value;
  }
}

final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, FeatureFlags>((ref) {
  return FeatureFlagsNotifier(ref);
});

class FeatureFlagsNotifier extends StateNotifier<FeatureFlags> {
  final Ref ref;
  FeatureFlagsNotifier(this.ref) : super(FeatureFlags()) {
    _init();
  }

  Future<void> _init() async {
    final dioClient = ref.read(dioClientProvider);
    await state.fetchFlags(dioClient);
    state = state;
  }

  bool isEnabled(String flag) => state.isEnabled(flag);

  Future<void> refresh() async {
    final dioClient = ref.read(dioClientProvider);
    await state.fetchFlags(dioClient);
    state = state;
  }
}
