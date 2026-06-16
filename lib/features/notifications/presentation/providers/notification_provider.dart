import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_item.dart';

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  // Mock data - will be replaced with API
  return [
    NotificationItem(id: '1', title: 'New Course Available', body: 'Advanced Quran Recitation course is now available!', type: 'course', isRead: false, createdAt: '2024-06-10T10:00:00Z'),
    NotificationItem(id: '2', title: 'Payment Reminder', body: 'Monthly fee payment due in 3 days', type: 'payment', isRead: false, createdAt: '2024-06-09T09:00:00Z'),
    NotificationItem(id: '3', title: 'Certificate Ready', body: 'Your Quran Recitation Level 1 certificate is ready', type: 'certificate', isRead: true, createdAt: '2024-06-08T14:00:00Z'),
    NotificationItem(id: '4', title: 'Class Schedule Updated', body: 'Bayan class timing changed to 7:00 PM', type: 'info', isRead: true, createdAt: '2024-06-07T11:00:00Z'),
  ];
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.whenData((list) => list.where((n) => n.isRead != true).length).valueOrNull ?? 0;
});
