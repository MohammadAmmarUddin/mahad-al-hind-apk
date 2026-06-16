import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../domain/entities/shayekh.dart';
import '../../data/datasources/shayekh_remote_datasource.dart';
import '../../data/repositories/shayekh_repository_impl.dart';

final shayekhDataSourceProvider = Provider<ShayekhRemoteDataSource>((ref) => ShayekhRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider)));
final shayekhRepositoryProvider = Provider<ShayekhRepositoryImpl>((ref) => ShayekhRepositoryImpl(remoteDataSource: ref.read(shayekhDataSourceProvider)));
final shayekhListProvider = FutureProvider<List<Shayekh>>((ref) async => ref.read(shayekhRepositoryProvider).getAllShayekh());
final shayekhDetailProvider = FutureProvider.family<Shayekh, String>((ref, id) async => ref.read(shayekhRepositoryProvider).getShayekhDetail(id));
