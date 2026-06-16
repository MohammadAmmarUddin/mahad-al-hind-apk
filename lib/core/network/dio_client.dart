import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static String? _cachedToken;

  DioClient({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
    _loadToken();
  }

  Future<void> _loadToken() async {
    _cachedToken = await _secureStorage.read(key: 'access_token');
  }

  static void setToken(String? token) {
    _cachedToken = token;
  }

  static String? get currentToken => _cachedToken;

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return _dio.patch(path, data: data, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Options? options}) async {
    return _dio.delete(path, data: data, options: options);
  }
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = DioClient._cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST: ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR: ${err.response?.statusCode} ${err.requestOptions.uri} ${err.message}');
    handler.next(err);
  }
}
