import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_helper.dart';
import 'admin_dashboard_page.dart';
import 'student_dashboard_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        final level = getAccessLevel(user);
        if (level == AccessLevel.admin) {
          return const AdminDashboardPage();
        }
        if (level == AccessLevel.student) {
          return const StudentDashboardPage();
        }
        // Not logged in or no student access
        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(level == AccessLevel.anonymous ? Icons.lock_outline : Icons.info_outline, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  level == AccessLevel.anonymous
                      ? 'Please login to access your dashboard'
                      : 'Student access not available',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  level == AccessLevel.anonymous
                      ? 'Login with your student account'
                      : 'Your account does not have student access. Contact admin for approval.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (level == AccessLevel.anonymous)
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Login', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading dashboard'))),
    );
  }
}
