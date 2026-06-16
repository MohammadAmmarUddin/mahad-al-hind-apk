import '../../domain/entities/audio_track.dart';
import '../datasources/audio_remote_datasource.dart';

class AudioRepositoryImpl {
  final AudioRemoteDataSource _remoteDataSource;
  AudioRepositoryImpl({required AudioRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<AudioTrack>> getAllAudio({String? category, int page = 1}) async {
    return _remoteDataSource.getAllAudio(category: category, page: page);
  }
}
