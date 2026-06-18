import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
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
      );
      state = const AsyncValue.data(true);
    } catch (e) {
      state = const AsyncValue.data(false);
      rethrow;
    }
  }

  static const _webClientId = '449725978000-eea576epbteq5e8um8nc11cm2742blce.apps.googleusercontent.com';

  Future<bool> googleLogin() async {
    state = const AsyncValue.loading();
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: _webClientId,
      );

      developer.log('Starting Google Sign-In...', name: 'AuthNotifier');
      developer.log('Web Client ID: $_webClientId', name: 'AuthNotifier');

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        state = const AsyncValue.data(false);
        developer.log('Google Sign-In error: ${e.runtimeType}', name: 'AuthNotifier');
        if (e is PlatformException) {
          final code = e.code.toLowerCase();
          developer.log('PlatformException code: ${e.code}', name: 'AuthNotifier');
          developer.log('PlatformException message: ${e.message}', name: 'AuthNotifier');
          developer.log('PlatformException details: ${e.details}', name: 'AuthNotifier');
          if (code.contains('cancel') || code.contains('abort') || code.contains('sign_in_cancelled')) {
            return false;
          }
          if (code.contains('developer_error')) {
            throw Exception(
              'Google Sign-In DEVELOPER_ERROR.\n'
              'This usually means:\n'
              '1. SHA-1 fingerprint not registered in Google Cloud Console\n'
              '2. Wrong Web Client ID\n'
              '3. OAuth consent screen not configured\n'
              'Debug SHA-1: 37:5B:C4:26:C0:EA:4A:AD:01:4A:79:13:18:3D:4E:7C:7D:68:EA:57\n'
              'Details: ${e.details}',
            );
          }
          if (code.contains('network_error')) {
            throw Exception('Network error. Please check your internet connection.');
          }
          if (code.contains('sign_in_required')) {
            throw Exception('Google Sign-In is required. Please sign in to continue.');
          }
          throw Exception('Google Sign-In failed [${e.code}]: ${e.message}');
        }
        developer.log('Non-PlatformException error: $e', name: 'AuthNotifier');
        throw Exception('Google Sign-In failed: $e');
      }

      if (googleUser == null) {
        developer.log('Google Sign-In returned null (user cancelled)', name: 'AuthNotifier');
        state = const AsyncValue.data(false);
        return false;
      }

      developer.log('Google Sign-In success: ${googleUser.email}', name: 'AuthNotifier');

      final authentication = await googleUser.authentication;
      final idToken = authentication.idToken;
      final accessToken = authentication.accessToken;

      developer.log('ID Token present: ${idToken != null}', name: 'AuthNotifier');
      developer.log('Access Token present: ${accessToken != null}', name: 'AuthNotifier');

      if (idToken == null || idToken.isEmpty) {
        state = const AsyncValue.data(false);
        throw Exception(
          'Failed to get Google ID token.\n'
          'ID Token: ${idToken ?? "null"}\n'
          'Access Token: ${accessToken ?? "null"}\n'
          'Try: Revoke access in Google account settings and try again.',
        );
      }

      try {
        await ref.read(authRepositoryProvider).googleLogin(idToken: idToken);
      } catch (e) {
        final msg = e.toString().contains('Exception:')
            ? e.toString().replaceFirst('Exception: ', '')
            : e.toString();
        if (msg.contains('Invalid Google token')) {
          throw Exception('Google authentication failed. Please try again.');
        }
        if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
          throw Exception('Network error. Please check your internet connection.');
        }
        rethrow;
      }

      state = const AsyncValue.data(true);
      return true;
    } catch (e) {
      developer.log('googleLogin final error: $e', name: 'AuthNotifier');
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
