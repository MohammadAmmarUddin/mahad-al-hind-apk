import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/home_data.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final homeDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepositoryImpl>((ref) {
  return HomeRepositoryImpl(remoteDataSource: ref.read(homeDataSourceProvider));
});

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  return ref.read(homeRepositoryProvider).getHomeData();
});
