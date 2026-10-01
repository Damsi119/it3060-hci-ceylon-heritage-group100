import '../models/notification_item.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final ApiClient _api = ApiClient.instance;

  Future<List<NotificationItem>> getNotifications() async {
    final data = await _api.get('/api/notifications') as Map<String, dynamic>;
    final items = data['notifications'] as List<dynamic>? ?? const [];
    return items
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _api.put('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.put('/api/notifications/read-all');
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/notifications/$id');
  }
}
