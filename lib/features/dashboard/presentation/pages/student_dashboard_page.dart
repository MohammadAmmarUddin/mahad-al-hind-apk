import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StudentDashboardPage extends ConsumerStatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  ConsumerState<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends ConsumerState<StudentDashboardPage> {
  List<dynamic> _enrolledCourses = [];
  int _totalCourses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; });
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final results = await Future.wait([
        ref.read(dioClientProvider).get('/api/course/getAllCourses'),
        if (user != null) ref.read(dioClientProvider).get('/api/course/getAllEnrolledCourse/${user.id}').catchError((_) => null),
      ]);

      final coursesData = results[0].data;
      List<dynamic> allCourses = [];
      if (coursesData is List) allCourses = coursesData;
      else if (coursesData is Map && coursesData['data'] is List) allCourses = coursesData['data'];

      List<dynamic> enrolled = [];
      if (results.length > 1) {
        final enrolledData = results[1].data;
        if (enrolledData is List) enrolled = enrolledData;
        else if (enrolledData is Map && enrolledData['data'] is List) enrolled = enrolledData['data'];
      }

      if (mounted) {
        setState(() {
          _enrolledCourses = enrolled;
          _totalCourses = allCourses.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, userAsync),
                      const SizedBox(height: 20),
                      _buildEnrolledCourses(context),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<dynamic> userAsync) {
    String userName = 'Student';
    userAsync.whenData((user) {
      if (user != null) userName = user.displayName;
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3D1F), Color(0xFF1B7A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assalamu Alaikum,', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCourses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('My Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Text('Browse All', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_enrolledCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('No courses enrolled yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/courses'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Browse Courses', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _enrolledCourses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final course = _enrolledCourses[index];
                final title = course['title'] ?? 'Unknown Course';
                final banner = course['banner'];
                final students = (course['students'] as List?) ?? [];
                final videos = (course['videos'] as List?) ?? [];
                final totalVideos = videos.length;
                final category = course['category'] ?? '';

                return GestureDetector(
                  onTap: () => context.push('/course/${course['_id']}'),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                              child: banner != null && banner.toString().isNotEmpty
                                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: banner, fit: BoxFit.cover))
                                  : const Icon(Icons.school, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text('${students.length} students \u2022 $totalVideos videos', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard('Enrolled', '${_enrolledCourses.length}', Icons.school_outlined, AppColors.primary),
            const SizedBox(width: 8),
            _statCard('Available', '$_totalCourses', Icons.library_books_outlined, AppColors.info),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionData(icon: Icons.school_outlined, label: 'Courses', color: AppColors.primary, route: '/courses'),
      _ActionData(icon: Icons.bar_chart_outlined, label: 'Attendance', color: AppColors.success, route: '/more/attendance'),
      _ActionData(icon: Icons.receipt_outlined, label: 'Fees', color: AppColors.info, route: '/more/fees'),
      _ActionData(icon: Icons.card_membership_outlined, label: 'Certificates', color: AppColors.accent, route: '/more/certificates'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: GestureDetector(
                onTap: () => context.push(action.route),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: action.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(action.icon, color: action.color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(action.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _ActionData({required this.icon, required this.label, required this.color, required this.route});
}
