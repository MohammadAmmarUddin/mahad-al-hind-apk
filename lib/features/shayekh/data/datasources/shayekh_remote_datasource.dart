import '../../../../core/network/dio_client.dart';
import '../../domain/entities/shayekh.dart';

abstract class ShayekhRemoteDataSource {
  Future<List<Shayekh>> getAllShayekh();
  Future<Shayekh> getShayekhDetail(String id);
}

class ShayekhRemoteDataSourceImpl implements ShayekhRemoteDataSource {
  final DioClient _dioClient;

  ShayekhRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<Shayekh>> getAllShayekh() async {
    try {
      final res = await _dioClient.get('/api/shayekh');
      final data = res.data;
      List<dynamic> items = [];
      if (data is List) items = data;
      else if (data is Map && data['data'] is List) items = data['data'];
      return items.map((j) => Shayekh(
        id: j['_id'] ?? j['id'] ?? '',
        name: j['name'] ?? '',
        bio: j['bio'] ?? '',
        country: j['country'] ?? '',
        specialization: j['specialization'] ?? '',
        totalCourses: j['totalCourses'] ?? 0,
        totalTilawah: j['totalTilawah'] ?? 0,
        followers: j['followers'] ?? 0,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Shayekh> getShayekhDetail(String id) async {
    final all = await getAllShayekh();
    return all.firstWhere((s) => s.id == id, orElse: () => all.isNotEmpty ? all.first : Shayekh(id: id, name: '', bio: '', country: '', specialization: '', totalCourses: 0, totalTilawah: 0, followers: 0));
  }
}
