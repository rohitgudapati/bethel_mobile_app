import 'dart:math';

import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/app/theme.dart';
import 'package:bethelprayerhouse/bible/verse_counts.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/data/models.dart';
import 'package:bethelprayerhouse/notifications/notification_service.dart';
import 'package:bethelprayerhouse/plan/plan_messages.dart';
import 'package:bethelprayerhouse/plan/reading_plan.dart';
import 'package:bethelprayerhouse/plan/reminder_planner.dart';
import 'package:bethelprayerhouse/screens/reading_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schedule', () {
    for (final scope in PlanScope.values) {
      for (final length in PlanLength.forScope(scope)) {
        test('${scope.name} in ${length.label}: every chapter once, in order, no empty days', () {
          final plan = ReadingPlan(scope: scope, length: length, start: DateTime(2026, 12, 1));
          final seen = <String>[];
          for (var d = 1; d <= plan.days; d++) {
            final rs = plan.readingsFor(d);
            expect(rs, isNotEmpty, reason: 'day $d');
            for (final r in rs) {
              expect(r.chapters, lessThanOrEqualTo(5));
              for (var c = r.from; c <= r.to; c++) {
                seen.add('${r.book}:$c');
              }
            }
          }
          final books = scope == PlanScope.bible ? List.generate(66, (i) => i) : List.generate(27, (i) => i + 39);
          final all = [for (final b in books) for (var c = 1; c <= bibleVerseCounts[b].length; c++) '$b:$c'];
          expect(seen, all);
        });
      }
    }

    test('3 months from Dec 1 ends Feb 28', () {
      final plan = ReadingPlan(scope: PlanScope.bible, length: PlanLength.quarter, start: DateTime(2026, 12, 1));
      expect(plan.end, DateTime(2027, 2, 28));
      expect(plan.dayFor(DateTime(2026, 12, 1, 22)), 1);
      expect(plan.dayFor(DateTime(2026, 11, 30)), 0);
    });
  });

  group('progress and streak', () {
    test('finishing a day counts once; unticking undoes it; streak counts back from today or yesterday', () {
      final state = AppState(repository: MockRepository());
      state.plan = ReadingPlan(scope: PlanScope.bible, length: PlanLength.quarter, start: DateTime(2026, 11, 15));
      final day12 = DateTime(2026, 11, 26, 10);
      // Days 9–11 read on their own dates.
      for (final d in [9, 10, 11]) {
        state.markDay(d, now: DateTime(2026, 11, 14 + d, 9));
      }
      expect(state.planProgress.streak(day12), 3, reason: 'today not read yet, streak runs to yesterday');
      final readings = state.plan!.readingsFor(12);
      PlanMessage? m;
      for (var i = 0; i < readings.length; i++) {
        m = state.setReading(12, i, true, now: day12);
        if (i < readings.length - 1) expect(m, isNull);
      }
      expect(m, isNotNull);
      expect(state.planProgress.streak(day12), 4);
      state.setReading(12, 0, false, now: day12);
      expect(state.planProgress.streak(day12), 3);
      expect(state.planProgress.completedOn.containsKey(12), isFalse);
    });

    test('celebrations change and never repeat the last one', () {
      final plan = ReadingPlan(scope: PlanScope.bible, length: PlanLength.quarter, start: DateTime(2026, 11, 15));
      final progress = PlanProgress();
      for (var d = 1; d <= 12; d++) {
        for (var i = 0; i < plan.readingsFor(d).length; i++) {
          progress.done.add(PlanProgress.key(d, i));
        }
        progress.completedOn[d] = dateKey(DateTime(2026, 11, 14 + d));
      }
      final seen = <int>{};
      for (var i = 0; i < 20; i++) {
        final m = celebration(plan: plan, progress: progress, day: 12, now: DateTime(2026, 11, 26, 12), name: 'Samuel Raju', random: Random(i));
        expect(m.id, isNot(progress.lastMessage));
        expect(m.title, isNot(contains('{name}')));
        progress.lastMessage = m.id;
        seen.add(m.id);
      }
      expect(seen.length, greaterThan(1));
    });
  });

  group('reminders', () {
    final plan = ReadingPlan(scope: PlanScope.bible, length: PlanLength.quarter, start: DateTime(2026, 11, 15));
    test('partway nudge only when part of today is left', () {
      final progress = PlanProgress()..done.add(PlanProgress.key(12, 0));
      final items = planReminders(plan: plan, progress: progress, prefs: const ReminderPrefs(), now: DateTime(2026, 11, 26, 10), name: 'Samuel');
      final nudge = items.where((n) => n.id == 2000).toList();
      expect(nudge, hasLength(1));
      expect(nudge.first.when, DateTime(2026, 11, 26, 13, 15));
      expect(nudge.first.body, contains('Samuel'));
      expect(items.where((n) => n.id == 1000), isEmpty, reason: 'no morning reminder once started');
    });

    test('nothing for a finished day; morning reminders for the coming days', () {
      final progress = PlanProgress();
      for (var i = 0; i < plan.readingsFor(12).length; i++) {
        progress.done.add(PlanProgress.key(12, i));
      }
      progress.completedOn[12] = '2026-11-26';
      final items = planReminders(plan: plan, progress: progress, prefs: const ReminderPrefs(), now: DateTime(2026, 11, 26, 6));
      expect(items.where((n) => n.when.day == 26), isEmpty);
      expect(items.where((n) => n.id == 1001).single.when, DateTime(2026, 11, 27, 7));
    });

    test('streak reminder in the evening only if nothing is read and there is a streak', () {
      final progress = PlanProgress()..completedOn[11] = '2026-11-25';
      final items = planReminders(plan: plan, progress: progress, prefs: const ReminderPrefs(), now: DateTime(2026, 11, 26, 15));
      expect(items.where((n) => n.id == 3000).single.when, DateTime(2026, 11, 26, 20));
    });
  });

  testWidgets('set up a 3-month plan starting today, then finish the day', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notes = RecordingNotificationService();
    final state = AppState(repository: MockRepository(), notifications: notes)..signInAs(const UserProfile(name: 'Samuel Raju', email: 'sam@example.com'));
    await tester.pumpWidget(AppScope(state: state, child: MaterialApp(theme: BethelTheme.light(), home: const ReadingPlanScreen())));
    await tester.pumpAndSettle();

    expect(find.textContaining('How long would you like'), findsOneWidget);
    await tester.tap(find.text('3 months'));
    await tester.pumpAndSettle();
    expect(find.text('When do you want to start?'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('When should we remind you?'), findsOneWidget);
    await tester.tap(find.text('Start my plan'));
    await tester.pumpAndSettle();

    expect(state.plan, isNotNull);
    expect(notes.permission, isTrue);
    expect(find.textContaining('Day 1 of 90'), findsOneWidget);
    await tester.tap(find.text('Mark today as read'));
    await tester.pumpAndSettle();
    expect(find.text('Your streak begins'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('All done for today'), findsOneWidget);
    expect(state.planProgress.streak(DateTime.now()), 1);
    expect(tester.takeException(), isNull);
  });
}
