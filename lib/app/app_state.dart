import 'package:flutter/material.dart';

import '../data/api_repository.dart';
import '../data/bible_facts.dart';
import '../data/firebase_repository.dart';
import '../data/mock_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../bible/bible_text.dart';
import '../notes/note.dart';
import '../notifications/notification_service.dart';
import '../plan/plan_messages.dart';
import '../plan/reading_plan.dart';
import '../plan/reminder_planner.dart';
import 'config.dart';
import 'launch.dart';
import 'local_store.dart';

/// Small app-wide state: data source, signed-in user, theme and a few
/// personal toggles. Exposed to widgets through [AppScope].
class AppState extends ChangeNotifier {
  AppState({BethelRepository? repository, NotificationService? notifications})
      : notifications = notifications ?? RecordingNotificationService(),
        repo = repository ??
            (AppConfig.isFirebase
                ? FirebaseRepository()
                : AppConfig.isDemo
                    ? MockRepository()
                    : ApiRepository());

  final BethelRepository repo;

  /// Reminders and, later, push messages. See docs/firebase-setup.md.
  final NotificationService notifications;

  LocalStore _store = LocalStore.memory();

  /// Loads what was saved on this phone. Call once before the app starts.
  Future<void> restore([LocalStore? store]) async {
    _store = store ?? await LocalStore.open();
    final b = _store.read('bible');
    if (b is Map) {
      bibleVersion = BibleVersion.fromName(b['version'] as String?);
      bibleBook = ((b['book'] as num?) ?? bibleBook).toInt().clamp(0, 65);
      bibleChapter = ((b['chapter'] as num?) ?? bibleChapter).toInt().clamp(1, 150);
      bibleParallel = b['parallel'] == true;
      bibleScale = ((b['scale'] as num?) ?? 1).toDouble().clamp(0.8, 1.6);
    }
    final h = _store.read('highlights');
    if (h is List) highlights.addAll(h.whereType<String>());
    plan = ReadingPlan.fromJson(_store.read('plan'));
    planProgress = PlanProgress.fromJson(_store.read('planProgress'));
    reminderPrefs = ReminderPrefs.fromJson(_store.read('reminders'));
    final n = _store.read('notes');
    if (n is List) notes.addAll(n.map(Note.fromJson).whereType<Note>());
    final f = _store.read('facts');
    if (f is Map) {
      factIndex = ((f['index'] as num?) ?? factIndex).toInt();
      factChoice = (f['choice'] as num?)?.toInt();
      factHistory.addAll(((f['history'] as List?) ?? const []).whereType<bool>());
      if (f['date'] != dateKey(DateTime.now()) && factChoice != null) {
        // A new day brings a new question.
        factIndex = (factIndex + 1) % bibleFacts.length;
        factChoice = null;
      }
    }
    await rescheduleReminders();
    notifyListeners();
  }

  // ------------------------------------------------------------ Bible
  BibleVersion bibleVersion = BibleVersion.kjv;
  int bibleBook = 42; // John
  int bibleChapter = 3;
  bool bibleParallel = false;
  double bibleScale = 1;

  /// Highlighted verses as "book:chapter:verse".
  final Set<String> highlights = {};

  void _saveBible() => _store.write('bible', {
        'version': bibleVersion.name,
        'book': bibleBook,
        'chapter': bibleChapter,
        'parallel': bibleParallel,
        'scale': bibleScale,
      });

  void openBible(int book, int chapter) {
    bibleBook = book;
    bibleChapter = chapter;
    _saveBible();
    notifyListeners();
  }

  void setBibleVersion(BibleVersion v) {
    bibleVersion = v;
    _saveBible();
    notifyListeners();
  }

  void setBibleParallel(bool on) {
    bibleParallel = on;
    _saveBible();
    notifyListeners();
  }

  void setBibleScale(double s) {
    bibleScale = s;
    _saveBible();
    notifyListeners();
  }

  /// Highlights the verses, or removes the highlight if they all have one already.
  void toggleHighlights(Iterable<String> keys) {
    final all = keys.every(highlights.contains);
    all ? highlights.removeAll(keys) : highlights.addAll(keys);
    _store.write('highlights', highlights.toList());
    notifyListeners();
  }

