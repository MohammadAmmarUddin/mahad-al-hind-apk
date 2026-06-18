import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/auth_helper.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  List<dynamic> _enrolledCourses = [];
  bool _loadingCourses = false;

  @override
  void initState() {
    super.initState();
    _fetchEnrolledCourses();
  }

  Future<void> _fetchEnrolledCourses() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() { _loadingCourses = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/course/getAllEnrolledCourse/${user.id}');
      final data = res.data;
      List<dynamic> courses = [];
      if (data is Map && data['courses'] is List) courses = data['courses'];
      if (data is List) courses = data;
      setState(() { _enrolledCourses = courses; _loadingCourses = false; });
    } catch (e) {
      setState(() { _loadingCourses = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.translate('profile'))),
      body: userAsync.when(
        data: (user) {
          if (user == null) return Center(child: Text(t.translate('loginRequired') ?? 'Not logged in'));
          final level = getAccessLevel(user);
          final isStudent = level == AccessLevel.student;
          final isAdmin = level == AccessLevel.admin;
          final name = user.displayName;
          final email = user.email ?? '';
          final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primarySurface,
                        backgroundImage: (user.photo != null && user.photo!.isNotEmpty) ? CachedNetworkImageProvider(user.photo!) : null,
                        child: (user.photo == null || user.photo!.isEmpty)
                            ? Text(initials.length > 2 ? initials.substring(0, 2) : initials,
                                style: const TextStyle(fontSize: 36, color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: AppColors.textSecondary)),
                if (user.batch != null && user.batch!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${t.translate('batch') ?? 'Batch'}: ${user.batch}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAdmin ? AppColors.error.withOpacity(0.1) : isStudent ? AppColors.primarySurface : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(user.role ?? 'student', t),
                    style: TextStyle(
                      color: isAdmin ? AppColors.error : isStudent ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isStudent || isAdmin) ...[
                  _buildEnrolledCoursesSection(t),
                ],
                const SizedBox(height: 16),
                _ProfileMenuTile(icon: Icons.person_outline, title: t.translate('editProfile'), onTap: () => context.push('/more/profile/edit')),
                if (isAdmin)
                  _ProfileMenuTile(icon: Icons.admin_panel_settings, title: t.translate('dashboard'), onTap: () => context.push('/more/dashboard'))
                else if (isStudent)
                  _ProfileMenuTile(icon: Icons.dashboard_outlined, title: t.translate('dashboard'), onTap: () => context.push('/more/dashboard')),
                _ProfileMenuTile(icon: Icons.settings_outlined, title: t.translate('settings'), onTap: () => context.push('/more/settings')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(t.translate('logout'), style: const TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _buildEnrolledCoursesSection(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.translate('myCourses') ?? 'My Courses', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_loadingCourses)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_enrolledCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(Icons.school_outlined, size: 40, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(t.translate('noCoursesFound'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(t.translate('enrollNow'), style: TextStyle(color: AppColors.textHint, fontSize: 11)),
            ]),
          )
        else
          ...List.generate(_enrolledCourses.length, (i) {
            final c = _enrolledCourses[i];
            final banner = c['banner'];
            final title = c['title'] ?? 'Untitled';
            final students = c['students'] as List? ?? [];
            final studentData = students.isNotEmpty ? students.first : null;
            final progress = studentData != null && c['videos'] != null && (c['videos'] as List).isNotEmpty
                ? ((studentData['unlockedVideo'] ?? 1) / (c['videos'] as List).length * 100).round()
                : 0;
            final isComplete = studentData?['isCourseComplete'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: banner != null && banner.toString().isNotEmpty
                        ? CachedNetworkImage(imageUrl: banner, width: 70, height: 50, fit: BoxFit.cover)
                        : Container(width: 70, height: 50, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.school, color: Colors.white, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: AppColors.surfaceVariant,
                                color: isComplete ? AppColors.success : AppColors.primary,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$progress%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isComplete ? AppColors.success : AppColors.primary)),
                        ]),
                        if (isComplete)
                          Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                            const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(t.translate('coursesCompleted'), style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ])),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

String _roleLabel(String role, AppLocalizations t) {
  switch (role) {
    case 'admin': return t.translate('dashboard') ?? 'Administrator';
    case 'teacher': return 'Teacher';
    default: return t.translate('students') ?? 'Student';
  }
}
