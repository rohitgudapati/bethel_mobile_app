/// Reads service schedules written for people ("Every Sunday · 3:00 PM",
/// "First Friday of the month") and works out when each one next happens.
library;

const _days = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

const _ordinals = {'first': 1, '1st': 1, 'second': 2, '2nd': 2, 'third': 3, '3rd': 3, 'fourth': 4, '4th': 4, 'last': -1};

/// When a service next happens. [hasTime] is false for schedules without a clock time
/// ("First Friday of the month"): then only the day is known.
class Occurrence {
  const Occurrence(this.start, {required this.hasTime});
  final DateTime start;
  final bool hasTime;
}

/// The next time [schedule] happens at or after [now] (a service that started less than
/// [grace] ago still counts, so "happening now" shows). Null when the schedule can't be
/// read, or for "every other" week schedules, where the week can't be known from the text.
Occurrence? nextOccurrence(String schedule, DateTime now, {Duration grace = const Duration(hours: 2)}) {
  final s = schedule.toLowerCase();
  if (s.contains('every other') || s.contains('alternate') || s.contains('biweekly')) return null;
  int? weekday;
  for (final e in _days.entries) {
    if (RegExp('\\b${e.key}s?\\b').hasMatch(s)) {
      weekday = e.value;
      break;
    }
  }
  if (weekday == null) return null;

  final m = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*([ap])\.?\s*m\b').firstMatch(s);
  final hasTime = m != null;
  var hour = 0, minute = 0;
  if (m != null) {
    hour = int.parse(m.group(1)!) % 12 + (m.group(3) == 'p' ? 12 : 0);
    minute = int.tryParse(m.group(2) ?? '0') ?? 0;
  }

  int? nth;
  for (final e in _ordinals.entries) {
    if (RegExp('\\b${e.key}\\b').hasMatch(s)) {
      nth = e.value;
      break;
    }
  }

  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);
  bool notOver(DateTime start) => hasTime ? start.isAfter(now.subtract(grace)) : !_day(start).isBefore(_day(now));

  if (nth != null && s.contains('month')) {
    for (var i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month + i);
      final day = _nthWeekday(month.year, month.month, weekday, nth);
      if (day != null && notOver(at(day))) return Occurrence(at(day), hasTime: hasTime);
    }
    return null;
  }

  for (var i = 0; i < 8; i++) {
    final day = DateTime(now.year, now.month, now.day + i);
    if (day.weekday == weekday && notOver(at(day))) return Occurrence(at(day), hasTime: hasTime);
  }
  return null;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _nthWeekday(int year, int month, int weekday, int nth) {
  if (nth == -1) {
    var d = DateTime(year, month + 1, 0);
    while (d.weekday != weekday) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return d;
  }
  var d = DateTime(year, month, 1);
  while (d.weekday != weekday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  d = DateTime(d.year, d.month, d.day + 7 * (nth - 1));
  return d.month == month ? d : null;
}

/// "Tonight", "Today", "Tomorrow", or the weekday ("Sunday") within a week, else "Fri, Dec 4".
String dayLabel(DateTime start, DateTime now, {bool hasTime = true}) {
  final days = _day(start).difference(_day(now)).inDays;
  if (days == 0) return hasTime && start.hour >= 17 ? 'Tonight' : 'Today';
  if (days == 1) return 'Tomorrow';
  const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (days < 7) return names[start.weekday - 1];
  const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${short[start.weekday - 1]}, ${months[start.month - 1]} ${start.day}';
}

String clockTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "in 3 h 20 min", "in 12 min", "Happening now".
String countdown(DateTime start, DateTime now) {
  final diff = start.difference(now);
  if (diff.isNegative) return 'Happening now';
  final mins = diff.inMinutes;
  if (mins < 1) return 'Starting now';
  if (mins < 60) return 'in $mins min';
  final h = diff.inHours;
  if (h < 24) {
    final m = mins - h * 60;
    return m == 0 ? 'in $h h' : 'in $h h $m min';
  }
  final d = (diff.inHours / 24).round();
  return d == 1 ? 'in 1 day' : 'in $d days';
}
