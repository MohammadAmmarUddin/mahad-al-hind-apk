import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeesPage extends ConsumerStatefulWidget {
  const FeesPage({super.key});

  @override
  ConsumerState<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends ConsumerState<FeesPage> {
  List<dynamic> _enrolledCourses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFees();
  }

  Future<void> _fetchFees() async {
    setState(() { _loading = true; });
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        if (mounted) setState(() { _loading = false; });
        return;
      }
      final res = await ref.read(dioClientProvider).get('/api/course/getAllEnrolledCourse/${user.id}');
      final data = res.data;
      List<dynamic> courses = [];
      if (data is List) courses = data;
      else if (data is Map && data['data'] is List) courses = data['data'];
      if (mounted) setState(() { _enrolledCourses = courses; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPaid = 0;
    double totalDue = 0;
    for (final c in _enrolledCourses) {
      final price = double.tryParse(c['price']?.toString() ?? '0') ?? 0;
      final paid = c['students'] is List
          ? (c['students'] as List).where((s) => s['paymentComplete'] == true).length
          : 0;
      if (paid > 0) {
        totalPaid += price;
      } else {
        totalDue += price;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Management')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _enrolledCourses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text('No fee records yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Enroll in a course to see fee details', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/courses'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Browse Courses', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchFees,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A3D1F), Color(0xFF1B7A3D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text('Fee Summary', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              '\u20B9${totalDue.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Total Due', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(children: [
                                  Text('\u20B9${totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                                  Text('Paid', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                ]),
                                Column(children: [
                                  Text('\u20B9${totalDue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                                  Text('Pending', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Course Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._enrolledCourses.map((c) {
                        final title = c['title'] ?? 'Unknown';
                        final price = double.tryParse(c['price']?.toString() ?? '0') ?? 0;
                        final discount = double.tryParse(c['discount']?.toString() ?? '0') ?? 0;
                        final finalPrice = discount > 0 ? price - (price * discount / 100) : price;
                        final students = c['students'] as List? ?? [];
                        final isPaid = students.any((s) => s['paymentComplete'] == true);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(isPaid ? Icons.check_circle : Icons.pending, color: isPaid ? AppColors.success : AppColors.warning, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('\u20B9${finalPrice.toStringAsFixed(0)}${discount > 0 ? ' (${discount.toStringAsFixed(0)}% off)' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(fontSize: 12, color: isPaid ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
