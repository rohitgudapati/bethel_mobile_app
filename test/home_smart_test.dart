import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/app/clock.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home puts its sections in a different order depending on the day and time.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => setTestNow(null));

  Future<List<String>> homeOrder(WidgetTester tester, DateTime now) async {
    setTestNow(now);
    tester.view.physicalSize = const Size(1170, 2532 * 4); // tall, so every section is built
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState(repository: MockRepository())..continueAsGuest();
    await tester.pumpWidget(BethelApp(state: state));
    await tester.pumpAndSettle();
    final keys = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('home-'));
    final found = keys.evaluate().map((e) => (e.widget.key as ValueKey<String>).value.substring(5)).toList();
    final y = {for (final k in found) k: tester.getTopLeft(find.byKey(ValueKey('home-$k'))).dy};
    found.sort((a, b) => y[a]!.compareTo(y[b]!));
    expect(tester.takeException(), isNull);
    return found;
  }

  testWidgets('Sunday 3:10 PM: the live stream comes first', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 6, 15, 10));
    expect(o.first, 'live');
    expect(o[1], 'verse');
    expect(o, isNot(contains('replay')));
  });

  testWidgets('Sunday 2:40 PM: starting soon above the verse', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 6, 14, 40));
    expect(o.take(2), ['startingSoon', 'verse']);
  });

  testWidgets('Sunday 7 PM: replay right under the verse', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 6, 19));
    expect(o.take(2), ['verse', 'replay']);
  });

  testWidgets('Monday: last week’s winners under the verse; no weekly board below', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 7, 8));
    expect(o.take(2), ['verse', 'lastWeekWinners']);
    expect(o, isNot(contains('leaderboard')));
  });

  testWidgets('Special Meetings day: the event banner under the verse', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 5, 11));
    expect(o.take(2), ['verse', 'eventToday']);
  });

  testWidgets('ordinary weekday: verse, trivia, then browsing', (tester) async {
    final o = await homeOrder(tester, DateTime(2026, 12, 9, 8));
    expect(o.first, 'verse');
    expect(o.indexOf('trivia'), lessThan(o.indexOf('thisWeek')));
    expect(o.indexOf('thisWeek'), lessThan(o.indexOf('playlists')));
    expect(o, contains('leaderboard'));
    expect(o.last, 'planStart', reason: 'no reading plan yet');
  });
}
