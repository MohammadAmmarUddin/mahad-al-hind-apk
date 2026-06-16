import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/video.dart';
import '../../data/datasources/videos_remote_datasource.dart';
import '../../data/repositories/videos_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final videosDataSourceProvider = Provider<VideosRemoteDataSource>((ref) {
  return VideosRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final videosRepositoryProvider = Provider<VideosRepositoryImpl>((ref) {
  return VideosRepositoryImpl(remoteDataSource: ref.read(videosDataSourceProvider));
});

final videosProvider = FutureProvider<List<Video>>((ref) async {
  return ref.read(videosRepositoryProvider).getVideos();
});

final currentVideoProvider = StateProvider<Video?>((ref) => null);
