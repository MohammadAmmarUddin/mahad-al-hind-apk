import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminEnrollmentsPage extends ConsumerStatefulWidget {
  const AdminEnrollmentsPage({super.key});
  @override
  ConsumerState<AdminEnrollmentsPage> createState() => _AdminEnrollmentsPageState();
}

class _AdminEnrollmentsPageState extends ConsumerState<AdminEnrollmentsPage> {
  List<Map<String, dynamic>> _enrollments = [];
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
      final dio = ref.read(dioClientProvider);
      await dio.ensureTokenLoaded();
      final response = await dio.get('/api/course/all-enrollments');
      final data = response.data;
      final list = (data is List) ? data : <dynamic>[];

      final enrollments = <Map<String, dynamic>>[];
      for (final item in list) {
        final course = item['courseId'];
        final student = item['studentsId'];
        enrollments.add({
          'tranId': item['tranId'] ?? '',
          'sessionId': item['_id'] ?? '',
          'courseId': course is Map ? course['_id'] ?? '' : '',
          'courseTitle': course is Map ? course['title'] ?? 'Unknown' : 'Unknown',
          'coursePrice': course is Map ? course['price'] ?? '0' : '0',
          'studentId': student is Map ? student['_id'] ?? '' : '',
          'studentName': student is Map ? '${student['firstname'] ?? ''} ${student['lastname'] ?? ''}'.trim() : 'Unknown',
          'studentEmail': student is Map ? student['email'] ?? '' : '',
          'payment': item['payment'] ?? '0',
          'paymentMethod': item['paymentMethod'] ?? '',
          'paymentNumber': item['paymentNumber'] ?? '',
          'manualTransactionId': item['manualTransactionId'] ?? '',
          'status': item['status'] ?? 'pending',
          'paymentComplete': item['paymentComplete'] ?? false,
          'notes': item['notes'] ?? '',
          'createdAt': item['createdAt'] ?? '',
        });
      }

      setState(() {
        _enrollments = enrollments;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _enrollments;
    if (_filter == 'Pending') list = list.where((e) => e['status'] == 'pending').toList();
    if (_filter == 'Approved') list = list.where((e) => e['status'] == 'approved').toList();
    if (_filter == 'Rejected') list = list.where((e) => e['status'] == 'rejected').toList();
    if (_search.isNotEmpty) {
      list = list.where((e) =>
        (e['courseTitle'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (e['studentName'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (e['studentEmail'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (e['tranId'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    return list;
  }

  Future<void> _approveEnrollment(Map<String, dynamic> e) async {
    final tranId = e['tranId'];
    if (tranId == null || tranId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transaction ID found'), backgroundColor: AppColors.error));
      return;
    }

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/api/course/approve-enrollment/$tranId');
      setState(() {
        e['status'] = 'approved';
        e['paymentComplete'] = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrollment approved for ${e['studentName']}'), backgroundColor: AppColors.success));
      }
    } catch (err) {
      final msg = err.toString().contains('Exception:') ? err.toString().replaceFirst('Exception: ', '') : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _rejectEnrollment(Map<String, dynamic> e) async {
    final tranId = e['tranId'];
    if (tranId == null || tranId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transaction ID found'), backgroundColor: AppColors.error));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Enrollment'),
        content: Text("Reject ${e['studentName']}'s enrollment in \"${e['courseTitle']}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/api/course/reject-enrollment/$tranId');
      setState(() {
        e['status'] = 'rejected';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrollment rejected'), backgroundColor: AppColors.success));
      }
    } catch (err) {
      final msg = err.toString().contains('Exception:') ? err.toString().replaceFirst('Exception: ', '') : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _markCourseComplete(Map<String, dynamic> e) async {
    final courseId = e['courseId'];
    final studentId = e['studentId'];
    if (courseId.toString().isEmpty || studentId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing course or student ID'), backgroundColor: AppColors.error));
      return;
    }

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/api/course/completeCourse/$studentId', data: {'_id': courseId});
      setState(() { e['status'] = 'approved'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Course marked as complete for ${e['studentName']}'), backgroundColor: AppColors.success));
      }
    } catch (err) {
      final msg = err.toString().contains('Exception:') ? err.toString().replaceFirst('Exception: ', '') : err.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showEnrollmentDetail(Map<String, dynamic> e) {
    final isPending = e['status'] == 'pending';
    final isApproved = e['status'] == 'approved';

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
                  Text(e['studentName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(e['studentEmail'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 20),
              _detailRow('Course', e['courseTitle'] ?? '', AppColors.primary),
              _detailRow('Amount', '\u20B9${e['payment']}', AppColors.accent),
              _detailRow('Payment Method', e['paymentMethod'] ?? 'N/A', AppColors.info),
              _detailRow('Transaction ID', e['manualTransactionId'] ?? 'N/A', AppColors.secondary),
              _detailRow('Payment Number', e['paymentNumber'] ?? 'N/A', AppColors.secondary),
              _detailRow('Status', e['status'] ?? 'pending', e['status'] == 'approved' ? AppColors.success : e['status'] == 'rejected' ? AppColors.error : AppColors.warning),
              _detailRow('Tran ID', e['tranId'] ?? '', AppColors.textHint),
              if ((e['notes'] ?? '').toString().isNotEmpty)
                _detailRow('Notes', e['notes'], AppColors.textSecondary),
              if ((e['createdAt'] ?? '').toString().isNotEmpty)
                _detailRow('Date', e['createdAt'].toString().substring(0, 19), AppColors.textSecondary),
              const SizedBox(height: 20),
              if (isPending) ...[
                const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _approveEnrollment(e); },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _rejectEnrollment(e); },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  )),
                ]),
              ],
              if (isApproved) ...[
                const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _markCourseComplete(e); },
                    icon: const Icon(Icons.emoji_events, size: 18),
                    label: const Text('Mark Course Complete'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
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
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          const SizedBox(width: 8),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 2, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Enrollments'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by course, student, or tran ID...',
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
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((f) {
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
                            final status = e['status'] ?? 'pending';
                            final statusColor = _statusColor(status);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _showEnrollmentDetail(e),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: statusColor.withOpacity(0.1),
                                  child: Icon(
                                    status == 'approved' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.pending,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(e['courseTitle'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(e['studentName'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Text('\u20B9${e['payment']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                ]),
                                trailing: status == 'pending'
                                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                                          tooltip: 'Approve',
                                          onPressed: () => _approveEnrollment(e),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: AppColors.error, size: 22),
                                          tooltip: 'Reject',
                                          onPressed: () => _rejectEnrollment(e),
                                        ),
                                      ])
                                    : IconButton(
                                        icon: const Icon(Icons.info_outline, size: 22),
                                        onPressed: () => _showEnrollmentDetail(e),
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
