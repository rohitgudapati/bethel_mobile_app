import 'package:flutter/material.dart';

import '../data/api_repository.dart';
import '../data/mock_repository.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'config.dart';

/// Small app-wide state: data source, signed-in user, theme and a few
/// personal toggles. Exposed to widgets through [AppScope].
class AppState extends ChangeNotifier {
  AppState({BethelRepository? repository})
      : repo = repository ?? (AppConfig.isDemo ? MockRepository() : ApiRepository());

  final BethelRepository repo;

  UserProfile? user;
  bool guest = false;
  ThemeMode themeMode = ThemeMode.light;
  bool verseLiked = false;
  final Set<int> savedSongs = {};
  final Set<int> prayedFor = {};
  final Set<int> rsvps = {};

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

  void toggleVerseLike(int id) {
    verseLiked = !verseLiked;
    repo.likeVerse(id, verseLiked).ignore();
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

  String get greetingName => user?.name.split(' ').first ?? 'friend';
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
