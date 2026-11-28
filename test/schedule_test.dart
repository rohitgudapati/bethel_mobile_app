import 'package:bethelprayerhouse/home/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Saturday, Nov 28, 2026, 2:00 PM
  final sat = DateTime(2026, 11, 28, 14);

  test('weekly services with a time', () {
    final sun = nextOccurrence('Every Sunday · 3:00 PM', sat)!;
    expect(sun.start, DateTime(2026, 11, 29, 15));
    expect(sun.hasTime, isTrue);
    expect(nextOccurrence('Every Friday · 7:30 PM', sat)!.start, DateTime(2026, 12, 4, 19, 30));
    expect(nextOccurrence('Sundays at 6:30pm', sat)!.start, DateTime(2026, 11, 29, 18, 30));
  });

  test('a service that started less than two hours ago is still next', () {
    final during = DateTime(2026, 11, 29, 16);
    expect(nextOccurrence('Every Sunday · 3:00 PM', during)!.start, DateTime(2026, 11, 29, 15));
    final after = DateTime(2026, 11, 29, 18);
    expect(nextOccurrence('Every Sunday · 3:00 PM', after)!.start, DateTime(2026, 12, 6, 15));
  });

  test('nth weekday of the month, without a time', () {
    final first = nextOccurrence('First Friday of the month', sat)!;
    expect(first.start, DateTime(2026, 12, 4));
    expect(first.hasTime, isFalse);
    expect(nextOccurrence('Last Sunday of the month', sat)!.start, DateTime(2026, 11, 29));
  });

  test('schedules that cannot be placed', () {
    expect(nextOccurrence('Every other Sunday', sat), isNull);
    expect(nextOccurrence('By appointment', sat), isNull);
  });

  test('labels', () {
    expect(dayLabel(DateTime(2026, 11, 28, 19, 30), sat), 'Tonight');
    expect(dayLabel(DateTime(2026, 11, 29, 15), sat), 'Tomorrow');
    expect(dayLabel(DateTime(2026, 12, 2, 15), sat), 'Wednesday');
    expect(dayLabel(DateTime(2026, 12, 11, 19), sat), 'Fri, Dec 11');
    expect(countdown(DateTime(2026, 11, 28, 17, 20), sat), 'in 3 h 20 min');
    expect(countdown(DateTime(2026, 11, 28, 14, 12), sat), 'in 12 min');
    expect(countdown(DateTime(2026, 11, 28, 13), sat), 'Happening now');
    expect(clockTime(DateTime(2026, 1, 1, 19, 30)), '7:30 PM');
  });
}
