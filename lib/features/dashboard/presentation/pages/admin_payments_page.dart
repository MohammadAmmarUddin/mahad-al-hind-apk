import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminPaymentsPage extends ConsumerStatefulWidget {
  const AdminPaymentsPage({super.key});
  @override
  ConsumerState<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends ConsumerState<AdminPaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
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
        ref.read(dioClientProvider).get('/api/user/allUsers'),
      ]);

      final coursesData = results[0].data;
      final usersData = results[1].data;

      List<dynamic> courses = [];
      if (coursesData is List) courses = coursesData;
      else if (coursesData is Map && coursesData['data'] is List) courses = coursesData['data'];

      List<dynamic> users = [];
      if (usersData is List) users = usersData;
      else if (usersData is Map && usersData['data'] is List) users = usersData['data'];

      final payments = <Map<String, dynamic>>[];
      for (final course in courses) {
        final price = double.tryParse(course['price']?.toString() ?? '0') ?? 0;
        final discount = double.tryParse(course['discount']?.toString() ?? '0') ?? 0;
        final finalPrice = discount > 0 ? price - (price * discount / 100) : price;
        final students = course['students'] as List? ?? [];
        for (final s in students) {
          final studentId = s['studentsId'] ?? '';
          final studentUser = users.firstWhere(
            (u) => u['_id'] == studentId,
            orElse: () => null,
          );
          final name = studentUser != null
              ? '${studentUser['firstname'] ?? ''} ${studentUser['lastname'] ?? ''}'.trim()
              : studentId;
          payments.add({
            'courseId': course['_id'],
            'courseTitle': course['title'] ?? 'Unknown',
            'coursePrice': price,
            'discount': discount,
            'finalPrice': finalPrice,
            'studentId': studentId,
            'studentName': name.isNotEmpty ? name : studentId,
            'paymentComplete': s['paymentComplete'] ?? false,
            'enrollmentId': s['_id'] ?? '',
            'unlockedVideo': s['unlockedVideo'] ?? 0,
            'isCourseComplete': s['isCourseComplete'] ?? false,
          });
        }
      }

      setState(() {
        _courses = courses;
        _users = users;
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _payments;
    if (_filter == 'Paid') list = list.where((e) => e['paymentComplete'] == true).toList();
    if (_filter == 'Pending') list = list.where((e) => e['paymentComplete'] != true).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
        (e['studentName'] ?? '').toString().toLowerCase().contains(q) ||
        (e['courseTitle'] ?? '').toString().toLowerCase().contains(q) ||
        (e['studentId'] ?? '').toString().toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  double get _totalRevenue => _payments.where((e) => e['paymentComplete'] == true).fold(0, (sum, e) => sum + (e['finalPrice'] ?? 0));
  double get _pendingRevenue => _payments.where((e) => e['paymentComplete'] != true).fold(0, (sum, e) => sum + (e['finalPrice'] ?? 0));

  void _showPaymentDetail(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: p['paymentComplete'] == true ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                  child: Icon(p['paymentComplete'] == true ? Icons.check_circle : Icons.pending, color: p['paymentComplete'] == true ? AppColors.success : AppColors.warning, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['studentName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(p['courseTitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
              const SizedBox(height: 20),
              _detailRow('Payment Status', p['paymentComplete'] == true ? 'Paid' : 'Pending', p['paymentComplete'] == true ? AppColors.success : AppColors.warning),
              _detailRow('Course Price', '\u20B9${p['coursePrice']?.toStringAsFixed(0) ?? '0'}', AppColors.primary),
              if ((p['discount'] ?? 0) > 0)
                _detailRow('Discount', '${p['discount']}%', AppColors.accent),
              _detailRow('Final Amount', '\u20B9${p['finalPrice']?.toStringAsFixed(0) ?? '0'}', AppColors.primary),
              _detailRow('Videos Unlocked', '${p['unlockedVideo']}', AppColors.secondary),
              _detailRow('Course Status', p['isCourseComplete'] == true ? 'Completed' : 'In Progress', p['isCourseComplete'] == true ? AppColors.success : AppColors.info),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _togglePayment(p); },
                  icon: Icon(p['paymentComplete'] == true ? Icons.money_off : Icons.check_circle, size: 16),
                  label: Text(p['paymentComplete'] == true ? 'Mark Unpaid' : 'Mark Paid'),
                  style: OutlinedButton.styleFrom(foregroundColor: p['paymentComplete'] == true ? AppColors.warning : AppColors.success),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _editAmount(p); },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Amount'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                )),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _deletePayment(p); },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove Record'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
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

  Future<void> _togglePayment(Map<String, dynamic> p) async {
    final newStatus = !(p['paymentComplete'] == true);
    try {
      await ref.read(dioClientProvider).patch(
        '/api/course/${p['courseId']}',
        data: {
          'students': [
            {
              'studentsId': p['studentId'],
              'paymentComplete': newStatus,
              'unlockedVideo': p['unlockedVideo'],
              'isCourseComplete': p['isCourseComplete'],
            }
          ],
        },
      );
      setState(() { p['paymentComplete'] = newStatus; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus ? 'Marked as Paid' : 'Marked as Unpaid'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _editAmount(Map<String, dynamic> p) {
    final priceCtrl = TextEditingController(text: p['coursePrice']?.toString() ?? '0');
    final discountCtrl = TextEditingController(text: p['discount']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Payment'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${p['studentName']}\n${p['courseTitle']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Course Price (\u20B9)', prefixIcon: Icon(Icons.attach_money, size: 20)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount (%)', prefixIcon: Icon(Icons.percent, size: 20)),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: priceCtrl,
                  builder: (_, priceVal, __) {
                    final price = double.tryParse(priceVal.text) ?? 0;
                    final disc = double.tryParse(discountCtrl.text) ?? 0;
                    final final_ = disc > 0 ? price - (price * disc / 100) : price;
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Final Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('\u20B9${final_.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final newPrice = priceCtrl.text.trim();
                  final newDiscount = discountCtrl.text.trim();
                  await ref.read(dioClientProvider).patch(
                    '/api/course/${p['courseId']}',
                    data: {
                      'price': newPrice,
                      'discount': newDiscount,
                      'students': [
                        {
                          'studentsId': p['studentId'],
                          'paymentComplete': p['paymentComplete'],
                          'unlockedVideo': p['unlockedVideo'],
                          'isCourseComplete': p['isCourseComplete'],
                        }
                      ],
                    },
                  );
                  setState(() {
                    p['coursePrice'] = double.tryParse(newPrice) ?? 0;
                    p['discount'] = double.tryParse(newDiscount) ?? 0;
                    final fp = p['discount'] > 0 ? p['coursePrice'] - (p['coursePrice'] * p['discount'] / 100) : p['coursePrice'];
                    p['finalPrice'] = fp;
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment updated'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePayment(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Record'),
        content: Text("Remove ${p['studentName']}'s enrollment from ${p['courseTitle']}? This will unenroll them."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final course = _courses.firstWhere((c) => c['_id'] == p['courseId'], orElse: () => null);
                if (course != null) {
                  final students = (course['students'] as List? ?? [])
                      .where((s) => s['studentsId'] != p['studentId'])
                      .toList();
                  await ref.read(dioClientProvider).patch(
                    '/api/course/${p['courseId']}',
                    data: {'students': students},
                  );
                }
                setState(() { _payments.remove(p); });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment record removed'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Remove'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _summaryItem('Paid', '\u20B9${_totalRevenue.toStringAsFixed(0)}', AppColors.success),
                Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
                _summaryItem('Pending', '\u20B9${_pendingRevenue.toStringAsFixed(0)}', AppColors.warning),
                Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
                _summaryItem('Records', '${_payments.length}', Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by student or course...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'Paid', 'Pending'].map((f) {
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
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                        SizedBox(height: 16),
                        Text('No payment records', style: TextStyle(color: AppColors.textSecondary)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _fetchAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = filtered[i];
                            final paid = p['paymentComplete'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => _showPaymentDetail(p),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: paid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                  child: Icon(paid ? Icons.check_circle : Icons.pending, color: paid ? AppColors.success : AppColors.warning, size: 20),
                                ),
                                title: Text(p['studentName'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: paid ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(paid ? 'Paid' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: paid ? AppColors.success : AppColors.warning)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(p['courseTitle'] ?? '', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('\u20B9${p['finalPrice']?.toStringAsFixed(0) ?? '0'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: paid ? AppColors.success : AppColors.primary)),
                                    const SizedBox(width: 4),
                                    PopupMenuButton(
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.info_outline, size: 16), SizedBox(width: 8), Text('Details')])),
                                        PopupMenuItem(
                                          value: 'toggle',
                                          child: Row(children: [
                                            Icon(paid ? Icons.money_off : Icons.check_circle, size: 16, color: paid ? AppColors.warning : AppColors.success),
                                            SizedBox(width: 8),
                                            Text(paid ? 'Mark Unpaid' : 'Mark Paid'),
                                          ]),
                                        ),
                                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit Amount')])),
                                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Remove', style: TextStyle(color: AppColors.error))])),
                                      ],
                                      onSelected: (val) {
                                        if (val == 'detail') _showPaymentDetail(p);
                                        else if (val == 'toggle') _togglePayment(p);
                                        else if (val == 'edit') _editAmount(p);
                                        else if (val == 'delete') _deletePayment(p);
                                      },
                                    ),
                                  ],
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

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}
