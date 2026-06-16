import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../shared/providers/core_providers.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(dioClient: ref.read(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.data(false)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final isLoggedIn = await ref.read(authRepositoryProvider).isLoggedIn();
      state = AsyncValue.data(isLoggedIn);
    } catch (e) {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = const AsyncValue.data(true);
    } catch (e) {
      state = const AsyncValue.data(false);
      rethrow;
    }
  }

  Future<void> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    String role = 'student',
    String? password,
    String? batch,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signup(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phone: phone,
        role: role,
        password: password,
        batch: batch,
      );
      state = const AsyncValue.data(true);
    } catch (e) {
      state = const AsyncValue.data(false);
      rethrow;
    }
  }

  Future<void> googleLogin() async {
    state = const AsyncValue.loading();
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        state = const AsyncValue.data(false);
        throw Exception('Google Sign-In was cancelled or failed. Please try again.');
      }

      if (googleUser == null) {
        state = const AsyncValue.data(false);
        return;
      }

      final email = googleUser.email;
      final name = googleUser.displayName ?? '';
      final photoUrl = googleUser.photoUrl;

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      await ref.read(authRepositoryProvider).googleLogin(
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      state = const AsyncValue.data(true);
    } catch (e) {
      state = const AsyncValue.data(false);
      rethrow;
    }
  }

  Future<void> forgetPassword(String email) async {
    await ref.read(authRepositoryProvider).forgetPassword(email: email);
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await ref.read(authRepositoryProvider).resetPassword(
      email: email, otp: otp, newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(false);
  }

  bool get isAuthenticated => state.valueOrNull ?? false;
}

final currentUserProvider = FutureProvider<User?>((ref) async {
  final isLoggedIn = ref.watch(authStateProvider);
  if (isLoggedIn.valueOrNull != true) return null;
  return ref.read(authRepositoryProvider).getCurrentUser();
});