  UserProfile? user;
  bool guest = LaunchOptions.skipWelcome;
  /// Follows the phone's light or dark setting until the member picks one in More.
  ThemeMode themeMode = ThemeMode.system;
  final Set<int> likedVerses = {};
  final Set<int> savedSongs = {};
  final Set<int> downloadedSongs = {};
  final List<Song> recentSongs = [];
  double lyricsScale = 1;
  final Set<int> prayedFor = {};
  final Set<int> rsvps = {};

  // ------------------------------------------------------------ Did you know?
  int factIndex = DateTime.now().difference(DateTime(DateTime.now().year)).inDays % bibleFacts.length;

  /// The answer picked for the current question, or null if not answered yet.
  int? factChoice;

  /// Right or wrong for recent answers, newest last.
  final List<bool> factHistory = [];

  BibleFact get fact => bibleFacts[factIndex % bibleFacts.length];

  void _saveFacts() => _store.write('facts', {
        'index': factIndex,
        'choice': factChoice,
        'history': factHistory.length > 20 ? factHistory.sublist(factHistory.length - 20) : factHistory,
        'date': dateKey(DateTime.now()),
      });

  void answerFact(int choice) {
    if (factChoice != null) return;
    factChoice = choice;
    factHistory.add(choice == fact.answer);
    _saveFacts();
    notifyListeners();
  }

  void nextFact() {
    factIndex = (factIndex + 1) % bibleFacts.length;
    factChoice = null;
    _saveFacts();
    notifyListeners();
  }

  // ------------------------------------------------------------ Reading plan
  ReadingPlan? plan;
  PlanProgress planProgress = PlanProgress();
  ReminderPrefs reminderPrefs = const ReminderPrefs();

  void _savePlan() {
    _store.write('plan', plan?.toJson());
    _store.write('planProgress', planProgress.toJson());
    _store.write('reminders', reminderPrefs.toJson());
  }

  Future<void> startPlan(ReadingPlan p, ReminderPrefs prefs) async {
    plan = p;
    planProgress = PlanProgress();
    reminderPrefs = prefs;
    _savePlan();
    notifyListeners();
    if (prefs.morning || prefs.partway || prefs.streak) await notifications.requestPermission();
    await rescheduleReminders();
  }

  void endPlan() {
    plan = null;
    planProgress = PlanProgress();
    _savePlan();
    notifyListeners();
    rescheduleReminders();
  }

  void setReminderPrefs(ReminderPrefs prefs) {
    reminderPrefs = prefs;
    _savePlan();
    notifyListeners();
    rescheduleReminders();
  }

  /// Ticks or unticks one reading. Returns the celebration when this finishes the day.
  PlanMessage? setReading(int day, int index, bool done, {DateTime? now}) {
    final p = plan;
    if (p == null) return null;
    final at = now ?? DateTime.now();
    final wasComplete = planProgress.dayComplete(p, day);
    done ? planProgress.done.add(PlanProgress.key(day, index)) : planProgress.done.remove(PlanProgress.key(day, index));
    final isComplete = planProgress.dayComplete(p, day);
    PlanMessage? message;
    if (isComplete && !wasComplete) {
      planProgress.completedOn[day] = dateKey(at);
      message = celebration(plan: p, progress: planProgress, day: day, now: at, name: user?.name ?? '');
      planProgress.lastMessage = message.id;
    } else if (!isComplete && wasComplete) {
      planProgress.completedOn.remove(day);
    }
    _savePlan();
    notifyListeners();
    rescheduleReminders(now: at);
    return message;
  }

  /// Ticks every reading of a day.
  PlanMessage? markDay(int day, {DateTime? now}) {
    final p = plan;
    if (p == null) return null;
    final n = p.readingsFor(day).length;
    PlanMessage? message;
    for (var i = 0; i < n; i++) {
      if (!planProgress.isDone(day, i)) message = setReading(day, i, true, now: now) ?? message;
    }
    return message;
  }

