class NotificationItem {
  final String id;
  final String? title;
  final String? body;
  final String? type;
  final bool? isRead;
  final String? createdAt;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    this.title,
    this.body,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String?,
      body: json['body'] as String?,
      type: json['type'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
