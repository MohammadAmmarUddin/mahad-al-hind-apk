import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> signup({required String firstname, required String lastname, required String email, required String phone, required String role, String? password, String? batch});
  Future<User> googleLogin({required String email, required String name, String? photoUrl});
  Future<void> forgetPassword({required String email});
  Future<void> resetPassword({required String email, required String otp, required String newPassword});
  Future<User> getProfile(String userId);
  Future<void> updateProfile({required String userId, Map<String, dynamic>? data});
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<void> deleteAccount();
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
}
