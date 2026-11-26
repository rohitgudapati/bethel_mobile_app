import 'package:flutter/material.dart';

import '../data/api_repository.dart';
import '../data/firebase_repository.dart';
import '../data/mock_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../bible/bible_text.dart';
import 'config.dart';
import 'launch.dart';
import 'local_store.dart';

/// Small app-wide state: data source, signed-in user, theme and a few
/// personal toggles. Exposed to widgets through [AppScope].
class AppState extends ChangeNotifier {
  AppState({BethelRepository? repository})
      : repo = repository ??
            (AppConfig.isFirebase
                ? FirebaseRepository()
                : AppConfig.isDemo
                    ? MockRepository()
                    : ApiRepository());

  final BethelRepository repo;

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

  /// Reading-plan passages marked as read (by reference), shared by Home and the Bible screen.
  final Set<String> readingDone = {};

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

  /// Notes a member writes while watching a sermon, by sermon id.
  final Map<int, String> sermonNotes = {};
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

  void setSermonNote(int sermonId, String note) {
    if (note.trim().isEmpty) {
      sermonNotes.remove(sermonId);
    } else {
      sermonNotes[sermonId] = note;
    }
    // No notifyListeners: the note field owns its text, and rebuilding while typing would move the caret.
  }

  void markPassageRead(String reference) {
    readingDone.add(reference);
    notifyListeners();
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