  Future<void> rescheduleReminders({DateTime? now}) async {
    final p = plan;
    final items = p == null
        ? const <PlannedNotification>[]
        : planReminders(plan: p, progress: planProgress, prefs: reminderPrefs, now: now ?? DateTime.now(), name: user?.name ?? '');
    try {
      await notifications.replaceGroup('plan', items);
    } catch (_) {
      // A reminder that can't be scheduled must never break reading.
    }
  }

  /// Which notifications the member wants. Kept on this phone while the app runs.
  final Map<String, bool> notificationPrefs = {
    'Service reminders': true,
    'New messages': true,
    'Prayer updates': true,
    'Events': false,
  };

  void setNotificationPref(String key, bool on) {
    notificationPrefs[key] = on;
    notifyListeners();
  }

  // ------------------------------------------------------------ Notes
  /// Saved on the phone; they'll sync to the member's account once Firebase is set up.
  final List<Note> notes = [];

  void _saveNotes() => _store.write('notes', [for (final n in notes) n.toJson()]);

  /// Adds or replaces a note. Empty notes are removed.
  void saveNote(Note note) {
    notes.removeWhere((n) => n.id == note.id);
    if (!note.isEmpty) notes.add(note.copyWith(updated: DateTime.now()));
    _saveNotes();
    notifyListeners();
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    _saveNotes();
    notifyListeners();
  }

  Note? noteForSermon(int sermonId) => notes.where((n) => n.sermonId == sermonId).firstOrNull;

  /// Speakers used in notes, most used first.
  List<String> get noteSpeakers {
    final counts = <String, int>{};
    for (final n in notes) {
      if (n.speaker.trim().isNotEmpty) counts[n.speaker] = (counts[n.speaker] ?? 0) + 1;
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  static String newNoteId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${notesSeq++}';
  static int notesSeq = 0;
  final Set<int> readNotifications = {};

  bool get signedIn => user != null || guest;

  void signInAs(UserProfile profile) {
    user = profile;
    guest = false;
    notifyListeners();
  }

  void continueAsGuest() {
    guest = true;
    notifyListeners();
  }

  void signOut() {
    user = null;
    guest = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  bool isVerseLiked(int id) => likedVerses.contains(id);

  void toggleVerseLike(int id) {
    final liked = likedVerses.add(id);
    if (!liked) likedVerses.remove(id);
    repo.likeVerse(id, liked).ignore();
    notifyListeners();
  }

  void openedSong(Song song) {
    recentSongs.removeWhere((s) => s.id == song.id);
    recentSongs.insert(0, song);
    if (recentSongs.length > 12) recentSongs.removeLast();
    notifyListeners();
  }

  void toggleDownload(int id) {
    downloadedSongs.contains(id) ? downloadedSongs.remove(id) : downloadedSongs.add(id);
    notifyListeners();
  }

  void setLyricsScale(double v) {
    lyricsScale = v.clamp(0.8, 1.8);
    notifyListeners();
  }

  void toggleSavedSong(int id) {
    savedSongs.contains(id) ? savedSongs.remove(id) : savedSongs.add(id);
    notifyListeners();
  }

  void toggleRsvp(int id) {
    rsvps.contains(id) ? rsvps.remove(id) : rsvps.add(id);
    notifyListeners();
  }

  Future<void> prayFor(int id) async {
    if (prayedFor.contains(id)) return;
    prayedFor.add(id);
    notifyListeners();
    await repo.prayFor(id);
  }

  /// The sermon page's inline note, kept as a Note with the sermon's speaker and date so it
  /// shows up and filters in Notes.
  void setSermonNote({required int sermonId, required String title, required String speaker, required DateTime date, required String body}) {
    final existing = noteForSermon(sermonId);
    final note = (existing ??
            Note(id: newNoteId(), title: title, body: '', date: date, speaker: speaker, sermonId: sermonId, updated: DateTime.now()))
        .copyWith(body: body);
    notes.removeWhere((n) => n.id == note.id);
    if (body.trim().isNotEmpty) notes.add(note.copyWith(updated: DateTime.now()));
    _saveNotes();
    // No notifyListeners: the note field owns its text, and rebuilding while typing would move the caret.
  }

  void markNotificationsRead(Iterable<int> ids) {
    readNotifications.addAll(ids);
    notifyListeners();
  }

  String get greetingName => user?.name.split(' ').first ?? 'friend';
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
