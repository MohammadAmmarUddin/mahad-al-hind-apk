import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../storage/hive_storage.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // External
    sl.registerLazySingleton(() => const FlutterSecureStorage());

    // Core
    sl.registerLazySingleton(() => SecureStorage(storage: sl()));
    sl.registerLazySingleton(() => DioClient(secureStorage: sl()));

    // Initialize Hive
    await HiveStorage.init();

    // Load auth token into DioClient's static cache before any API calls
    final token = await sl<FlutterSecureStorage>().read(key: 'access_token');
    DioClient.setToken(token);
  }
}
