import '../../domain/entities/shayekh.dart';
import '../datasources/shayekh_remote_datasource.dart';

class ShayekhRepositoryImpl {
  final ShayekhRemoteDataSource _remoteDataSource;
  ShayekhRepositoryImpl({required ShayekhRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<List<Shayekh>> getAllShayekh() async => _remoteDataSource.getAllShayekh();
  Future<Shayekh> getShayekhDetail(String id) async => _remoteDataSource.getShayekhDetail(id);
}
