class YouTubeUtils {
  /// Extract YouTube video ID from any YouTube URL format
  static String? extractId(String? url) {
    if (url == null || url.isEmpty) return null;
    url = url.trim();
    
    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
      RegExp(r'm\.youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }
    return null;
  }

  /// Get YouTube embed URL from any YouTube URL
  static String? getEmbedUrl(String? url, {bool autoplay = false}) {
    final id = extractId(url);
    if (id == null) return null;
    final params = autoplay ? 'autoplay=1&rel=0&modestbranding=1&playsinline=1' : 'autoplay=0&rel=0&modestbranding=1&playsinline=1';
    return 'https://www.youtube.com/embed/$id?$params';
  }

  /// Get YouTube thumbnail URL
  static String? getThumbnail(String? url, {String quality = 'mqdefault'}) {
    final id = extractId(url);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/$quality.jpg';
  }

  /// Check if a URL is a YouTube URL
  static bool isYouTube(String? url) {
    return extractId(url) != null;
  }

  /// Normalize any YouTube URL to embed format
  static String normalizeUrl(String? url) {
    return getEmbedUrl(url) ?? url ?? '';
  }
}
