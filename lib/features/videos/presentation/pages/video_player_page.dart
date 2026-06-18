import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../providers/videos_provider.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String? embedUrl;
  final String? title;
  final String? tag;
  final String? desc;
  const VideoPlayerPage({super.key, this.embedUrl, this.title, this.tag, this.desc});

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final video = ref.read(currentVideoProvider);
    final url = widget.embedUrl ?? video?.embedUrl;
    _initPlayer(url);
  }

  void _initPlayer(String? url) {
    if (url == null || url.isEmpty) {
      setState(() { _hasError = true; _isLoading = false; });
      return;
    }

    final id = YouTubeUtils.extractId(url);
    String html;
    if (id != null && id.isNotEmpty) {
      html = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { margin: 0; padding: 0; }
            html, body { width: 100%; height: 100%; background: #0F172A; overflow: hidden; }
            iframe { width: 100%; height: 100%; border: none; }
          </style>
        </head>
        <body>
          <iframe src="https://www.youtube.com/embed/$id?autoplay=1&rel=0&modestbranding=1&playsinline=1&enablejsapi=1"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen></iframe>
        </body>
        </html>
      ''';
    } else {
      html = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { margin: 0; padding: 0; }
            html, body { width: 100%; height: 100%; background: #000; overflow: hidden; display: flex; align-items: center; justify-content: center; }
            video { width: 100%; height: 100%; object-fit: contain; }
          </style>
        </head>
        <body>
          <video src="$url" controls autoplay playsinline></video>
        </body>
        </html>
      ''';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(YouTubeUtils.webUserAgent)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() { _isLoading = false; _hasError = true; });
        },
      ))
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(currentVideoProvider);
    final displayTitle = widget.title ?? video?.title ?? 'Video';
    final displayTag = widget.tag ?? video?.tag;
    final displayDesc = widget.desc ?? video?.desc;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          displayTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: const Color(0xFF0F172A),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_controller != null)
                    Positioned.fill(
                        child: WebViewWidget(controller: _controller!)),
                  if (_isLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black26,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  if (_hasError)
                    const Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.white38, size: 48),
                            SizedBox(height: 12),
                            Text('Unable to load video',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTitle,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  if (displayTag != null && displayTag.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(displayTag,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                  if (displayDesc != null && displayDesc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Text(displayDesc,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
