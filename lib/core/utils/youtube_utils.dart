class YouTubeUtils {
  static const String webUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

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

  static String? getEmbedUrl(String? url, {bool autoplay = false}) {
    final id = extractId(url);
    if (id == null) return null;
    final ap = autoplay ? '1' : '0';
    return 'https://www.youtube.com/embed/$id?autoplay=$ap&rel=0&modestbranding=1&playsinline=1&enablejsapi=1';
  }

  static String? getThumbnail(String? url, {String quality = 'mqdefault'}) {
    final id = extractId(url);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/$quality.jpg';
  }

  static bool isYouTube(String? url) {
    return extractId(url) != null;
  }

  static String normalizeUrl(String? url) {
    return getEmbedUrl(url) ?? url ?? '';
  }
}
