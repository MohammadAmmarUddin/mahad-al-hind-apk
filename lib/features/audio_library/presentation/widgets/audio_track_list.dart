import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/audio_provider.dart';
import '../../domain/entities/audio_track.dart';

class AudioTrackList extends ConsumerWidget {
  const AudioTrackList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioAsync = ref.watch(filteredAudioProvider);

    return audioAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.headset_off, size: 64, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'No audio content found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(
            bottom: ref.watch(currentTrackProvider) != null ? 72 : 16,
          ),
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final currentTrack = ref.watch(currentTrackProvider);
            final isCurrentlyPlaying = currentTrack?.id == track.id;
            return _AudioTrackTile(
              track: track,
              isPlaying: isCurrentlyPlaying,
              onTap: () {
                ref.read(currentTrackProvider.notifier).state = track;
                ref.read(isPlayingProvider.notifier).state = true;
                ref.read(audioQueueProvider.notifier).state = tracks;
                ref.read(currentQueueIndexProvider.notifier).state = index;
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AudioTrackTile extends StatelessWidget {
  final AudioTrack track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _AudioTrackTile({
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: isPlaying ? AppColors.primaryGradient : AppColors.accentGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isPlaying
              ? const Icon(Icons.equalizer, color: Colors.white, size: 24)
              : const Icon(Icons.play_arrow, color: Colors.white, size: 24),
        ),
      ),
      title: Text(
        track.title ?? 'Unknown',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
          color: isPlaying ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        track.shayekhName ?? track.artist ?? 'Unknown Artist',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.duration != null)
            Text(
              Formatters.duration(track.duration!),
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              track.isFavorite == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 20,
              color: track.isFavorite == true
                  ? AppColors.error
                  : AppColors.textHint,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
