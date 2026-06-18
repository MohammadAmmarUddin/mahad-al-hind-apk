import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/videos_provider.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _embedUrl;

  String _normalizeYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    url = url.trim();
    if (url.startsWith('http://')) url = url.replaceFirst('http://', 'https://');

    if (!url.startsWith('https://')) {
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        return 'https://www.youtube.com/embed/$url?autoplay=0&rel=0&modestbranding=1&playsinline=1';
      }
      url = 'https://$url';
    }

    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) {
        return 'https://www.youtube.com/embed/${m.group(1)}?autoplay=0&rel=0&modestbranding=1&playsinline=1';
      }
    }
    return url;
  }

  String? _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final video = ref.read(currentVideoProvider);
    _embedUrl = _normalizeYoutubeUrl(video?.embedUrl);
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

  Future<void> _openInBrowser() async {
    if (_embedUrl != null && _embedUrl!.isNotEmpty) {
      final uri = Uri.parse(_embedUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(currentVideoProvider);
    final youtubeId = _extractYoutubeId(video?.embedUrl);
    final thumbnailUrl = youtubeId != null
        ? 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          video?.title ?? 'Video',
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_hasError)
            IconButton(
              icon: const Icon(Icons.open_in_browser, color: Colors.white),
              onPressed: _openInBrowser,
            ),
        ],
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
                  Text(video?.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (video?.tag != null && video!.tag!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text(video.tag!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (video?.desc != null && video!.desc!.isNotEmpty) ...[
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Text(video.desc!, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                  ],
                  if (_hasError) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text('Watch on YouTube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
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
    return GestureDetector(
      onTap: _openInBrowser,
      child: Container(
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
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
            ),
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Tap to watch on YouTube', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
