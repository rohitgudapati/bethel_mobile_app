import 'package:bethelprayerhouse/app/app_state.dart';
import 'package:bethelprayerhouse/app/theme.dart';
import 'package:bethelprayerhouse/data/mock_repository.dart';
import 'package:bethelprayerhouse/notes/note.dart';
import 'package:bethelprayerhouse/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Note _n(String id, String speaker, DateTime date, {String passage = '', String title = 'T'}) =>
    Note(id: id, title: title, body: 'body $id', date: date, speaker: speaker, passage: passage, updated: date);

void main() {
  test('filter by speaker, date range, book and words', () {
    final notes = [
      _n('a', 'Bro. Moses Polugari', DateTime(2026, 11, 22), passage: 'Philippians 4:6–7', title: 'Peace'),
      _n('b', 'Bro. Vinod Somepalli', DateTime(2026, 11, 15), passage: '1 John 1:5–7'),
      _n('c', 'Bro. Moses Polugari', DateTime(2026, 10, 18), passage: 'Joshua 24:15'),
    ];
    List<String> ids(NoteFilter f) => notes.where(f.matches).map((n) => n.id).toList();
    expect(ids(const NoteFilter(speaker: 'Bro. Moses Polugari')), ['a', 'c']);
    expect(ids(NoteFilter(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 30))), ['a', 'b']);
    expect(ids(const NoteFilter(book: 'Philippians')), ['a']);
    expect(ids(const NoteFilter(book: 'John')), isEmpty, reason: '1 John is not John');
    expect(ids(const NoteFilter(query: 'peace')), ['a']);
    expect(ids(NoteFilter(speaker: 'Bro. Moses Polugari', from: DateTime(2026, 11, 1))), ['a']);
  });

  test('sermon notes become notes with the speaker and date; clearing removes them', () {
    final state = AppState(repository: MockRepository());
    state.setSermonNote(sermonId: 7, title: 'Walking in the light', speaker: 'Bro. Vinod Somepalli', date: DateTime(2026, 11, 15), body: 'Fellowship first');
    expect(state.notes.single.speaker, 'Bro. Vinod Somepalli');
    expect(state.noteForSermon(7)!.title, 'Walking in the light');
    state.setSermonNote(sermonId: 7, title: 'Walking in the light', speaker: 'Bro. Vinod Somepalli', date: DateTime(2026, 11, 15), body: 'Fellowship first, then cleansing');
    expect(state.notes, hasLength(1));
    state.setSermonNote(sermonId: 7, title: 'x', speaker: 'x', date: DateTime(2026), body: '  ');
    expect(state.notes, isEmpty);
  });

  testWidgets('write a note with a speaker and passage, then filter by speaker', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState(repository: MockRepository())
      ..saveNote(_n('old', 'Bro. Vinod Somepalli', DateTime(2026, 11, 15), title: 'Walking in the light'));
    await tester.pumpWidget(AppScope(state: state, child: MaterialApp(theme: BethelTheme.light(), home: const NotesScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Walking in the light'), findsOneWidget);

    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Peace that guards your heart');
    await tester.enterText(find.widgetWithText(TextField, 'Write your note'), 'Peace is a guard at the door.');
    await tester.tap(find.text('Add speaker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Bro. Moses Polugari');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add passage'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'John 3:16'), 'philippians 4:6-7');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Philippians 4:6–7'), findsOneWidget, reason: 'passage is tidied');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(state.notes, hasLength(2));
    expect(find.text('Peace that guards your heart'), findsOneWidget);

    await tester.tap(find.text('Speaker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bro. Moses Polugari').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 1 note'));
    await tester.pumpAndSettle();
    expect(find.text('Peace that guards your heart'), findsOneWidget);
    expect(find.text('Walking in the light'), findsNothing);
    expect(find.textContaining('1 note from Bro. Moses Polugari'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
