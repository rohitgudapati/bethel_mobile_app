import 'dart:math';

import '../bible/books.dart';
import 'reading_plan.dart';

/// A message for the "you did it" moment or a reminder.
class PlanMessage {
  const PlanMessage(this.id, this.title, this.body, {this.verse});
  final int id;
  final String title;
  final String body;

  /// A short KJV verse to close with.
  final String? verse;
}

const _verses = [
  '“The LORD bless thee, and keep thee.” Numbers 6:24',
  '“Thy word is a lamp unto my feet, and a light unto my path.” Psalm 119:105',
  '“They shall run, and not be weary; and they shall walk, and not faint.” Isaiah 40:31',
  '“His compassions fail not. They are new every morning.” Lamentations 3:22–23',
  '“Man shall not live by bread alone, but by every word.” Matthew 4:4',
  '“I can do all things through Christ which strengtheneth me.” Philippians 4:13',
  '“Be strong and of a good courage.” Joshua 1:9',
  '“In his law doth he meditate day and night.” Psalm 1:2',
  '“The word of our God shall stand for ever.” Isaiah 40:8',
];

const _numbers = ['No', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve'];
String numberWord(int n, {bool lower = false}) {
  final w = n >= 0 && n < _numbers.length ? _numbers[n] : '$n';
  return lower && n < _numbers.length ? w.toLowerCase() : w;
}

/// The celebration after finishing a day. Built from the day itself (who, streak, what was
/// read, what's next, time of day, milestones) and never the same as [lastId].
PlanMessage celebration({
  required ReadingPlan plan,
  required PlanProgress progress,
  required int day,
  required DateTime now,
  String name = '',
  Random? random,
}) {
  final rnd = random ?? Random();
  final who = name.trim().split(RegExp(r'\s+')).first;
  String withName(String s) => who.isEmpty ? s.replaceAll(', {name}', '').replaceAll(' {name}', '') : s.replaceAll('{name}', who);

  final today = plan.readingsFor(day);
  final tomorrow = plan.readingsFor(day + 1);
  final streak = progress.streak(now);
  final done = progress.completedDays(plan);
  final pct = done * 100 ~/ plan.days;
  final pctBefore = (done - 1) * 100 ~/ plan.days;
  final chapters = today.fold<int>(0, (n, r) => n + r.chapters);
  final minutes = today.fold<int>(0, (n, r) => n + r.minutes);
  final finished = [for (final r in today) if (r.to == bibleBooks[r.book].chapters) bibleBooks[r.book].name];
  final next = tomorrow.isEmpty ? null : tomorrow.first;
  final nextLine = next == null ? '' : 'Tomorrow: ${next.label}.';
  final newBookTomorrow = next != null && next.from == 1 ? bibleBooks[next.book].name : null;

  final options = <PlanMessage>[];
  void add(int id, String title, String body) => options.add(PlanMessage(id, withName(title), withName(body)));

  if (day >= plan.days) {
    add(1, 'You read ${plan.scope == PlanScope.bible ? 'the whole Bible' : 'the New Testament'}, {name}.',
        '${plan.days} days, ${done == plan.days ? 'every one of them' : '$done of them'}. Well done, good and faithful servant.');
  } else {
    if (day == 1) add(2, 'Day one is done.', 'The first step is the hardest one. $nextLine');
    if (finished.isNotEmpty) {
      final book = finished.last;
      add(3, 'You finished $book, {name}.',
          newBookTomorrow != null ? '$chapters chapters today. Tomorrow you start $newBookTomorrow.' : '$chapters chapters today. $nextLine');
      add(4, '$book is done.', 'One more book read through. ${newBookTomorrow != null ? 'Next up: $newBookTomorrow.' : nextLine}');
    }
    for (final m in [25, 50, 75]) {
      if (pctBefore < m && pct >= m) {
        final part = {25: 'A quarter', 50: 'Halfway', 75: 'Three quarters'}[m]!;
        add(5, m == 50 ? 'Halfway there, {name}.' : '$part of the way.', '$done of ${plan.days} days done. $nextLine');
      }
    }
    if (streak >= 7 && streak % 7 == 0) {
      final weeks = streak ~/ 7;
      add(6, '$streak days in a row.', '${weeks == 1 ? 'A full week' : '${numberWord(weeks)} full weeks'} of showing up. $nextLine');
    }
    if (now.hour < 9) add(7, 'Done before nine, {name}.', 'About $minutes minutes with God to start the day. $nextLine');
    if (now.hour >= 21) add(8, 'Late, but faithful.', 'You still made it today${streak > 1 ? ', and your $streak-day streak lives on' : ''}. $nextLine');
    if (now.hour >= 11 && now.hour < 14) add(9, 'Done before lunch.', '${numberWord(chapters)} chapters before midday. $nextLine');
    if (streak > 1) add(10, '${numberWord(streak)} days straight, {name}.', 'Today: ${today.map((r) => r.label).join(', ')}. $nextLine');
    add(11, 'Well done, {name}.', 'Day $day of ${plan.days} is done. ${plan.days - day} to go.');
    add(12, 'Another day in the Word.', '$chapters chapters, about $minutes minutes. $nextLine');
  }

  // Prefer the most specific messages (they come first), but never repeat the last one.
  final fresh = options.where((o) => o.id != progress.lastMessage).toList();
  final pool = (fresh.isEmpty ? options : fresh).take(3).toList();
  final pick = pool[rnd.nextInt(pool.length)];
  return PlanMessage(pick.id, pick.title, pick.body.trim(), verse: _verses[(day + pick.id) % _verses.length]);
}

/// Afternoon nudge when part of today is left.
PlanMessage partwayNudge({required List<Reading> left, required int doneCount, String name = '', int variant = 0}) {
  final who = name.trim().split(RegExp(r'\s+')).first;
  final minutes = left.fold<int>(0, (n, r) => n + r.minutes);
  final title = left.length == 1
      ? '${numberWord(doneCount)} down, one to go'
      : '${numberWord(left.length)} readings left today';
  const nudges = ['A quiet coffee break would do it', 'You can do it', 'Find a few minutes this afternoon', 'Finish strong today'];
  final what = left.length == 1 ? left.first.label : '${left.first.label} and ${left.length - 1} more';
  final nudge = nudges[variant % nudges.length];
  return PlanMessage(100 + variant % nudges.length, title,
      '$what takes about $minutes minutes. $nudge${who.isEmpty ? '' : ', $who'}.');
}

/// Morning reminder when nothing is read yet.
PlanMessage morningReminder({required List<Reading> today, required int day, required int days}) {
  final minutes = today.fold<int>(0, (n, r) => n + r.minutes);
  return PlanMessage(200, 'Day $day of $days', '${today.map((r) => r.label).join(', ')}. About $minutes minutes.');
}

/// Evening reminder that protects a streak.
PlanMessage streakReminder({required int streak, required List<Reading> today}) {
  final minutes = today.fold<int>(0, (n, r) => n + r.minutes);
  return PlanMessage(300, 'Keep your $streak-day streak', 'There’s still time today. About $minutes minutes.');
}
