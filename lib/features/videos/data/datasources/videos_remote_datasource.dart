import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/video.dart';

abstract class VideosRemoteDataSource {
  Future<List<Video>> getVideos();
}

class VideosRemoteDataSourceImpl implements VideosRemoteDataSource {
  final DioClient _dioClient;
  VideosRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['data'] is List) return response['data'] as List;
    return [];
  }

  @override
  Future<List<Video>> getVideos() async {
    final response = await _dioClient.get(ApiEndpoints.videos);
    final data = _extractList(response.data);
    return data.map((e) => Video.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
