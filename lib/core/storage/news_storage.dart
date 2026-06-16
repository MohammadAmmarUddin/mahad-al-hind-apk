import 'package:hive_flutter/hive_flutter.dart';

class NewsStorage {
  static const String _boxName = 'hot_news_box';
  static const String _key = 'news_items';

  static List<Map<String, dynamic>> getAll() {
    final box = Hive.box(_boxName);
    final data = box.get(_key);
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> saveAll(List<Map<String, dynamic>> items) async {
    final box = Hive.box(_boxName);
    await box.put(_key, items);
  }

  static Future<void> addItem(Map<String, dynamic> item) async {
    final items = getAll();
    item['_id'] = DateTime.now().millisecondsSinceEpoch.toString();
    item['createdAt'] = DateTime.now().toIso8601String();
    items.add(item);
    await saveAll(items);
  }

  static Future<void> updateItem(String id, Map<String, dynamic> updated) async {
    final items = getAll();
    final index = items.indexWhere((e) => e['_id'] == id);
    if (index != -1) {
      items[index] = {...items[index], ...updated, 'updatedAt': DateTime.now().toIso8601String()};
      await saveAll(items);
    }
  }

  static Future<void> deleteItem(String id) async {
    final items = getAll();
    items.removeWhere((e) => e['_id'] == id);
    await saveAll(items);
  }

  static Future<void> reorderItems(List<Map<String, dynamic>> items) async {
    await saveAll(items);
  }
}
