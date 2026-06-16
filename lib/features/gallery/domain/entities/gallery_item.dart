class GalleryItem {
  final String id;
  final String? title;
  final String? url;
  final String? description;
  final String? type;
  final DateTime? createdAt;

  const GalleryItem({
    required this.id,
    this.title,
    this.url,
    this.description,
    this.type,
    this.createdAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String?,
      url: json['url'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
