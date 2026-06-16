import '../../domain/entities/home_data.dart';
import '../datasources/home_remote_datasource.dart';
import '../../../../core/storage/hive_storage.dart';

class HomeRepositoryImpl {
  final HomeRemoteDataSource _remoteDataSource;
  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<HomeData> getHomeData() async {
    try {
      final data = await _remoteDataSource.getHomeData();
      await HiveStorage.cacheData('home_data', data, expiry: const Duration(minutes: 30));
      return HomeData(
        topCourses: data['topCourses'] as List<dynamic>? ?? [],
        reviews: data['reviews'] as List<dynamic>? ?? [],
        videos: data['videos'] as List<dynamic>? ?? [],
        gallery: data['gallery'] as List<dynamic>? ?? [],
        siteContent: data['siteContent'] as Map<String, dynamic>?,
        siteSettings: data['siteSettings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      final cached = HiveStorage.getCachedData('home_data');
      if (cached != null) {
        return HomeData(
          topCourses: (cached['topCourses'] as List<dynamic>?) ?? [],
          reviews: (cached['reviews'] as List<dynamic>?) ?? [],
          videos: (cached['videos'] as List<dynamic>?) ?? [],
          gallery: (cached['gallery'] as List<dynamic>?) ?? [],
          siteContent: cached['siteContent'] as Map<String, dynamic>?,
          siteSettings: cached['siteSettings'] as Map<String, dynamic>?,
        );
      }
      rethrow;
    }
  }
}
