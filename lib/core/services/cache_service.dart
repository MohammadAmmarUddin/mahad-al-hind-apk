import '../storage/hive_storage.dart';

class CacheService {
  Future<void> cacheData(String key, dynamic data, {Duration expiry = const Duration(hours: 1)}) async {
    await HiveStorage.cacheData(key, data, expiry: expiry);
  }

  dynamic getCachedData(String key) {
    return HiveStorage.getCachedData(key);
  }

  Future<void> clearCache() async {
    await HiveStorage.clearCache();
  }

  Future<bool> hasCache(String key) async {
    final data = getCachedData(key);
    return data != null;
  }
}
