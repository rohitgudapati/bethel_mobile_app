/// One notification to show at a time on this phone.
class PlannedNotification {
  const PlannedNotification({required this.id, required this.when, required this.title, required this.body, this.route});
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// Where tapping it should go, e.g. "plan".
  final String? route;

  @override
  String toString() => '$id @ $when: $title — $body';
}

/// Notifications on this phone. The reading plan schedules its reminders through this.
///
/// Two kinds will plug in here:
/// - Local notifications the app schedules itself (reading-plan reminders). They need no server.
/// - Push messages the church sends through Firebase Cloud Messaging (new sermon, prayer updates).
///
/// Until those packages are added (see docs/firebase-setup.md), the app uses
/// [RecordingNotificationService], which keeps the schedule so it can be shown and tested.
abstract class NotificationService {
  /// Asks the person for permission. Returns whether notifications are allowed.
  Future<bool> requestPermission();

  /// Replaces every notification in [group] with [items].
  Future<void> replaceGroup(String group, List<PlannedNotification> items);

  /// The push token for this phone, once Firebase Cloud Messaging is set up.
  Future<String?> pushToken() async => null;
}

/// Keeps the planned notifications in memory and shows none. Used until the notification
/// packages are added, and in tests.
class RecordingNotificationService implements NotificationService {
  final Map<String, List<PlannedNotification>> groups = {};
  bool permission = false;

  @override
  Future<bool> requestPermission() async => permission = true;

  @override
  Future<void> replaceGroup(String group, List<PlannedNotification> items) async {
    groups[group] = List.unmodifiable(items);
  }

  @override
  Future<String?> pushToken() async => null;

  List<PlannedNotification> get all => [for (final g in groups.values) ...g]..sort((a, b) => a.when.compareTo(b.when));
}
