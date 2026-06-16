class Video {
  final String id;
  final String? title;
  final String? tag;
  final String? desc;
  final String? embedUrl;

  const Video({
    required this.id,
    this.title,
    this.tag,
    this.desc,
    this.embedUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String?,
      tag: json['tag'] as String?,
      desc: json['desc'] as String?,
      embedUrl: json['embedUrl'] as String?,
    );
  }
}
