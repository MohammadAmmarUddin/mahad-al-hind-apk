import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/audio_remote_datasource.dart';
import '../../data/repositories/audio_repository.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/audio_category.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../shared/providers/core_providers.dart';

// ─── Data Layer ───

final audioDataSourceProvider = Provider<AudioRemoteDataSource>((ref) {
  return AudioRemoteDataSource(ref.read(dioClientProvider));
});

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  return AudioRepository(ref.read(audioDataSourceProvider));
});

// ─── Audio Player Service ───

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

// ─── Categories ───

final audioCategoriesProvider = FutureProvider.family<List<AudioCategory>, String?>((ref, type) async {
  return ref.read(audioRepositoryProvider).getCategories(type: type);
});

// ─── Tracks ───

final audioTracksProvider = FutureProvider.family<List<AudioTrack>, Map<String, String?>>((ref, params) async {
  return ref.read(audioRepositoryProvider).getAudios(
    categoryId: params['categoryId'],
    search: params['search'],
    reciter: params['reciter'],
    sort: params['sort'],
  );
});

final audioSearchProvider = FutureProvider.family<List<AudioTrack>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.read(audioRepositoryProvider).searchAudios(query);
});

// ─── Playback State ───

final currentTrackProvider = StateProvider<AudioTrack?>((ref) => null);
final audioQueueProvider = StateProvider<List<AudioTrack>>((ref) => []);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final audioPositionProvider = StateProvider<Duration>((ref) => Duration.zero);
final audioDurationProvider = StateProvider<Duration>((ref) => Duration.zero);
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);
final currentCategoryIdProvider = StateProvider<String?>((ref) => null);

// ─── Favorites (persisted in SharedPreferences) ───

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  static const _key = 'audio_favorites';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    state = Set.from(list);
  }

  Future<void> toggle(String audioId) async {
    if (state.contains(audioId)) {
      state = {...state}..remove(audioId);
    } else {
      state = {...state, audioId};
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  bool isFavorite(String audioId) => state.contains(audioId);
}

// ─── Recently Played (persisted) ───

final recentlyPlayedProvider = StateNotifierProvider<RecentlyPlayedNotifier, List<AudioTrack>>((ref) {
  return RecentlyPlayedNotifier();
});

class RecentlyPlayedNotifier extends StateNotifier<List<AudioTrack>> {
  static const _key = 'audio_recently_played';
  static const _maxItems = 20;

  RecentlyPlayedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    state = jsonList.map((j) => AudioTrack.fromJson(
      Map<String, dynamic>.from(jsonDecode(j) as Map)
    )).where((t) => t.id.isNotEmpty).toList();
  }

  Future<void> add(AudioTrack track) async {
    final updated = <AudioTrack>[track, ...state.where((AudioTrack t) => t.id != track.id)].take(_maxItems).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.map<String>((AudioTrack t) => jsonEncode(t.toJson())).toList());
  }
}

// ─── Playback Progress Tracking ───

final playbackProgressProvider = StateNotifierProvider<PlaybackProgressNotifier, Map<String, double>>((ref) {
  return PlaybackProgressNotifier();
});

class PlaybackProgressNotifier extends StateNotifier<Map<String, double>> {
  static const _key = 'audio_playback_progress';

  PlaybackProgressNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_key));
    final map = <String, double>{};
    for (final k in keys) {
      final id = k.replaceFirst('${_key}_', '');
      map[id] = prefs.getDouble(k) ?? 0;
    }
    state = map;
  }

  Future<void> saveProgress(String audioId, double progress) async {
    state = {...state, audioId: progress};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_key}_$audioId', progress);
  }

  double getProgress(String audioId) => state[audioId] ?? 0;
}
