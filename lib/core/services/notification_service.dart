import 'dart:async';
import '../network/dio_client.dart';
import '../network/api_endpoints.dart';
import '../storage/secure_storage.dart';

class NotificationService {
  final DioClient _dioClient;
  final SecureStorage _secureStorage;

  NotificationService({required DioClient dioClient, required SecureStorage secureStorage})
      : _dioClient = dioClient, _secureStorage = secureStorage;

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.unreadCount);
      return response.data['data'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dioClient.patch(ApiEndpoints.readNotification(id));
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.patch(ApiEndpoints.readAllNotifications);
    } catch (_) {}
  }
}
