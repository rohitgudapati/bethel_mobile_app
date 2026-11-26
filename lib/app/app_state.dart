import 'package:flutter/material.dart';

import '../data/api_repository.dart';
import '../data/firebase_repository.dart';
import '../data/mock_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'config.dart';
import 'launch.dart';

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
