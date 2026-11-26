import '../notifications/notification_service.dart';
import 'plan_messages.dart';
import 'reading_plan.dart';

/// What the member asked to be reminded about.
class ReminderPrefs {
  const ReminderPrefs({this.morning = true, this.morningHour = 7, this.morningMinute = 0, this.partway = true, this.streak = true});
  final bool morning;
  final int morningHour;
  final int morningMinute;

  /// Early afternoon, only if part of the day is left.
  final bool partway;

  /// Evening, only if nothing is read and there's a streak to keep.
  final bool streak;

  static const partwayHour = 13, partwayMinute = 15, streakHour = 20;

  ReminderPrefs copyWith({bool? morning, int? morningHour, int? morningMinute, bool? partway, bool? streak}) => ReminderPrefs(
        morning: morning ?? this.morning,
        morningHour: morningHour ?? this.morningHour,
        morningMinute: morningMinute ?? this.morningMinute,
        partway: partway ?? this.partway,
        streak: streak ?? this.streak,
      );

  Map<String, Object> toJson() =>
      {'morning': morning, 'h': morningHour, 'm': morningMinute, 'partway': partway, 'streak': streak};

  static ReminderPrefs fromJson(Object? j) {
    if (j is! Map) return const ReminderPrefs();
    return ReminderPrefs(
      morning: j['morning'] != false,
      morningHour: (j['h'] as num?)?.toInt() ?? 7,
      morningMinute: (j['m'] as num?)?.toInt() ?? 0,
      partway: j['partway'] != false,
      streak: j['streak'] != false,
    );
  }
}

/// Works out the reminders for today and the next week from the plan and progress.
/// Recomputed whenever progress changes or the app opens, so a reminder never fires
/// for something already done.
List<PlannedNotification> planReminders({
  required ReadingPlan plan,
  required PlanProgress progress,
  required ReminderPrefs prefs,
  required DateTime now,
  String name = '',
}) {
  final out = <PlannedNotification>[];
  final streak = progress.streak(now);
  for (var offset = 0; offset < 7; offset++) {
    final date = DateTime(now.year, now.month, now.day + offset);
    final day = plan.dayFor(date);
    if (day < 1 || day > plan.days) continue;
    final readings = plan.readingsFor(day);
    final done = progress.doneCount(plan, day);
    final complete = done == readings.length;
    if (complete) continue;
    DateTime at(int h, int m) => DateTime(date.year, date.month, date.day, h, m);
    final isToday = offset == 0;

    if (prefs.morning && done == 0) {
      final when = at(prefs.morningHour, prefs.morningMinute);
      if (when.isAfter(now)) {
        final m = morningReminder(today: readings, day: day, days: plan.days);
        out.add(PlannedNotification(id: 1000 + offset, when: when, title: m.title, body: m.body, route: 'plan'));
      }
    }
    if (prefs.partway && isToday && done > 0) {
      final when = at(ReminderPrefs.partwayHour, ReminderPrefs.partwayMinute);
      if (when.isAfter(now)) {
        final left = [for (var i = 0; i < readings.length; i++) if (!progress.isDone(day, i)) readings[i]];
        final m = partwayNudge(left: left, doneCount: done, name: name, variant: day);
        out.add(PlannedNotification(id: 2000, when: when, title: m.title, body: m.body, route: 'plan'));
      }
    }
    // The streak reminder only makes sense for today: tomorrow's streak depends on today.
    if (prefs.streak && isToday && done == 0 && streak > 0) {
      final when = at(ReminderPrefs.streakHour, 0);
      if (when.isAfter(now)) {
        final m = streakReminder(streak: streak, today: readings);
        out.add(PlannedNotification(id: 3000, when: when, title: m.title, body: m.body, route: 'plan'));
      }
    }
  }
  return out;
}
