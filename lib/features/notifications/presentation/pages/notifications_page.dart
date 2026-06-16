import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('No notifications yet'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                title: notification.title ?? '',
                body: notification.body ?? '',
                time: notification.createdAt ?? '',
                isRead: notification.isRead ?? false,
                type: notification.type ?? 'info',
                onTap: () {},
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String type;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case 'course': return Icons.school;
      case 'payment': return Icons.payment;
      case 'certificate': return Icons.workspace_premium;
      default: return Icons.info;
    }
  }

  Color _getColor() {
    switch (type) {
      case 'course': return AppColors.primary;
      case 'payment': return AppColors.warning;
      case 'certificate': return AppColors.success;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.primarySurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getIcon(), color: _getColor(), size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.w600)),
        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        trailing: !isRead ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
        onTap: onTap,
      ),
    );
  }
}
