import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase/notification_service.dart';
import '../theme/kali_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final notifications = await NotificationService.fetchNotifications();
    await NotificationService.markAllAsRead();
    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaliColors.warmWhite,
      appBar: AppBar(
        backgroundColor: KaliColors.warmWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notificaciones',
          style: KaliText.body(KaliColors.espresso, size: 15, weight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: KaliColors.sand2, thickness: 1, height: 1),
        ),
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 48, color: KaliColors.sand2),
                  const SizedBox(height: 12),
                  Text(
                    'Sin notificaciones',
                    style: KaliText.body(KaliColors.clayDark, size: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                Divider(color: KaliColors.sand2, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData _iconForType(String type) {
    switch (type) {
      case 'reserva':
        return Icons.calendar_today_rounded;
      case 'plan':
        return Icons.card_membership_rounded;
      case 'waitlist':
        return Icons.list_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('d MMM · HH:mm', 'es').format(notification.createdAt.toLocal());

    return Container(
      color: notification.isRead ? Colors.transparent : KaliColors.sand.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KaliColors.espresso,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(notification.type),
                size: 18, color: KaliColors.warmWhite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: KaliText.body(KaliColors.espresso,
                      size: 13, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: KaliText.body(KaliColors.clayDark, size: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: KaliText.body(KaliColors.clayDark, size: 11),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: KaliColors.espresso,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
