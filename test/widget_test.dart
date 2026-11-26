import 'dart:io';

import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/data/daily_verses.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/main.dart';
import 'package:bethelprayerhouse/data/models.dart';
import 'package:bethelprayerhouse/screens/live_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The welcome screen remembers the last sign-in method.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest can reach every tab', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(BethelApp(state: AppState(repository: MockRepository())));
    expect(find.text('Continue as guest'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Verse of the day'), findsOneWidget);
    expect(find.textContaining(builtInVerse(DateTime.now()).reference!), findsWidgets, reason: "today's verse is shown");
    expect(find.textContaining('Good '), findsOneWidget, reason: 'greeting');
    expect(find.textContaining('friend'), findsWidgets, reason: 'guests are greeted as friend');
    expect(find.text('Sign in to save songs and notes'), findsOneWidget);
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

    // Saving needs an account (guests get a sign-in prompt).
    final state = AppState(repository: MockRepository())..signInAs(const UserProfile(name: 'Sam Lee', email: 'sam@example.com'));
    await tester.pumpWidget(BethelApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Songs').last);
    await tester.pumpAndSettle();

    expect(find.text('Songs of Zion'), findsWidgets);
    // Song 1 of Songs of Zion: the real book when assets/songs/songs_of_zion.json is present, else the sample.
    expect(
      find.textContaining('Dustula allochana choppuna').evaluate().isNotEmpty ||
          find.textContaining('Aadhaaram Naaku Aadhaaram').evaluate().isNotEmpty,
      isTrue,
    );

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

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(state.savedSongs, contains(3));
    expect(find.text('Saved to your songs'), findsOneWidget);
    expect(state.recentSongs.first.id, 3);
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
      // Rows show the Telugu title with the transliteration underneath.
      await tester.tap(find.textContaining('Ne Yesuni velugulo nadichedanu').first);
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

  testWidgets('sign up with a phone number and a texted code', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = AppState(repository: MockRepository());
    await tester.pumpWidget(BethelApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    expect(find.text('Your phone number'), findsOneWidget, reason: 'floating card');

    await tester.enterText(find.byType(TextField), '6305550123');
    await tester.pump();
    expect(find.text('+1 (630) 555-0123'), findsOneWidget, reason: 'formatted while typing');
    await tester.tap(find.text('Send code'));
    // The resend countdown ticks every second, so step the clock instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Enter the code'), findsOneWidget, reason: 'its own step');
    expect(find.text('+1 (630) 555‑0123'), findsOneWidget);
    expect(find.text('Resend in 0:42'), findsOneWidget);

    // A paste with letters and extra digits is trimmed to six digits, which submits by itself.
    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();
    expect(find.text('6'), findsOneWidget, reason: 'only digits, at most six');
    expect(find.text('Checking'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Verified'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Shown on the prayer wall'), findsOneWidget, reason: 'new members give a name');
    await tester.enterText(find.byType(TextField), 'Grace Paul');
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(state.user?.name, 'Grace Paul');
    expect(state.user?.contact, '+16305550123');
    expect(find.text('Verse of the day'), findsOneWidget, reason: 'signed in and on Home');
    expect(find.textContaining('Grace'), findsWidgets, reason: 'greeted by first name');
  });

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
    expect(find.text('Live now'), findsNothing);
    expect(find.text('Sunday Worship Service'), findsOneWidget);
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
    expect(find.text('Live now'), findsNothing);
    expect(find.text('Good Friday Service'), findsOneWidget, reason: 'special events scheduled on YouTube');
    expect(find.textContaining('Next stream'), findsOneWidget);
    expect(find.textContaining('11:00 AM'), findsOneWidget);

    await show(const [
      LiveStream(id: 1, title: 'Sunday Worship Service', description: '', image: '', youtubeUrl: '', isLive: true),
    ]);
    expect(find.text('Live now'), findsOneWidget);
  });
}
