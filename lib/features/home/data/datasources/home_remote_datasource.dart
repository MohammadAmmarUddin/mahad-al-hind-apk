import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/hive_storage.dart';

abstract class HomeRemoteDataSource {
  Future<Map<String, dynamic>> getHomeData();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient _dioClient;
  HomeRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final results = await Future.wait([
        _dioClient.get(ApiEndpoints.topCourses),
        _dioClient.get(ApiEndpoints.reviews),
        _dioClient.get(ApiEndpoints.videos),
        _dioClient.get(ApiEndpoints.gallery),
        _dioClient.get(ApiEndpoints.siteContent),
        _dioClient.get(ApiEndpoints.siteSettings),
      ]);

      return {
        'topCourses': _extractList(results[0].data),
        'reviews': _extractList(results[1].data),
        'videos': _extractList(results[2].data),
        'gallery': _extractList(results[3].data),
        'siteContent': _extractMap(results[4].data),
        'siteSettings': _extractMap(results[5].data),
      };
    } catch (e) {
      final cached = HiveStorage.getCachedData('home_data');
      if (cached != null) return Map<String, dynamic>.from(cached);
      rethrow;
    }
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['data'] is Map && response['data'].containsKey('data')) {
        return (response['data']['data'] as List?) ?? [];
      }
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data']);
    }
    if (response is Map && response['success'] == true && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data']);
    }
    return {};
  }
}
