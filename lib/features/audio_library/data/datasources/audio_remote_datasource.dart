import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/audio_category.dart';

class AudioRemoteDataSource {
  final DioClient _dio;
  AudioRemoteDataSource(this._dio);

  Future<List<AudioCategory>> getCategories({String? type, String? parentId}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (parentId != null) params['parentId'] = parentId;

    final res = await _dio.get(ApiEndpoints.audioCategories, queryParameters: params);
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => AudioCategory.fromJson(e)).toList();
    }
    return [];
  }

  Future<AudioCategory> getCategoryById(String id) async {
    final res = await _dio.get(ApiEndpoints.audioCategory(id));
    final data = res.data;
    if (data is Map && data['data'] is Map) {
      return AudioCategory.fromJson(data['data']);
    }
    throw Exception('Category not found');
  }

  Future<List<AudioTrack>> getAudios({String? categoryId, String? search, String? reciter, String? sort, int limit = 50, int skip = 0}) async {
    final params = <String, dynamic>{
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    if (categoryId != null) params['categoryId'] = categoryId;
    if (search != null) params['search'] = search;
    if (reciter != null) params['reciter'] = reciter;
    if (sort != null) params['sort'] = sort;

    final res = await _dio.get(ApiEndpoints.audios, queryParameters: params);
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => AudioTrack.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> incrementPlayCount(String id) async {
    await _dio.patch(ApiEndpoints.audioPlay(id));
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.audioCategories, data: data);
  }

  Future<void> createAudio(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.audios, data: data);
  }

  Future<void> updateAudio(String id, Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.audioItem(id), data: data);
  }

  Future<void> deleteAudio(String id) async {
    await _dio.delete(ApiEndpoints.audioItem(id));
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _dio.put(ApiEndpoints.audioCategory(id), data: data);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete(ApiEndpoints.audioCategory(id));
  }
}
