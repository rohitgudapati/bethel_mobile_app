import '../bible/books.dart';
import '../bible/verse_counts.dart';

/// What the plan covers.
enum PlanScope {
  bible('The whole Bible'),
  newTestament('The New Testament');

  const PlanScope(this.label);
  final String label;
}

/// How long the member wants to take.
enum PlanLength {
  month(30, '1 month'),
  quarter(90, '3 months'),
  half(182, '6 months'),
  year(365, '1 year');

  const PlanLength(this.days, this.label);
  final int days;
  final String label;

  static List<PlanLength> forScope(PlanScope s) =>
      s == PlanScope.bible ? values : const [PlanLength.month, PlanLength.quarter, PlanLength.half];
}

/// Roughly how long one verse takes to read aloud-ish, in minutes. A chapter is about 3½ minutes.
const minutesPerVerse = 0.12;

/// One passage in a day: a run of chapters from one book, e.g. Numbers 27–31.
class Reading {
  const Reading(this.book, this.from, this.to, this.verses);
  final int book;
  final int from;
  final int to;
  final int verses;

  String get label => from == to ? '${bibleBooks[book].name} $from' : '${bibleBooks[book].name} $from–$to';
  String get teLabel => from == to ? '${bibleBooks[book].teName} $from' : '${bibleBooks[book].teName} $from–$to';
  int get chapters => to - from + 1;
  int get minutes => (verses * minutesPerVerse).round().clamp(1, 999);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A plan: what to read each day from [start] for [days] days.
class ReadingPlan {
  ReadingPlan({required this.scope, required this.length, required DateTime start}) : start = dateOnly(start);

  final PlanScope scope;
  final PlanLength length;
  final DateTime start;

  int get days => length.days;
  DateTime get end => DateTime(start.year, start.month, start.day + days - 1);

  /// Day number for a date: 1 on [start]. 0 or less before the plan starts, more than [days] after it ends.
  int dayFor(DateTime date) => dateOnly(date).difference(start).inDays + 1;

  DateTime dateOfDay(int day) => DateTime(start.year, start.month, start.day + day - 1);

  late final List<List<Reading>> schedule = buildSchedule(scope, days);

  List<Reading> readingsFor(int day) => day < 1 || day > days ? const [] : schedule[day - 1];

  Map<String, Object> toJson() => {'scope': scope.name, 'length': length.name, 'start': dateKey(start)};

  static ReadingPlan? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return ReadingPlan(
        scope: PlanScope.values.byName(j['scope'] as String),
        length: PlanLength.values.byName(j['length'] as String),
        start: DateTime.parse(j['start'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Chapters a day and minutes a day, for the setup screen.
  static (double, int) pace(PlanScope scope, PlanLength length) {
    final books = _books(scope);
    final chapters = books.fold<int>(0, (n, b) => n + bibleVerseCounts[b].length);
    final verses = books.fold<int>(0, (n, b) => n + bibleVerseCounts[b].fold<int>(0, (a, v) => a + v));
    return (chapters / length.days, (verses * minutesPerVerse / length.days).round());
  }
}

Iterable<int> _books(PlanScope s) => s == PlanScope.bible ? Iterable<int>.generate(66) : Iterable<int>.generate(27, (i) => i + 39);

/// Splits the chapters into [days] days of about the same amount of text, keeping chapters whole.
/// Each day's chapters are grouped into readings by book, at most five chapters per reading.
List<List<Reading>> buildSchedule(PlanScope scope, int days) {
  final chapters = <(int, int, int)>[]; // book, chapter, verses
  for (final b in _books(scope)) {
    final counts = bibleVerseCounts[b];
    for (var c = 0; c < counts.length; c++) {
      chapters.add((b, c + 1, counts[c]));
    }
  }
  final total = chapters.fold<int>(0, (n, c) => n + c.$3);
  final byDay = List.generate(days, (_) => <(int, int, int)>[]);
  // Each day takes chapters while that brings the running total closer to where the day
  // should end, always at least one, and always leaving at least one for each day after it.
  var i = 0, sum = 0;
  for (var d = 0; d < days && i < chapters.length; d++) {
    final target = total * (d + 1) / days;
    final maxTake = chapters.length - i - (days - d - 1);
    var take = 0;
    while (take < maxTake) {
      final next = chapters[i + take].$3;
      if (take > 0 && (sum + next - target).abs() >= (sum - target).abs()) break;
      sum += next;
      take++;
    }
    byDay[d].addAll(chapters.sublist(i, i + take));
    i += take;
  }
  if (i < chapters.length) byDay.last.addAll(chapters.sublist(i));
  return [
    for (final day in byDay) _group(day),
  ];
}

List<Reading> _group(List<(int, int, int)> chapters) {
  final out = <Reading>[];
  for (final c in chapters) {
    final last = out.isEmpty ? null : out.last;
    if (last != null && last.book == c.$1 && last.to == c.$2 - 1 && last.chapters < 5) {
      out[out.length - 1] = Reading(last.book, last.from, c.$2, last.verses + c.$3);
    } else {
      out.add(Reading(c.$1, c.$2, c.$2, c.$3));
    }
  }
  return out;
}

/// What the member has read, and the streak that comes from it.
class PlanProgress {
  PlanProgress({Set<String>? done, Map<int, String>? completedOn, this.lastMessage = -1})
      : done = done ?? {},
        completedOn = completedOn ?? {};

  /// Readings ticked off, as "day:index".
  final Set<String> done;

  /// The date each plan day was finished on, as "yyyy-mm-dd". Unticking a reading removes it.
  final Map<int, String> completedOn;

  /// Dates on which the member finished a day's reading.
  Set<String> get readDates => completedOn.values.toSet();

  /// The celebration message shown last, so the next one is different.
  int lastMessage;

  static String key(int day, int index) => '$day:$index';

  bool isDone(int day, int index) => done.contains(key(day, index));

  int doneCount(ReadingPlan plan, int day) =>
      List.generate(plan.readingsFor(day).length, (i) => i).where((i) => isDone(day, i)).length;

  bool dayComplete(ReadingPlan plan, int day) {
    final n = plan.readingsFor(day).length;
    return n > 0 && doneCount(plan, day) == n;
  }

  /// Days in a row with a finished reading, counting today if it's done and otherwise up to yesterday.
  int streak(DateTime now) {
    var d = dateOnly(now);
    if (!readDates.contains(dateKey(d))) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (readDates.contains(dateKey(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// Earlier days of the plan that aren't finished yet.
  List<int> behind(ReadingPlan plan, DateTime now) {
    final today = plan.dayFor(now).clamp(0, plan.days + 1);
    return [for (var d = 1; d < today && d <= plan.days; d++) if (!dayComplete(plan, d)) d];
  }

  int completedDays(ReadingPlan plan) => [for (var d = 1; d <= plan.days; d++) if (dayComplete(plan, d)) d].length;

  Map<String, Object> toJson() =>
      {'done': done.toList(), 'completed': {for (final e in completedOn.entries) '${e.key}': e.value}, 'last': lastMessage};

  static PlanProgress fromJson(Object? j) {
    if (j is! Map) return PlanProgress();
    return PlanProgress(
      done: {...?(j['done'] as List?)?.whereType<String>()},
      completedOn: {
        for (final e in ((j['completed'] as Map?) ?? const {}).entries)
          if (int.tryParse('${e.key}') != null && e.value is String) int.parse('${e.key}'): e.value as String
      },
      lastMessage: (j['last'] as num?)?.toInt() ?? -1,
    );
  }
}
