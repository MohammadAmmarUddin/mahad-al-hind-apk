import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/audio_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);

    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/audio/player'),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Consumer(
              builder: (ctx, ref, _) {
                final pos = ref.watch(audioPositionProvider);
                final dur = ref.watch(audioDurationProvider);
                final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
                return LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                );
              },
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(track.reciter.isNotEmpty ? track.reciter : 'Unknown', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 22),
                    onPressed: () {
                      final player = ref.read(audioPlayerServiceProvider);
                      player.seekToPrevious();
                    },
                  ),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                    onPressed: () {
                      final player = ref.read(audioPlayerServiceProvider);
                      final playing = ref.read(isPlayingProvider);
                      if (playing) {
                        player.pause();
                        ref.read(isPlayingProvider.notifier).state = false;
                      } else {
                        player.resume();
                        ref.read(isPlayingProvider.notifier).state = true;
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 22),
                    onPressed: () {
                      final player = ref.read(audioPlayerServiceProvider);
                      player.seekToNext();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
