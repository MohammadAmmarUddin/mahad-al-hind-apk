import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

class VideosSection extends StatelessWidget {
  final List<dynamic> videos;
  const VideosSection({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Latest Videos',
          actionText: 'View All',
          onAction: () => context.push('/more/videos'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length > 5 ? 5 : videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return _VideoCard(video: video);
            },
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final dynamic video;
  const _VideoCard({required this.video});

  String? _extractYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(r'(?:youtube\.com/embed/|youtu\.be/)([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final title = video['title'] ?? 'Video';
    final tag = video['tag'] ?? '';
    final embedUrl = video['embedUrl'] ?? '';
    final videoId = _extractYoutubeId(embedUrl);
    final thumbnailUrl = videoId != null ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg' : null;

    return GestureDetector(
      onTap: () => context.push('/more/videos/player', extra: embedUrl),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 95,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: double.infinity,
                        height: 95,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 36)),
                      ),
                    )
                  else
                    const Center(child: Icon(Icons.play_circle, color: Colors.white, size: 40)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.85),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if (tag.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 9, color: AppColors.accentDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
