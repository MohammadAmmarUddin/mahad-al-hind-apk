import '../datasources/audio_remote_datasource.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/audio_category.dart';

class AudioRepository {
  final AudioRemoteDataSource _dataSource;
  AudioRepository(this._dataSource);

  Future<List<AudioCategory>> getCategories({String? type}) =>
      _dataSource.getCategories(type: type);

  Future<AudioCategory> getCategoryById(String id) =>
      _dataSource.getCategoryById(id);

  Future<List<AudioTrack>> getAudios({String? categoryId, String? search, String? reciter, String? sort}) =>
      _dataSource.getAudios(categoryId: categoryId, search: search, reciter: reciter, sort: sort);

  Future<List<AudioTrack>> searchAudios(String query) =>
      _dataSource.getAudios(search: query);

  Future<void> incrementPlayCount(String id) =>
      _dataSource.incrementPlayCount(id);

  Future<void> createCategory(Map<String, dynamic> data) =>
      _dataSource.createCategory(data);

  Future<void> createAudio(Map<String, dynamic> data) =>
      _dataSource.createAudio(data);

  Future<void> updateAudio(String id, Map<String, dynamic> data) =>
      _dataSource.updateAudio(id, data);

  Future<void> deleteAudio(String id) =>
      _dataSource.deleteAudio(id);

  Future<void> updateCategory(String id, Map<String, dynamic> data) =>
      _dataSource.updateCategory(id, data);

  Future<void> deleteCategory(String id) =>
      _dataSource.deleteCategory(id);
}
