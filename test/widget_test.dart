import 'dart:io';

import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/data/daily_verses.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/main.dart';
import 'package:bethelprayerhouse/data/models.dart';
import 'package:bethelprayerhouse/screens/live_banner.dart';
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
    expect(find.text('VERSE OF THE DAY'), findsOneWidget);
    expect(find.text(builtInVerse(DateTime.now()).reference!), findsWidgets, reason: "today's verse is shown");
    await tester.scrollUntilVisible(find.text('Testimonies'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Testimonies'), findsOneWidget, reason: 'heart shortcut opens Testimonies');
    expect(find.text('Give'), findsNothing);
    expect(find.text('Meet our elders'), findsNothing, reason: 'elders moved to More');

    for (final tab in ['Songs', 'Watch', 'Prayer', 'More']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    // More: Meet our elders
    await tester.scrollUntilVisible(find.text('Bro. Moses Polugari'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Meet our elders'), findsOneWidget);
    expect(find.text('Bro. Vinod Somepalli'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
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
    // Song 1 of Songs of Zion: the real book when assets/songs/songs_of_zion.json is present, else the sample.
    expect(
      find.text('Dustula allochana choppuna').evaluate().isNotEmpty ||
          find.text('Aadhaaram Naaku Aadhaaram').evaluate().isNotEmpty,
      isTrue,
    );

    expect(find.text('Hymns of Faith'), findsNothing, reason: 'replaced by Bethel English Songs');

    // Open song 1 of Songs of Zion and save it.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(state.savedSongs, hasLength(1));
    expect(state.recentSongs.first.number, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Songs of Zion: find song 500 by number and read it in Telugu and English',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final state = AppState(repository: MockRepository())..continueAsGuest();
      await tester.pumpWidget(BethelApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Songs').last);
      await tester.pumpAndSettle();
      expect(find.text('866 songs'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '500');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ne Yesuni velugulo nadichedanu'));
      await tester.pumpAndSettle();

      expect(find.text('నే యేసుని వెలుగులో నడిచెదను'), findsOneWidget, reason: 'Telugu title');
      expect(find.textContaining('John 8:12'), findsOneWidget, reason: 'Bible reference');
      expect(find.textContaining('రాత్రింబగలాయనతో నడిచెదను'), findsOneWidget, reason: 'Telugu lyrics first');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ratrimabagalaayanato nadichedanu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !File('assets/songs/songs_of_zion.json').existsSync(),
  );

  test('the built-in verse changes every day and repeats the same verse for everyone', () {
    final a = builtInVerse(DateTime(2026, 11, 25, 6));
    final b = builtInVerse(DateTime(2026, 11, 25, 23, 59));
    final c = builtInVerse(DateTime(2026, 11, 26, 0, 1));
    expect(a.reference, b.reference, reason: 'same day, same verse');
    expect(a.id, b.id);
    expect(c.reference, isNot(a.reference), reason: 'next day, new verse');
    final month = {for (var d = 1; d <= 30; d++) builtInVerse(DateTime(2026, 11, d)).reference};
    expect(month.length, 30, reason: 'no repeats within a month');
  });

  test('next Sunday service is the coming Sunday at 3:00 PM', () {
    expect(nextSundayService(DateTime(2026, 11, 25, 10)), DateTime(2026, 11, 29, 15)); // Wednesday
    expect(nextSundayService(DateTime(2026, 11, 29, 9)), DateTime(2026, 11, 29, 15)); // Sunday morning
    expect(nextSundayService(DateTime(2026, 11, 29, 18)), DateTime(2026, 12, 6, 15)); // Sunday evening
  });

  testWidgets('banner says LIVE only while streaming', (tester) async {
    Future<void> show(List<LiveStream> s) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: LiveBanner(streams: s))));

    await show(const []);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('NEXT SERVICE'), findsOneWidget);
    expect(find.textContaining('3:00 PM CT'), findsOneWidget);

    await show([
      LiveStream(
        id: 1,
        title: 'Good Friday Service',
        description: '',
        image: '',
        youtubeUrl: 'https://youtube.com',
        scheduledStart: DateTime(2027, 3, 26, 11),
      ),
    ]);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('UPCOMING'), findsOneWidget, reason: 'special events scheduled on YouTube');
    expect(find.textContaining('11:00 AM'), findsOneWidget);

    await show(const [
      LiveStream(id: 1, title: 'Sunday Worship Service', description: '', image: '', youtubeUrl: '', isLive: true),
    ]);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets(
    'Bethel English Songs: second song book, search by number, save',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final state = AppState(repository: MockRepository())..continueAsGuest();
      await tester.pumpWidget(BethelApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Songs').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bethel English Songs').first);
      await tester.pumpAndSettle();
      expect(find.text('60 songs'), findsOneWidget);
      expect(find.text('Be still, for the presence of the Lord'), findsOneWidget);

      await tester.tap(find.text('Be still, for the presence of the Lord'));
      await tester.pumpAndSettle();
      expect(find.textContaining('The Holy one is here'), findsWidgets);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(state.savedSongs, hasLength(1));

      // Search by number across both books.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '30');
      await tester.pumpAndSettle();
      expect(find.text('I will sing of the mercies of the Lord'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !File('assets/songs/bethel_english.json').existsSync(),
  );
}
