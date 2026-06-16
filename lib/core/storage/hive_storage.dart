import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String _userBox = 'user_box';
  static const String _cacheBox = 'cache_box';
  static const String _settingsBox = 'settings_box';
  static const String _offlineBox = 'offline_box';
  static const String _audioQueueBox = 'audio_queue_box';
  static const String _newsBox = 'hot_news_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_offlineBox);
    await Hive.openBox(_audioQueueBox);
    await Hive.openBox(_newsBox);
  }

  // User Data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final box = Hive.box(_userBox);
    await box.put('current_user', user);
  }

  static Map<String, dynamic>? getUser() {
    final box = Hive.box(_userBox);
    final data = box.get('current_user');
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> clearUser() async {
    await Hive.box(_userBox).clear();
  }

  // Cache
  static Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    final box = Hive.box(_cacheBox);
    await box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    });
  }

  static dynamic getCachedData(String key) {
    final box = Hive.box(_cacheBox);
    final cached = box.get(key);
    if (cached == null) return null;

    final map = Map<String, dynamic>.from(cached);
    if (map['expiry'] != null) {
      final timestamp = map['timestamp'] as int;
      final expiry = map['expiry'] as int;
      if (DateTime.now().millisecondsSinceEpoch - timestamp > expiry) {
        box.delete(key);
        return null;
      }
    }
    return map['data'];
  }

  static Future<void> clearCache() async {
    await Hive.box(_cacheBox).clear();
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    await Hive.box(_settingsBox).put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return Hive.box(_settingsBox).get(key, defaultValue: defaultValue);
  }

  // Offline Data
  static Future<void> saveOfflineData(String key, dynamic data) async {
    await Hive.box(_offlineBox).put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static dynamic getOfflineData(String key) {
    final data = Hive.box(_offlineBox).get(key);
    if (data != null) {
      return Map<String, dynamic>.from(data)['data'];
    }
    return null;
  }

  // Audio Queue
  static Future<void> saveAudioQueue(List<Map<String, dynamic>> queue) async {
    await Hive.box(_audioQueueBox).put('queue', queue);
  }

  static List<Map<String, dynamic>> getAudioQueue() {
    final data = Hive.box(_audioQueueBox).get('queue');
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  static Future<void> clearAll() async {
    await Hive.box(_userBox).clear();
    await Hive.box(_cacheBox).clear();
    await Hive.box(_settingsBox).clear();
    await Hive.box(_offlineBox).clear();
    await Hive.box(_audioQueueBox).clear();
  }
}
