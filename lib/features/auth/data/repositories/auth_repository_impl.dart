import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
    GoogleSignIn? googleSignIn,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      await HiveStorage.clearUser();
      final result = await _remoteDataSource.login(email: email, password: password);
      final user = result['user'] as User;
      final token = result['token'] as String?;
      await _saveUserData(user, token);
      if (user.id.isNotEmpty) {
        try {
          final freshProfile = await _remoteDataSource.getProfile(user.id);
          await _saveUserData(freshProfile, token);
          return freshProfile;
        } catch (_) {}
      }
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<User> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required String role,
    String? password,
    String? batch,
  }) async {
    try {
      await HiveStorage.clearUser();
      final result = await _remoteDataSource.signup(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phone: phone,
        role: role,
        password: password,
        batch: batch,
      );
      final user = result['user'] as User;
      final token = result['token'] as String?;
      await _saveUserData(user, token);
      if (user.id.isNotEmpty) {
        try {
          final freshProfile = await _remoteDataSource.getProfile(user.id);
          await _saveUserData(freshProfile, token);
          return freshProfile;
        } catch (_) {}
      }
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<User> googleLogin({required String idToken}) async {
    try {
      await HiveStorage.clearUser();
      final result = await _remoteDataSource.googleLogin(idToken: idToken);
      final user = result['user'] as User;
      final token = result['token'] as String?;
      await _saveUserData(user, token);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> forgetPassword({required String email}) async {
    try {
      await _remoteDataSource.forgetPassword(email: email);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    try {
      await _remoteDataSource.resetPassword(email: email, otp: otp, newPassword: newPassword);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<User> getProfile(String userId) async {
    try {
      final user = await _remoteDataSource.getProfile(userId);
      await _saveUserData(user, null);
      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({required String userId, Map<String, dynamic>? data}) async {
    try {
      await _remoteDataSource.updateProfile(userId, data ?? {});
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _remoteDataSource.changePassword(currentPassword, newPassword);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      await logout();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    DioClient.setToken(null);
    await _secureStorage.deleteAll();
    await HiveStorage.clearUser();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User?> getCurrentUser() async {
    final userData = HiveStorage.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  Future<void> _saveUserData(User user, String? token) async {
    final userModel = UserModel.fromEntity(user);
    final json = userModel.toJson();
    await HiveStorage.saveUser(json);
    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: 'access_token', value: token);
      DioClient.setToken(token);
    }
    await _secureStorage.write(key: 'user_id', value: user.id);
  }
}
