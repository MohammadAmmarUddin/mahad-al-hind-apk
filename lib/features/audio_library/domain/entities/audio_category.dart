class AudioCategory {
  final String id;
  final String name;
  final String type;
  final String description;
  final String image;
  final String? parentId;
  final int order;
  final bool isVisible;
  final int audioCount;
  final int subCategoryCount;
  final List<AudioCategory> children;

  const AudioCategory({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.image = '',
    this.parentId,
    this.order = 0,
    this.isVisible = true,
    this.audioCount = 0,
    this.subCategoryCount = 0,
    this.children = const [],
  });

  factory AudioCategory.fromJson(Map<String, dynamic> json) {
    return AudioCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      order: json['order'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      audioCount: json['audioCount'] ?? 0,
      subCategoryCount: json['subCategoryCount'] ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => AudioCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
