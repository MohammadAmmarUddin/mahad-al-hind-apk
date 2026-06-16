import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _totalStudents = 0;
  int _totalCourses = 0;
  int _totalUsers = 0;
  int _totalEnrollments = 0;
  int _paidEnrollments = 0;
  double _totalRevenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() { _loading = true; });
    try {
      final results = await Future.wait([
        ref.read(dioClientProvider).get('/api/user/allUsers'),
        ref.read(dioClientProvider).get('/api/course/getAllCourses'),
      ]);

      final usersData = results[0].data;
      final coursesData = results[1].data;

      List<dynamic> users = [];
      if (usersData is List) users = usersData;
      else if (usersData is Map && usersData['data'] is List) users = usersData['data'];

      List<dynamic> courses = [];
      if (coursesData is List) courses = coursesData;
      else if (coursesData is Map && coursesData['data'] is List) courses = coursesData['data'];

      int totalStudentsCount = 0;
      int totalEnrollmentsCount = 0;
      int paidCount = 0;
      double revenue = 0;

      for (final course in courses) {
        final students = course['students'] as List? ?? [];
        totalEnrollmentsCount += students.length;
        final price = double.tryParse(course['price']?.toString() ?? '0') ?? 0;
        for (final s in students) {
          if (s['paymentComplete'] == true) {
            paidCount++;
            revenue += price;
          }
        }
      }

      totalStudentsCount = users.where((u) => u['role'] == 'student').length;

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _totalStudents = totalStudentsCount;
          _totalCourses = courses.length;
          _totalEnrollments = totalEnrollmentsCount;
          _paidEnrollments = paidCount;
          _totalRevenue = revenue;
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
        onRefresh: _fetchStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  userAsync.when(
                    data: (user) => Text(
                      user != null ? 'Welcome, ${user.displayName}' : 'Admin',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14, color: AppColors.error),
                      SizedBox(width: 4),
                      Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          _buildSectionHeader('Content Management'),
                          const SizedBox(height: 12),
                          _buildContentGrid(context),
                          const SizedBox(height: 20),
                          _buildSectionHeader('User Management'),
                          const SizedBox(height: 12),
                          _buildUserManagementGrid(context),
                          const SizedBox(height: 20),
                          _buildSectionHeader('Enrollment Overview'),
                          const SizedBox(height: 12),
                          _buildEnrollmentChart(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(title: 'Students', value: '$_totalStudents', icon: Icons.people, color: AppColors.primary),
        const SizedBox(width: 10),
        _StatCard(title: 'Courses', value: '$_totalCourses', icon: Icons.school, color: AppColors.secondary),
        const SizedBox(width: 10),
        _StatCard(title: 'Revenue', value: '\u20B9${_totalRevenue.toStringAsFixed(0)}', icon: Icons.payments, color: AppColors.accent),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$_totalUsers users \u2022 $_totalEnrollments enrollments', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildContentGrid(BuildContext context) {
    final items = [
      _AdminItem(icon: Icons.school, label: 'Courses', color: AppColors.primary, route: '/more/admin/courses'),
      _AdminItem(icon: Icons.videocam, label: 'Videos', color: AppColors.error, route: '/more/admin/videos'),
      _AdminItem(icon: Icons.headphones, label: 'Audio', color: AppColors.secondary, route: '/more/admin/audio'),
      _AdminItem(icon: Icons.photo_library, label: 'Gallery', color: AppColors.accent, route: '/more/admin/gallery'),
      _AdminItem(icon: Icons.notifications, label: 'Notifications', color: const Color(0xFF7C3AED), route: '/more/admin/notifications'),
      _AdminItem(icon: Icons.campaign, label: 'Hot News', color: AppColors.warning, route: '/more/admin/news-feed'),
      _AdminItem(icon: Icons.system_update, label: 'App Update', color: const Color(0xFFD4AF37), route: '/more/admin/app-update'),
      _AdminItem(icon: Icons.article, label: 'Site Content', color: const Color(0xFF059669), route: '/more/admin/site-content'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => context.push(item.route),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserManagementGrid(BuildContext context) {
    final items = [
      _AdminItem(icon: Icons.people, label: 'All Users', color: AppColors.primary, route: '/more/admin/users'),
      _AdminItem(icon: Icons.how_to_reg, label: 'Enrollments', color: AppColors.accent, route: '/more/admin/enrollments'),
      _AdminItem(icon: Icons.receipt_long, label: 'Payments', color: const Color(0xFF7C3AED), route: '/more/admin/payments'),
      _AdminItem(icon: Icons.workspace_premium, label: 'Certificates', color: AppColors.error, route: '/more/admin/certificates'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => context.push(item.route),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentChart() {
    final paid = _paidEnrollments.toDouble();
    final unpaid = (_totalEnrollments - _paidEnrollments).toDouble();
    final total = _totalEnrollments.toDouble();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: total == 0
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 36, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('No enrollment data yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: paid,
                          color: AppColors.success,
                          radius: 24,
                          title: '$paid',
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: unpaid > 0 ? unpaid : 0,
                          color: AppColors.warning,
                          radius: 24,
                          title: unpaid > 0 ? '$unpaid' : '',
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendDot(AppColors.success, 'Paid ($paid)'),
                    const SizedBox(height: 8),
                    _legendDot(AppColors.warning, 'Pending (${unpaid.toStringAsFixed(0)})'),
                    const SizedBox(height: 12),
                    Text('Total: ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('\u20B9${_totalRevenue.toStringAsFixed(0)} revenue', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AdminItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _AdminItem({required this.icon, required this.label, required this.color, required this.route});
}
