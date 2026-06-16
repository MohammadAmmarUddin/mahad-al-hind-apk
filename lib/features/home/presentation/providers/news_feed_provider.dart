import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/news_storage.dart';

class NewsItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? courseId;
  final String type;
  final bool enabled;
  final DateTime? createdAt;

  const NewsItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.courseId,
    this.type = 'info',
    this.enabled = true,
    this.createdAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['message'] ?? json['text'] ?? '',
      subtitle: json['subtitle'] ?? json['description'],
      courseId: json['courseId'] ?? json['course'],
      type: json['type'] ?? 'info',
      enabled: json['enabled'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'subtitle': subtitle,
    'courseId': courseId,
    'type': type,
    'enabled': enabled,
    'createdAt': createdAt?.toIso8601String(),
  };
}

final newsFeedProvider = FutureProvider<List<NewsItem>>((ref) async {
  final items = NewsStorage.getAll();
  return items
      .map((e) => NewsItem.fromJson(e))
      .where((n) => n.enabled)
      .toList();
});
