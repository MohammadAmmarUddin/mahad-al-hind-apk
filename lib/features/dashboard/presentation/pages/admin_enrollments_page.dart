import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminEnrollmentsPage extends ConsumerStatefulWidget {
  const AdminEnrollmentsPage({super.key});
  @override
  ConsumerState<AdminEnrollmentsPage> createState() => _AdminEnrollmentsPageState();
}

class _AdminEnrollmentsPageState extends ConsumerState<AdminEnrollmentsPage> {
  List<Map<String, dynamic>> _enrollments = [];
  List<dynamic> _courses = [];
  List<dynamic> _users = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'All';

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
      final courses = (coursesData is List) ? coursesData : <dynamic>[];

      final enrollments = <Map<String, dynamic>>[];
      for (final course in courses) {
        final students = course['students'] as List? ?? [];
        for (final s in students) {
          enrollments.add({
            'courseId': course['_id'],
            'courseTitle': course['title'] ?? 'Unknown Course',
            'coursePrice': course['price'] ?? '0',
            'studentId': s['studentsId'] ?? '',
            'paymentId': s['paymentId'] ?? '',
            'paymentComplete': s['paymentComplete'] ?? false,
            'unlockedVideo': s['unlockedVideo'] ?? 0,
            'isCourseComplete': s['isCourseComplete'] ?? false,
            'isQuizComplete': s['isQuizComplete'] ?? false,
            'quizMarks': s['quizMarks'] ?? 0,
            'quizMarksPercentage': s['quizMarksPercentage'] ?? 0,
            'certificateUrl': s['certificateUrl'] ?? '',
            'enrollmentId': s['_id'] ?? '',
          });
        }
      }

