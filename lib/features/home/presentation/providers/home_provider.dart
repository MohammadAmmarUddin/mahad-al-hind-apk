import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_data.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/hive_storage.dart';

final homeDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepositoryImpl>((ref) {
  return HomeRepositoryImpl(remoteDataSource: ref.read(homeDataSourceProvider));
});

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  try {
    return await ref.read(homeRepositoryProvider).getHomeData();
  } catch (_) {
    return HomeData(
      topCourses: [],
      reviews: [],
      videos: [],
      gallery: [],
      siteContent: null,
      siteSettings: null,
    );
  }
});

final heroBannerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ref.read(dioClientProvider).get(ApiEndpoints.siteContent);
    final data = res.data;
    Map<String, dynamic> result = {};
    if (data is Map && data['data'] is Map) {
      result = Map<String, dynamic>.from(data['data']);
    }
    HiveStorage.cacheData('hero_banner_cache', result, expiry: const Duration(minutes: 10));
    return result;
  } catch (_) {
    final cached = HiveStorage.getCachedData('hero_banner_cache');
    if (cached != null && cached is Map) return Map<String, dynamic>.from(cached);
    return {};
  }
});
