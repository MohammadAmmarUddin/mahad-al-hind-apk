import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          final level = getAccessLevel(user);
          final isAdmin = level == AccessLevel.admin;
          final isStudent = level == AccessLevel.student;
          final isLoggedIn = level != AccessLevel.anonymous;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(children: [
                    const Icon(Icons.person_add_outlined, color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    const Text('Login to access student features', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Enroll in courses, track progress, earn certificates', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                        child: const Text('Login / Sign Up'),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              if (isAdmin) ...[
                _buildSection(context, 'Admin Panel', [
                  _MoreItem(icon: Icons.admin_panel_settings, title: 'Admin Dashboard', subtitle: 'Full control panel', onTap: () => context.push('/more/dashboard'), color: AppColors.error),
                  _MoreItem(icon: Icons.school, title: 'Manage Courses', subtitle: 'Create, edit, delete courses', onTap: () => context.push('/more/admin/courses')),
                  _MoreItem(icon: Icons.videocam, title: 'Manage Videos', subtitle: 'Upload & manage videos', onTap: () => context.push('/more/admin/videos')),
                  _MoreItem(icon: Icons.headphones, title: 'Manage Audio', subtitle: 'Upload & manage audio', onTap: () => context.push('/more/admin/audio')),
                  _MoreItem(icon: Icons.photo_library, title: 'Manage Gallery', subtitle: 'Upload photos & images', onTap: () => context.push('/more/admin/gallery')),
                  _MoreItem(icon: Icons.notifications, title: 'Manage Notifications', subtitle: 'Send announcements', onTap: () => context.push('/more/admin/notifications')),
                  _MoreItem(icon: Icons.people, title: 'Manage Users', subtitle: 'View & manage users', onTap: () => context.push('/more/admin/users')),
                  _MoreItem(icon: Icons.how_to_reg, title: 'Enrollments', subtitle: 'Approve/reject enrollments', onTap: () => context.push('/more/admin/enrollments')),
                  _MoreItem(icon: Icons.receipt_long, title: 'Payments', subtitle: 'View payment records', onTap: () => context.push('/more/admin/payments')),
                  _MoreItem(icon: Icons.workspace_premium, title: 'Certificates', subtitle: 'Manage certificates', onTap: () => context.push('/more/admin/certificates')),
                  _MoreItem(icon: Icons.article, title: 'Site Content', subtitle: 'Edit homepage content', onTap: () => context.push('/more/admin/site-content')),
                ]),
                const SizedBox(height: 16),
              ],
              _buildSection(context, 'Public', [
                _MoreItem(icon: Icons.play_circle_outline, title: 'Video Gallery', subtitle: 'Watch Islamic lectures', onTap: () => context.push('/more/videos')),
                _MoreItem(icon: Icons.photo_library_outlined, title: 'Gallery', subtitle: 'Photos from events', onTap: () => context.push('/more/gallery')),
                _MoreItem(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Stay updated', onTap: () => context.push('/more/notifications')),
                _MoreItem(icon: Icons.verified_outlined, title: 'Certificate Checker', subtitle: 'Verify any certificate by ID', onTap: () => _showCertificateChecker(context)),
              ]),
              const SizedBox(height: 16),
              _buildSection(context, 'My Account', [
                _MoreItem(icon: Icons.person_outline, title: 'Profile', subtitle: isLoggedIn ? 'View & edit your profile' : 'Login to manage profile', onTap: () => requireAuth(context, ref, onAuthenticated: () => context.push('/more/profile'))),
                _MoreItem(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'App preferences', onTap: () => context.push('/more/settings')),
              ]),
              if (isStudent || isAdmin) ...[
                const SizedBox(height: 16),
                _buildSection(context, 'Student Features', [
                  _MoreItem(icon: Icons.dashboard_outlined, title: 'Dashboard', subtitle: 'Your progress & stats', onTap: () => context.push('/more/dashboard')),
                  _MoreItem(icon: Icons.receipt_long_outlined, title: 'Attendance', subtitle: 'Track class attendance', onTap: () => context.push('/more/attendance')),
                  _MoreItem(icon: Icons.payment_outlined, title: 'Fees & Payments', subtitle: 'View payment history', onTap: () => context.push('/more/fees')),
                  _MoreItem(icon: Icons.card_membership_outlined, title: 'Certificates', subtitle: 'View & verify certificates', onTap: () => context.push('/more/certificates')),
                  _MoreItem(icon: Icons.headset_mic_outlined, title: 'AI Assistant', subtitle: 'Get help from AI', onTap: () => context.push('/more/ai-assistant')),
                ]),
              ],
              if (isLoggedIn && !isStudent && !isAdmin) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Your account does not have student access yet. Contact admin for approval.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
      ),
    );
  }

  void _showCertificateChecker(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Check Certificate'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter Certificate ID',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                context.push('/verify-certificate?id=$id');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MoreItem({required this.icon, required this.title, required this.subtitle, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: itemColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
