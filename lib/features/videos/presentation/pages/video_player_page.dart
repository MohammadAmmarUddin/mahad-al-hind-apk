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
  String? _embedUrl;

  @override
  void initState() {
    super.initState();
    final video = ref.read(currentVideoProvider);
    _embedUrl = YouTubeUtils.getEmbedUrl(widget.embedUrl ?? video?.embedUrl);
    if (_embedUrl == null || _embedUrl!.isEmpty) {
      _hasError = true;
      _isLoading = false;
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() { _isLoading = false; });
          },
          onWebResourceError: (error) {
            if (mounted) setState(() { _isLoading = false; _hasError = true; });
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(_embedUrl!));
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(currentVideoProvider);
    final displayTitle = widget.title ?? video?.title ?? 'Video';
    final displayTag = widget.tag ?? video?.tag;
    final displayDesc = widget.desc ?? video?.desc;
    final displayUrl = widget.embedUrl ?? video?.embedUrl;
    final thumbnailUrl = YouTubeUtils.getThumbnail(displayUrl, quality: 'maxresdefault');

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
            child: _hasError
                ? _buildErrorFallback(thumbnailUrl)
                : Stack(
                    children: [
                      if (_isLoading)
                        Container(
                          color: const Color(0xFF0F172A),
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                      if (_controller != null)
                        WebViewWidget(controller: _controller!),
                    ],
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (displayTag != null && displayTag.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text(displayTag, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                  if (displayDesc != null && displayDesc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Text(displayDesc, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorFallback(String? thumbnailUrl) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 48),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
              child: const Text('Unable to load video', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
