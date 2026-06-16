class AudioTrack {
  final String id;
  final String? title;
  final String? artist;
  final String? shayekhName;
  final String? shayekhId;
  final String? url;
  final String? coverUrl;
  final String? category;
  final Duration? duration;
  final bool isFavorite;
  final bool isDownloaded;
  final int? playCount;
  final String? createdAt;

  const AudioTrack({
    required this.id,
    this.title,
    this.artist,
    this.shayekhName,
    this.shayekhId,
    this.url,
    this.coverUrl,
    this.category,
    this.duration,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.playCount,
    this.createdAt,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      shayekhName: json['shayekhName'] as String?,
      shayekhId: json['shayekhId'] as String?,
      url: json['url'] as String?,
      coverUrl: json['coverUrl'] as String?,
      category: json['category'] as String?,
      duration: json['duration'] != null ? Duration(seconds: json['duration'] as int) : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      playCount: json['playCount'] as int?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
