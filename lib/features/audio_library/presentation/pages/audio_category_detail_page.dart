import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/audio_provider.dart';
import '../widgets/mini_player.dart';

class AudioCategoryDetailPage extends ConsumerWidget {
  final String categoryId;
  const AudioCategoryDetailPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catAsync = ref.watch(audioCategoriesProvider(null).future);
    final tracksAsync = ref.watch(audioTracksProvider({'categoryId': categoryId}));

    return Scaffold(
      appBar: AppBar(title: const Text('Category')),
      body: Column(
        children: [
          Expanded(
            child: tracksAsync.when(
              data: (tracks) {
                if (tracks.isEmpty) return const Center(child: Text('No audio in this category'));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tracks.length,
                  itemBuilder: (ctx, i) {
                    final track = tracks[i];
                    final currentTrack = ref.watch(currentTrackProvider);
                    final isCurrent = currentTrack?.id == track.id;
                    final isFav = ref.watch(favoritesProvider).contains(track.id);

                    return ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isCurrent
                            ? const Icon(Icons.equalizer, color: AppColors.primary, size: 22)
                            : Text('${i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                      title: Text(track.title, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? AppColors.primary : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(track.reciter.isNotEmpty ? track.reciter : track.formattedDuration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 18, color: isFav ? AppColors.error : AppColors.textHint),
                            onPressed: () => ref.read(favoritesProvider.notifier).toggle(track.id),
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(currentTrackProvider.notifier).state = track;
                        ref.read(audioQueueProvider.notifier).state = tracks;
                        final player = ref.read(audioPlayerServiceProvider);
                        player.play(track.audioUrl);
                        ref.read(isPlayingProvider.notifier).state = true;
                        ref.read(audioRepositoryProvider).incrementPlayCount(track.id);
                        context.push('/audio/player');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      bottomSheet: const MiniPlayer(),
    );
  }
}
