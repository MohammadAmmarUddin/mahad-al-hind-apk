class CourseCategory {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final int? courseCount;

  const CourseCategory({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.courseCount,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description'] as String?,
      image: json['image'] as String?,
      courseCount: json['courseCount'] as int?,
    );
  }
}
