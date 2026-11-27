import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// Notifications from the bell on Home: Today and Earlier, a gold dot on unread ones.
/// Tapping one marks it read, closes this screen and hands the kind to [onOpen].
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.items, required this.onOpen});

  final List<NotificationItem> items;
  final ValueChanged<String> onOpen;

  static IconData _icon(String kind) => switch (kind) {
        'sermon' => Icons.play_circle_outline_rounded,
        'prayer' => Icons.favorite_border_rounded,
        'reading' => Icons.menu_book_outlined,
        'service' => Icons.church_outlined,
        _ => Icons.calendar_today_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final unread = items.where((n) => !state.readNotifications.contains(n.id)).toList();
    final now = DateTime.now();
    bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    final today = items.where((n) => isToday(n.at)).toList();
    final earlier = items.where((n) => !isToday(n.at)).toList();

    Widget tile(NotificationItem n) {
      final isUnread = !state.readNotifications.contains(n.id);
      return HairlineRow(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
          child: Icon(_icon(n.kind), size: 20, color: t.colorScheme.primary),
        ),
        title: n.title,
        titleStyle: t.textTheme.bodyMedium?.copyWith(fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400),
        subtitle: '${n.detail} · ${timeAgo(n.at)}',
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: isUnread ? BethelColors.brass : Colors.transparent, shape: BoxShape.circle),
        ),
        onTap: () {
          state.markNotificationsRead([n.id]);
          Navigator.pop(context);
          onOpen(n.kind);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              onPressed: () => state.markNotificationsRead(unread.map((n) => n.id)),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? const BethelEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'You’re all caught up',
              message: 'Service reminders, new messages and prayer updates show up here',
            )
          : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
              if (today.isNotEmpty) ...[const BethelSectionTitle('Today'), ...today.map(tile), const SizedBox(height: 20)],
              if (earlier.isNotEmpty) ...[const BethelSectionTitle('Earlier'), ...earlier.map(tile)],
            ]),
    );
  }
}
