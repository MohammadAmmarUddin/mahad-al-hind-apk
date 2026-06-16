import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminCertificatesPage extends ConsumerStatefulWidget {
  const AdminCertificatesPage({super.key});
  @override
  ConsumerState<AdminCertificatesPage> createState() => _AdminCertificatesPageState();
}

class _AdminCertificatesPageState extends ConsumerState<AdminCertificatesPage> {
  List<dynamic> _certificates = [];
  List<dynamic> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; });
    try {
      final results = await Future.wait([
        ref.read(dioClientProvider).get('/api/course/getAllCourses'),
      ]);

      final coursesData = results[0].data;
      List<dynamic> courses = [];
      if (coursesData is List) courses = coursesData;
      else if (coursesData is Map && coursesData['data'] is List) courses = coursesData['data'];

      final certs = <Map<String, dynamic>>[];
      for (final course in courses) {
        final students = course['students'] as List? ?? [];
        for (final s in students) {
          if (s['certificateUrl'] != null && (s['certificateUrl'] as String).isNotEmpty) {
            certs.add({
              'courseTitle': course['title'] ?? 'Unknown',
              'studentId': s['studentsId'] ?? '',
              'certificateUrl': s['certificateUrl'],
              'courseId': course['_id'],
              'isCourseComplete': s['isCourseComplete'] ?? false,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _certificates = certs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Certificates'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _certificates.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.workspace_premium_outlined, size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text('No certificates issued yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Certificates appear here when students complete courses', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _certificates.length,
                    itemBuilder: (ctx, i) {
                      final c = _certificates[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 28),
                          ),
                          title: Text(c['studentId'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['courseTitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(c['certificateUrl'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.share, color: AppColors.primary),
                            onPressed: () => Share.share('Certificate: ${c['certificateUrl']}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