      setState(() {
        _courses = courses;
        _enrollments = enrollments;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _enrollments;
    if (_filter == 'Completed') list = list.where((e) => e['isCourseComplete'] == true).toList();
    if (_filter == 'In Progress') list = list.where((e) => e['isCourseComplete'] != true).toList();
    if (_filter == 'Quiz Done') list = list.where((e) => e['isQuizComplete'] == true).toList();
    if (_filter == 'Paid') list = list.where((e) => e['paymentComplete'] == true).toList();
    if (_search.isNotEmpty) {
      list = list.where((e) =>
        (e['courseTitle'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (e['studentId'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    return list;
  }

  void _showEnrollmentDetail(Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                CircleAvatar(radius: 22, backgroundColor: AppColors.primarySurface, child: Icon(Icons.person, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Student: ${e['studentId']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(e['courseTitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 20),
              _detailRow('Payment Status', e['paymentComplete'] == true ? 'Paid' : 'Pending', e['paymentComplete'] == true ? AppColors.success : AppColors.warning),
              _detailRow('Course Progress', e['isCourseComplete'] == true ? 'Completed' : 'In Progress', e['isCourseComplete'] == true ? AppColors.success : AppColors.info),
              _detailRow('Quiz Status', e['isQuizComplete'] == true ? 'Completed' : 'Not Done', e['isQuizComplete'] == true ? AppColors.success : AppColors.textHint),
              _detailRow('Quiz Marks', '${e['quizMarks']} (${e['quizMarksPercentage']}%)', AppColors.accent),
              _detailRow('Videos Unlocked', '${e['unlockedVideo']}', AppColors.secondary),
              if ((e['certificateUrl'] ?? '').toString().isNotEmpty)
                _detailRow('Certificate', e['certificateUrl'], AppColors.primary),
              const SizedBox(height: 20),
              const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _togglePayment(e); },
                  icon: Icon(e['paymentComplete'] == true ? Icons.payment : Icons.check_circle, size: 16),
                  label: Text(e['paymentComplete'] == true ? 'Mark Unpaid' : 'Mark Paid'),
                  style: OutlinedButton.styleFrom(foregroundColor: e['paymentComplete'] == true ? AppColors.warning : AppColors.success),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _toggleCourseComplete(e); },
                  icon: Icon(e['isCourseComplete'] == true ? Icons.undo : Icons.check_circle_outline, size: 16),
                  label: Text(e['isCourseComplete'] == true ? 'Mark Incomplete' : 'Mark Complete'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                )),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _removeEnrollment(e); },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove Enrollment'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
  }

  Future<void> _togglePayment(Map<String, dynamic> e) async {
    final newStatus = !(e['paymentComplete'] == true);
    try {
      await ref.read(dioClientProvider).patch(
        '/api/course/${e['courseId']}',
        data: {
          'students': [
            {
              'studentsId': e['studentId'],
              'paymentComplete': newStatus,
              'unlockedVideo': e['unlockedVideo'],
              'isCourseComplete': e['isCourseComplete'],
            }
          ],
        },
      );
      setState(() { e['paymentComplete'] = newStatus; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus ? 'Marked as Paid' : 'Marked as Unpaid'), backgroundColor: AppColors.success));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _toggleCourseComplete(Map<String, dynamic> e) async {
    final newStatus = !(e['isCourseComplete'] == true);
    try {
      await ref.read(dioClientProvider).patch(
        '/api/course/${e['courseId']}',
        data: {
          'students': [
            {
              'studentsId': e['studentId'],
              'paymentComplete': e['paymentComplete'],
              'unlockedVideo': e['unlockedVideo'],
              'isCourseComplete': newStatus,
            }
          ],
        },
      );
      setState(() { e['isCourseComplete'] = newStatus; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus ? 'Marked as Complete' : 'Marked as Incomplete'), backgroundColor: AppColors.success));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error));
    }
  }

  void _showManualEnrollDialog() {
    String? selectedCourse;
    final studentIdCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Manual Enrollment'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: InputDecoration(
                    labelText: 'Course *',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _courses.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                    value: c['_id'],
                    child: Text(c['title'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCourse = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Student ID *',
                    hintText: 'Enter student user ID',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: loading ? null : () async {
                if (selectedCourse == null || studentIdCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course and Student ID are required'), backgroundColor: AppColors.error));
                  return;
                }
                setDialogState(() => loading = true);
                try {
                  await ref.read(dioClientProvider).post('/api/course/manual-enroll', data: {
                    'courseId': selectedCourse,
                    'studentId': studentIdCtrl.text.trim(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled successfully'), backgroundColor: AppColors.success));
                    _fetchAll();
                  }
                } catch (err) {
                  setDialogState(() => loading = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error));
                }
              },
              icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add, size: 16),
              label: Text(loading ? 'Enrolling...' : 'Enroll'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeEnrollment(Map<String, dynamic> e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Enrollment'),
        content: const Text('This will remove the student from this course. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      setState(() { _enrollments.remove(e); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrollment removed'), backgroundColor: AppColors.success));
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Enrollments'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualEnrollDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Manual Enroll', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by course or student...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'In Progress', 'Completed', 'Paid', 'Quiz Done'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textPrimary)),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.how_to_reg, size: 64, color: AppColors.textHint),
                        SizedBox(height: 16),
                        Text('No enrollments found', style: TextStyle(color: AppColors.textSecondary)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _fetchAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final e = filtered[i];
                            final complete = e['isCourseComplete'] == true;
                            final paid = e['paymentComplete'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _showEnrollmentDetail(e),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: complete ? AppColors.success.withOpacity(0.1) : AppColors.primarySurface,
                                  child: Icon(complete ? Icons.check_circle : Icons.school, color: complete ? AppColors.success : AppColors.primary, size: 20),
                                ),
                                title: Text(e['courseTitle'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: paid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(paid ? 'Paid' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: paid ? AppColors.success : AppColors.warning)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Quiz: ${e['quizMarksPercentage']}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(width: 6),
                                  Text('Videos: ${e['unlockedVideo']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ]),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.info_outline, size: 16), SizedBox(width: 8), Text('Details')])),
                                    const PopupMenuItem(value: 'toggle_payment', child: Row(children: [Icon(Icons.payment, size: 16), SizedBox(width: 8), Text('Toggle Payment')])),
                                    const PopupMenuItem(value: 'toggle_complete', child: Row(children: [Icon(Icons.check_circle_outline, size: 16), SizedBox(width: 8), Text('Toggle Complete')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Remove', style: TextStyle(color: AppColors.error))])),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'detail') _showEnrollmentDetail(e);
                                    else if (val == 'toggle_payment') _togglePayment(e);
                                    else if (val == 'toggle_complete') _toggleCourseComplete(e);
                                    else if (val == 'delete') _removeEnrollment(e);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
