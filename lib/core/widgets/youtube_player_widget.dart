import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../constants/app_colors.dart';

const String webUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

/// Extracts a YouTube video ID from any YouTube URL format.
String? extractYoutubeId(String? url) {
  if (url == null || url.isEmpty) return null;
  return YoutubePlayerController.convertUrlToId(url.trim());
}

/// Returns true if the URL is a YouTube link.
bool isYouTubeUrl(String? url) => extractYoutubeId(url) != null;

/// Returns a thumbnail URL for a YouTube video.
String? getYoutubeThumbnail(String? url, {String quality = 'mqdefault'}) {
  final id = extractYoutubeId(url);
  if (id == null) return null;
  return 'https://img.youtube.com/vi/$id/$quality.jpg';
}

/// A reusable inline YouTube player widget with built-in controls.
/// Handles fullscreen automatically via vertical swipe.
class YoutubePlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const YoutubePlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  YoutubePlayerController? _controller;
  bool _hasError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant YoutubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.close();
      _controller = null;
      _hasError = false;
      _errorMsg = null;
      _initPlayer();
    }
  }

  void _initPlayer() {
    final id = extractYoutubeId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      _hasError = true;
      _errorMsg = 'Invalid YouTube URL';
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: const Color(0xFF0F172A),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                Text(_errorMsg ?? 'Unable to load video',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      aspectRatio: 16 / 9,
      autoFullScreen: true,
    );
  }
}

/// A tappable thumbnail card for YouTube videos.
class YoutubeThumbnailCard extends StatelessWidget {
  final String videoUrl;
  final String? title;
  final VoidCallback? onTap;

  const YoutubeThumbnailCard({
    super.key,
    required this.videoUrl,
    this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        getYoutubeThumbnail(videoUrl, quality: 'maxresdefault');

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white54, size: 64),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: const Icon(Icons.play_circle_outline,
                    color: Colors.white54, size: 64),
              ),
            Container(color: Colors.black26),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}
