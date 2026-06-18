import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/audio_track.dart';
import '../../data/datasources/audio_remote_datasource.dart';
import '../../data/repositories/audio_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final audioDataSourceProvider = Provider<AudioRemoteDataSource>((ref) {
  return AudioRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final audioRepositoryProvider = Provider<AudioRepositoryImpl>((ref) {
  return AudioRepositoryImpl(
    remoteDataSource: ref.read(audioDataSourceProvider),
  );
});

final audioTracksProvider = FutureProvider<List<AudioTrack>>((ref) async {
  try {
    return await ref.read(audioRepositoryProvider).getAllAudio();
  } catch (_) {
    return [];
  }
});

final audioCategoryProvider = StateProvider<String?>((ref) => null);

final filteredAudioProvider = FutureProvider<List<AudioTrack>>((ref) async {
  try {
    final category = ref.watch(audioCategoryProvider);
    return await ref.read(audioRepositoryProvider).getAllAudio(category: category);
  } catch (_) {
    return [];
  }
});

// Current playing track
final currentTrackProvider = StateProvider<AudioTrack?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final audioPositionProvider = StateProvider<Duration>((ref) => Duration.zero);
final audioDurationProvider = StateProvider<Duration>((ref) => Duration.zero);
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);
final favoritesProvider = StateProvider<List<String>>((ref) => []);
final audioQueueProvider = StateProvider<List<AudioTrack>>((ref) => []);
final currentQueueIndexProvider = StateProvider<int>((ref) => 0);
