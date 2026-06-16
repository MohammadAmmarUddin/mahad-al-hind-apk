import 'hive_storage.dart';

class HomeSectionToggles {
  static const String _key = 'home_section_toggles';

  static const Map<String, String> sectionLabels = {
    'hero_banner': 'Hero Banner',
    'news_feed': 'Hot News Feed',
    'stats': 'Statistics Counter',
    'featured_courses': 'Featured Courses',
    'videos': 'Video Library',
    'audio': 'Audio Preview',
    'testimonials': 'Testimonials',
    'gallery': 'Gallery Preview',
  };

  static Map<String, bool> _defaults() {
    return {for (var k in sectionLabels.keys) k: true};
  }

  static Map<String, bool> getAll() {
    final data = HiveStorage.getCachedData(_key);
    if (data is Map) {
      final map = Map<String, bool>.from(data);
      final defaults = _defaults();
      for (var key in defaults.keys) {
        map.putIfAbsent(key, () => true);
      }
      return map;
    }
    return _defaults();
  }

  static bool isEnabled(String section) {
    final all = getAll();
    return all[section] ?? true;
  }

  static Future<void> setEnabled(String section, bool enabled) async {
    final all = getAll();
    all[section] = enabled;
    await HiveStorage.cacheData(_key, all, expiry: const Duration(days: 3650));
  }

  static Future<void> resetAll() async {
    await HiveStorage.cacheData(_key, _defaults(), expiry: const Duration(days: 3650));
  }
}
