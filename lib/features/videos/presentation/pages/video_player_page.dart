import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/youtube_player_widget.dart';
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
  @override
  Widget build(BuildContext context) {
    final video = ref.watch(currentVideoProvider);
    final displayTitle = widget.title ?? video?.title ?? 'Video';
    final displayTag = widget.tag ?? video?.tag;
    final displayDesc = widget.desc ?? video?.desc;
    final videoUrl = widget.embedUrl ?? video?.embedUrl ?? '';

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
          YoutubePlayerWidget(
            videoUrl: videoUrl,
            autoPlay: true,
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
