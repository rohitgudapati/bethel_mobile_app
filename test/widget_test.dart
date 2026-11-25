import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guest can reach every tab', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(BethelApp(state: AppState(repository: MockRepository())));
    expect(find.text('Explore as a guest'), findsOneWidget);

    await tester.tap(find.text('Explore as a guest'));
    await tester.pumpAndSettle();
    expect(find.text('Verse of the day'), findsOneWidget);
    expect(find.text('Isaiah 40:31'), findsOneWidget);

    for (final tab in ['Songs', 'Watch', 'Prayer', 'More', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitting a prayer request adds it to the wall', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = AppState(repository: MockRepository())..continueAsGuest();
    await tester.pumpWidget(BethelApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prayer').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request prayer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Please pray for our exams this week.');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Sam Lee');
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(find.text('Please pray for our exams this week.'), findsOneWidget);
    expect(find.text('Sam (you)'), findsOneWidget);
  });

  testWidgets('song book: search by number, open lyrics, save', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = AppState(repository: MockRepository())..continueAsGuest();
    await tester.pumpWidget(BethelApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Songs').last);
    await tester.pumpAndSettle();

    expect(find.text('Songs of Zion'), findsWidgets);
    expect(find.text('Aadhaaram Naaku Aadhaaram'), findsWidgets);

    // Switch to the hymn book and search by number.
    await tester.tap(find.text('Hymns of Faith').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.pumpAndSettle();
    expect(find.text('Blessed Assurance'), findsOneWidget);

    await tester.tap(find.text('Blessed Assurance'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fanny Crosby'), findsOneWidget);
    expect(find.textContaining('Blessed assurance, Jesus is mine!'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.savedSongs, contains(3));
    expect(state.recentSongs.first.id, 3);
    expect(tester.takeException(), isNull);
  });
}
