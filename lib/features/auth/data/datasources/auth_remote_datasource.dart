import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> signup({required String firstname, required String lastname, required String email, required String phone, required String role, String? password, String? batch});
  Future<Map<String, dynamic>> googleLogin({required String idToken});
  Future<void> forgetPassword({required String email});
  Future<void> resetPassword({required String email, required String otp, required String newPassword});
  Future<UserModel> getProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> data);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  Map<String, dynamic> _parseResponse(Response response) {
    return response.data as Map<String, dynamic>;
  }

  String _extractError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['error'] ?? data['message'] ?? data['msg'] ?? 'Error ${e.response!.statusCode}';
      }
      return data.toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return e.message ?? 'Something went wrong';
  }

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = _parseResponse(response);
      return {
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
      };
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<Map<String, dynamic>> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String role,
    String? password,
    String? batch,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.signup,
        data: {
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'role': role,
          if (password != null && password.isNotEmpty) 'password': password,
          if (batch != null && batch.isNotEmpty) 'batch': batch,
        },
      );
      final data = _parseResponse(response);
      return {
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
      };
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<Map<String, dynamic>> googleLogin({required String idToken}) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.googleLogin,
        data: {'idToken': idToken},
      );
      final data = _parseResponse(response);
      return {
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
      };
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> forgetPassword({required String email}) async {
    try {
      await _dioClient.post(ApiEndpoints.forgetPassword, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    try {
      await _dioClient.post(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<UserModel> getProfile(String userId) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.singleUser(userId));
      final data = _parseResponse(response);
      return UserModel.fromJson(data['data'] ?? data['user'] ?? data);
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _dioClient.patch('${ApiEndpoints.updateUser}$userId', data: data);
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dioClient.patch(
        ApiEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dioClient.delete(ApiEndpoints.deleteMyAccount);
    } on DioException catch (e) {
      throw ApiException(message: _extractError(e), statusCode: e.response?.statusCode);
    }
  }
}
