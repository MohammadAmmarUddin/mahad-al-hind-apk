import '../widgets/youtube_player_widget.dart' as yt;

/// Legacy wrapper — delegates to centralized youtube_player_widget functions.
class YouTubeUtils {
  static const String webUserAgent = yt.webUserAgent;
  static String? extractId(String? url) => yt.extractYoutubeId(url);
  static String? getEmbedUrl(String? url, {bool autoplay = false}) => yt.extractYoutubeId(url);
  static String? getThumbnail(String? url, {String quality = 'mqdefault'}) => yt.getYoutubeThumbnail(url, quality: quality);
  static bool isYouTube(String? url) => yt.isYouTubeUrl(url);
  static String normalizeUrl(String? url) => yt.extractYoutubeId(url) ?? url ?? '';
}
