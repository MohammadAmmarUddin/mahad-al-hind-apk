import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user.dart';

enum AccessLevel { anonymous, logged, student, admin }

AccessLevel getAccessLevel(User? user) {
  if (user == null) return AccessLevel.anonymous;
  if (user.role == 'admin') return AccessLevel.admin;
  if (user.hasStudentAccess) return AccessLevel.student;
  return AccessLevel.logged;
}

bool isLoggedIn(WidgetRef ref) {
  return ref.read(authStateProvider).valueOrNull ?? false;
}

void requireAuth(BuildContext context, WidgetRef ref, {VoidCallback? onAuthenticated}) {
  final isLoggedIn = ref.read(authStateProvider).valueOrNull ?? false;
  if (isLoggedIn) {
    onAuthenticated?.call();
    return;
  }
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Login Required'),
      content: const Text('Please login or create an account to continue.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push('/login');
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Login'),
        ),
      ],
    ),
  );
}

void requireStudentAccess(BuildContext context, WidgetRef ref, {VoidCallback? onAuthorized}) {
  final user = ref.read(currentUserProvider).valueOrNull;
  final level = getAccessLevel(user);
  if (level == AccessLevel.student || level == AccessLevel.admin) {
    onAuthorized?.call();
    return;
  }
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Student Access Required'),
      content: user == null
          ? const Text('Please login with your student account to access this feature.')
          : const Text('Your account does not have student access yet. Contact admin for approval.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
        if (user == null)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Login'),
          ),
      ],
    ),
  );
}
