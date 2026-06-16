import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../presentation/providers/home_provider.dart';

class AudioPreviewSection extends ConsumerWidget {
  const AudioPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDataAsync = ref.watch(homeDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Audio Library', actionText: 'View All', onAction: () => context.push('/audio')),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: homeDataAsync.when(
            data: (homeData) {
              final videos = homeData.videos;
              final tags = <String>{};
              for (final v in videos) {
                final tag = v['tag'];
                if (tag != null && tag.toString().isNotEmpty) tags.add(tag.toString());
              }
              final categories = tags.toList()..sort();
              if (categories.isEmpty) {
                categories.addAll(['Tilawah', 'Bayan', 'Nasheed', 'Azaan']);
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length > 6 ? 6 : categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final icons = [Icons.menu_book_rounded, Icons.mic_rounded, Icons.music_note_rounded, Icons.volume_up_rounded, Icons.headphones_rounded, Icons.equalizer_rounded];
                  final colors = [AppColors.primary, AppColors.accent, AppColors.secondary, AppColors.info, AppColors.primaryDark, AppColors.accentDark];
                  return GestureDetector(
                    onTap: () => context.push('/audio'),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors[index % colors.length], colors[index % colors.length].withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colors[index % colors.length].withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[index % icons.length], color: Colors.white, size: 28),
                          const Spacer(),
                          Text(
                            cat,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
