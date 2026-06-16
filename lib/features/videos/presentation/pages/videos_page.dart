import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/videos_provider.dart';

class VideosPage extends ConsumerWidget {
  const VideosPage({super.key});

  String? _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(r'(?:youtube\.com/embed/|youtu\.be/)([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Video Library')),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No videos found', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoId = _extractYoutubeId(video.embedUrl);
              final thumbnailUrl = videoId != null
                  ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
                  : null;

              return GestureDetector(
                onTap: () {
                  ref.read(currentVideoProvider.notifier).state = video;
                  context.push('/more/videos/player');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (thumbnailUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: thumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.play_circle, color: Colors.white, size: 48),
                                ),
                              )
                            else
                              const Icon(Icons.play_circle, color: Colors.white, size: 48),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title ?? '',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            if (video.tag != null && video.tag!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  video.tag!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (video.desc != null && video.desc!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                video.desc!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              TextButton(onPressed: () => ref.invalidate(videosProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
