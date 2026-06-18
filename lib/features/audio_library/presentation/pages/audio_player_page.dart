import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../domain/entities/audio_track.dart';
import '../providers/audio_provider.dart';

class AudioPlayerPage extends ConsumerStatefulWidget {
  const AudioPlayerPage({super.key});

  @override
  ConsumerState<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends ConsumerState<AudioPlayerPage> {
  late AudioPlayerService _player;

  @override
  void initState() {
    super.initState();
    _player = ref.read(audioPlayerServiceProvider);
    _listenToPlayer();
  }

  void _listenToPlayer() {
    _player.positionStream.listen((pos) {
      if (mounted) ref.read(audioPositionProvider.notifier).state = pos;
    });
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) ref.read(audioDurationProvider.notifier).state = dur;
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        ref.read(isPlayingProvider.notifier).state = state.playing;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(audioPositionProvider);
    final duration = ref.watch(audioDurationProvider);
    final speed = ref.watch(playbackSpeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A3D1F),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                  const Expanded(child: Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Spacer(),

            // Cover art
            Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.4)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 80),
            ),

            const SizedBox(height: 32),

            // Track info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(track?.title ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(track?.reciter ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14), textAlign: TextAlign.center),
                ],
              ),
            ),

            const Spacer(),

            // Seek slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: const Color(0xFFD4AF37),
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: const Color(0xFFD4AF37),
                      overlayColor: const Color(0xFFD4AF37).withOpacity(0.2),
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble())
                          : 0,
                      max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        Text(_formatDuration(duration), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Speed
                  GestureDetector(
                    onTap: () {
                      final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                      final currentIdx = speeds.indexOf(speed);
                      final nextIdx = (currentIdx + 1) % speeds.length;
                      ref.read(playbackSpeedProvider.notifier).state = speeds[nextIdx];
                      _player.setSpeed(speeds[nextIdx]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${speed}x', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                    onPressed: () => _player.seekToPrevious(),
                  ),

                  // Play/Pause
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        _player.pause();
                      } else {
                        _player.resume();
                      }
                    },
                    child: Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE8C84A)]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFF0A3D1F), size: 36),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                    onPressed: () => _player.seekToNext(),
                  ),

                  // Favorite
                  Consumer(
                    builder: (ctx, ref, _) {
                      final isFav = ref.watch(favoritesProvider).contains(track?.id);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.error : Colors.white, size: 26),
                        onPressed: () {
                          if (track != null) ref.read(favoritesProvider.notifier).toggle(track.id);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
