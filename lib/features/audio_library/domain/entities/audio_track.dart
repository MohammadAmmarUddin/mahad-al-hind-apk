class AudioTrack {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String thumbnail;
  final String categoryId;
  final int duration;
  final String reciter;
  final int order;
  final int playCount;
  final bool isVisible;
  final String? createdAt;

  const AudioTrack({
    required this.id,
    required this.title,
    this.description = '',
    required this.audioUrl,
    this.thumbnail = '',
    required this.categoryId,
    this.duration = 0,
    this.reciter = '',
    this.order = 0,
    this.playCount = 0,
    this.isVisible = true,
    this.createdAt,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      duration: json['duration'] ?? 0,
      reciter: json['reciter']?.toString() ?? '',
      order: json['order'] ?? 0,
      playCount: json['playCount'] ?? 0,
      isVisible: json['isVisible'] ?? true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'thumbnail': thumbnail,
      'categoryId': categoryId,
      'duration': duration,
      'reciter': reciter,
      'order': order,
      'playCount': playCount,
      'isVisible': isVisible,
      'createdAt': createdAt,
    };
  }

  String get formattedDuration {
    if (duration <= 0) return '0:00';
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
