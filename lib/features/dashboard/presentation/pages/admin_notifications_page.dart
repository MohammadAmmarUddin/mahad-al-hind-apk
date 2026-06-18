import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/core_providers.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});
  @override
  ConsumerState<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends ConsumerState<AdminNotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _loading = true; });
    try {
      final res = await ref.read(dioClientProvider).get('/api/notifications');
      final data = res.data;
      setState(() {
        _notifications = (data is List) ? data : (data is Map && data['data'] is List ? data['data'] : []);
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  void _showCreateDialog() {
    String type = 'general';
    String role = 'all';
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Notification'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['general', 'enrollment_request', 'enrollment_approved', 'course_completed', 'payment_received', 'new_signup']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => type = v); },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['all', 'admin', 'student'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => role = v); },
                  decoration: const InputDecoration(labelText: 'Target Role'),
                ),
                const SizedBox(height: 8),
                TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Message')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
            onPressed: () async {
              if (msgCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message is required'), backgroundColor: AppColors.error));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref.read(dioClientProvider).post('/api/notifications/create', data: {
                  'type': type,
                  'role': role,
                  'message': msgCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent!'), backgroundColor: AppColors.success));
                  _fetchNotifications();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notifications'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchNotifications),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i];
                    final read = n['read'] ?? false;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: read ? null : AppColors.primarySurface.withOpacity(0.3),
                      child: ListTile(
                        leading: Icon(
                          n['type'] == 'enrollment_request' ? Icons.how_to_reg : Icons.notifications,
                          color: read ? AppColors.textHint : AppColors.primary,
                        ),
                        title: Text(n['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(n['type'] ?? '', style: const TextStyle(fontSize: 11)),
                        trailing: !read
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
