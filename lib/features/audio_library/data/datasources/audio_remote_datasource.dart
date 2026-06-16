import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/audio_track.dart';

abstract class AudioRemoteDataSource {
  Future<List<AudioTrack>> getAllAudio({String? category, int page = 1});
}

class AudioRemoteDataSourceImpl implements AudioRemoteDataSource {
  final DioClient _dioClient;
  AudioRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  @override
  Future<List<AudioTrack>> getAllAudio({String? category, int page = 1}) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.gallery);
      final rawData = response.data;

      List<dynamic> items = [];
      if (rawData is List) {
        items = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        items = rawData['data'] as List;
      }

      final audioTracks = items
          .where((item) {
            final type = (item['type'] ?? item['resourceType'] ?? '').toString().toLowerCase();
            return type == 'audio' || type == 'mp3' || type == 'wav' || type == 'ogg';
          })
          .map((item) => AudioTrack(
                id: item['_id']?.toString() ?? item['id']?.toString() ?? '',
                title: item['title']?.toString() ?? item['description']?.toString() ?? 'Untitled',
                artist: item['description']?.toString(),
                shayekhName: item['title']?.toString(),
                url: item['url']?.toString() ?? '',
                coverUrl: item['url']?.toString(),
                category: _mapCategory(item['title']?.toString() ?? item['description']?.toString()),
                duration: null,
                isFavorite: false,
                playCount: 0,
                createdAt: item['createdAt']?.toString(),
              ))
          .toList();

      if (category != null && category.isNotEmpty) {
        return audioTracks.where((t) => t.category?.toLowerCase() == category.toLowerCase()).toList();
      }

      return audioTracks;
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  String _mapCategory(String? title) {
    if (title == null) return 'Other';
    final lower = title.toLowerCase();
    if (lower.contains('surah') || lower.contains('quran') || lower.contains('tilawah') || lower.contains('recit')) return 'Tilawah';
    if (lower.contains('azaan') || lower.contains('adhan') || lower.contains('prayer')) return 'Azaan';
    if (lower.contains('bayan') || lower.contains('lecture') || lower.contains('tafsir')) return 'Bayan';
    if (lower.contains('nasheed') || lower.contains('song')) return 'Nasheed';
    if (lower.contains('dars') || lower.contains('class')) return 'Dars';
    return 'Other';
  }
}
