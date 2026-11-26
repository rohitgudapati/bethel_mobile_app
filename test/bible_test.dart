import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/app/theme.dart';
import 'package:bethelprayerhouse/bible/bible_text.dart';
import 'package:bethelprayerhouse/bible/books.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/data/models.dart';
import 'package:bethelprayerhouse/screens/bible_reader_screen.dart';
import 'package:bethelprayerhouse/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(AppState state) => AppScope(
      state: state,
      child: MaterialApp(theme: BethelTheme.light(), home: const BibleReaderScreen()),
    );

void main() {
  test('bundled texts line up: 66 books, same chapters and verses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final kjv = await BibleText.load(BibleVersion.kjv);
    final te = await BibleText.load(BibleVersion.te);
    expect(kjv.length, 66);
    expect(te.length, 66);
    for (var b = 0; b < 66; b++) {
      expect(kjv[b].length, bibleBooks[b].chapters);
      expect(te[b].length, bibleBooks[b].chapters);
    }
    expect(kjv[42][2][15], startsWith('For God so loved the world'));
    expect(te[19][2][4], contains('యెహోవాయందు'));
    expect(bibleRef(42, 3, verses: [16, 17]), 'John 3:16–17');

    // References as the church writes them.
    final r = parseBibleRef('Proverbs 3:5-6')!;
    expect([r.book, r.chapter, r.from, r.to], [19, 3, 5, 6]);
    expect(parseBibleRef('Psalm 23:1')!.book, 18);
    expect(parseBibleRef('1 John 4:8')!.book, 61);
    expect(parseBibleRef('Song of Songs 2:4')!.book, 21);
    expect(parseBibleRef('John 3:16 (KJV)')!.from, 16);
    expect(parseBibleRef('Nonsense 1:1'), isNull);
    expect(await biblePassage(BibleVersion.te, r), contains('యెహోవాయందు'));
  });

  testWidgets('read John 3, go to the next chapter, switch to Telugu, highlight', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await BibleText.load(BibleVersion.kjv);
      await BibleText.load(BibleVersion.te);
    });

    final state = AppState(repository: MockRepository());
    await tester.pumpWidget(_app(state));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('John 3'), findsWidgets);
    expect(find.textContaining('Nicodemus', findRichText: true), findsWidgets);

    // Next chapter.
    await tester.tap(find.text('John 4'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(state.bibleChapter, 4);
    expect(find.text('Chapter 4 of 21'), findsOneWidget);

    // Telugu.
    await tester.tap(find.text('KJV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Telugu Bible (BSI)'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(state.bibleVersion, BibleVersion.te);
    expect(find.text(bibleRef(42, 4, telugu: true)), findsOneWidget);

    // Select verse 1 and highlight it.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Verse 1(\D|$)')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highlight'));
    await tester.pumpAndSettle();
    expect(state.highlights, contains('42:4:1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pick Psalms 23 from the book list', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => BibleText.load(BibleVersion.kjv));

    final state = AppState(repository: MockRepository());
    await tester.pumpWidget(_app(state));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('John 3').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Old Testament'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Psalms'), 300, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Psalms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Psalms'));
    await tester.pumpAndSettle();
    final ch23 = find.widgetWithText(InkWell, '23');
    await tester.scrollUntilVisible(ch23, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(ch23);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(state.bibleBook, 18);
    expect(state.bibleChapter, 23);
    expect(find.textContaining('The LORD is my shepherd', findRichText: true), findsOneWidget);
  });

  testWidgets('verse of the day: English first, swipe or tap for Telugu', (tester) async {
    await tester.runAsync(() async {
      await BibleText.load(BibleVersion.kjv);
      await BibleText.load(BibleVersion.te);
    });
    final state = AppState(repository: MockRepository());
    final verse = DailyVerse(id: 1, date: DateTime(2026, 11, 26), reference: 'Proverbs 3:5');
    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(theme: BethelTheme.light(), home: Scaffold(body: ListView(children: [VerseCard(verse: verse)]))),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trust in the LORD'), findsOneWidget, reason: 'English from the bundled KJV');
    expect(find.text('Proverbs 3:5 · KJV'), findsOneWidget);

    await tester.fling(find.textContaining('Trust in the LORD'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('యెహోవాయందు'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trust in the LORD'), findsOneWidget);
  });
}
