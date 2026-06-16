import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _isFirstTimeKey = 'is_first_time';

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);

  Future<void> saveUserId(String userId) async => await _storage.write(key: _userIdKey, value: userId);
  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);

  Future<void> saveUserEmail(String email) async => await _storage.write(key: _userEmailKey, value: email);
  Future<String?> getUserEmail() async => await _storage.read(key: _userEmailKey);

  Future<void> setFirstTimeDone() async => await _storage.write(key: _isFirstTimeKey, value: 'false');
  Future<bool> isFirstTime() async {
    final value = await _storage.read(key: _isFirstTimeKey);
    return value == null || value == 'true';
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
