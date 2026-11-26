import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value store on the phone for things that must survive a restart:
/// Bible position, highlights, reading plan progress and notes (until they sync to Firebase).
class LocalStore {
  LocalStore._(this._prefs);
  final SharedPreferences? _prefs;

  static Future<LocalStore> open() async {
    try {
      return LocalStore._(await SharedPreferences.getInstance());
    } catch (_) {
      return LocalStore._(null); // Nothing is saved, but the app still runs.
    }
  }

  /// An in-memory store for tests and previews.
  static LocalStore memory() => LocalStore._(null);

  Object? read(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object? value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }
}
