import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;

  Future<void> play(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> playAsset(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> setSpeed(double speed) async => await _player.setSpeed(speed);

  Future<void> setVolume(double volume) async => await _player.setVolume(volume);

  Future<void> setLoopMode(LoopMode mode) async => await _player.setLoopMode(mode);

  Future<void> seekToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> seekToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  void dispose() {
    _player.dispose();
  }
}
