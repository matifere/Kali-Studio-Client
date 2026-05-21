import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        type: m['type'] as String? ?? 'general',
        isRead: m['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationService {
  static final _supabase = Supabase.instance.client;

  static Future<List<AppNotification>> fetchNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from('notifications')
          .select('id, title, body, type, is_read, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('NotificationService.fetchNotifications error: $e');
      return [];
    }
  }

  static Future<int> fetchUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e) {
      debugPrint('NotificationService.fetchUnreadCount error: $e');
      return 0;
    }
  }

  static Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('NotificationService.markAsRead error: $e');
    }
  }

  static Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('NotificationService.markAllAsRead error: $e');
    }
  }

  static RealtimeChannel subscribeToNotifications({
    required String userId,
    required void Function(AppNotification) onNew,
  }) {
    return _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = AppNotification.fromMap(payload.newRecord);
            onNew(notification);
          },
        )
        .subscribe();
  }
}
