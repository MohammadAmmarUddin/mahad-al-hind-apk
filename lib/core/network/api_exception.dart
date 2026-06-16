import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;

  factory ApiException.fromDioError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        String msg = 'Something went wrong';
        if (data is Map) {
          msg = data['error'] ?? data['message'] ?? data['msg'] ?? 'Error ${error.response!.statusCode}';
        }
        return ApiException(message: msg, statusCode: error.response!.statusCode);
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(message: 'Connection timeout. Please check your internet.');
        case DioExceptionType.connectionError:
          return ApiException(message: 'No internet connection.');
        default:
          return ApiException(message: error.message ?? 'Something went wrong.');
      }
    }
    return ApiException(message: error.toString());
  }
}
