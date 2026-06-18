import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/youtube_utils.dart';

class YouTubeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool showControls;

  const YouTubeVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.showControls = true,
  });

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final id = YouTubeUtils.extractId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      _error = 'Invalid video URL';
      return;
    }
    _controller = YoutubePlayerController(
      initialVideoId: id,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
        captionLanguage: 'en',
        showLiveFullscreenButton: true,
        hideThumbnail: false,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (mounted && _controller.value.isReady && !_isPlayerReady) {
      setState(() => _isPlayerReady = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: const Color(0xFF0F172A),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white38, size: 40),
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF0F6B4A),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF0F6B4A),
          handleColor: Color(0xFF0F6B4A),
          bufferedColor: Color(0x400F6B4A),
          backgroundColor: Color(0x20FFFFFF),
        ),
        onReady: () {
          if (mounted) setState(() => _isPlayerReady = true);
        },
        onEnded: (_) {},
      ),
      builder: (context, player) => player,
    );
  }
}

class YouTubeVideoPlayerFullScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final bool autoPlay;

  const YouTubeVideoPlayerFullScreen({
    super.key,
    required this.videoUrl,
    this.title,
    this.autoPlay = true,
  });

  @override
  State<YouTubeVideoPlayerFullScreen> createState() => _YouTubeVideoPlayerFullScreenState();
}

class _YouTubeVideoPlayerFullScreenState extends State<YouTubeVideoPlayerFullScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    final id = YouTubeUtils.extractId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      _error = 'Invalid video URL';
      return;
    }
    _controller = YoutubePlayerController(
      initialVideoId: id,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: true,
        enableCaption: true,
        captionLanguage: 'en',
        showLiveFullscreenButton: true,
        hideThumbnail: false,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (mounted && _controller.value.isReady && !_isPlayerReady) {
      setState(() => _isPlayerReady = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.title ?? 'Video',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF0F6B4A),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF0F6B4A),
                    handleColor: Color(0xFF0F6B4A),
                    bufferedColor: Color(0x400F6B4A),
                    backgroundColor: Color(0x20FFFFFF),
                  ),
                  onReady: () {
                    if (mounted) setState(() => _isPlayerReady = true);
                  },
                  onEnded: (_) {},
                ),
                builder: (context, player) => player,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
