import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/app/theme.dart';
import 'package:bethelprayerhouse/bible/bible_text.dart';
import 'package:bethelprayerhouse/bible/books.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/screens/bible_reader_screen.dart';
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
    expect(find.text('యోహాను సువార్త 4'), findsOneWidget);

    // Select verse 1 and highlight it.
    await tester.tap(find.bySemanticsLabel('Verse 1'));
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
}
