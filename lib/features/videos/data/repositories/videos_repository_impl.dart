import '../../domain/entities/video.dart';
import '../datasources/videos_remote_datasource.dart';

class VideosRepositoryImpl {
  final VideosRemoteDataSource _remoteDataSource;
  VideosRepositoryImpl({required VideosRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<Video>> getVideos() async {
    return _remoteDataSource.getVideos();
  }
}
