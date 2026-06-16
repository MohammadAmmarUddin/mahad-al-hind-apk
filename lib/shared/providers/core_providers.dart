import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/file_upload_service.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
final fileUploadServiceProvider = Provider<FileUploadService>((ref) => FileUploadService());
