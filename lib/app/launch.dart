/// Optional launch settings read from the web address, used by the shareable
/// preview, e.g. `index.html?start=songs&book=hymns`.
///
///   start  songs | watch | home | prayer | more   – skips the welcome screen as a guest
///   book   part of a song book title to open first
class LaunchOptions {
  static Map<String, String> get _params {
    try {
      return Uri.base.queryParameters;
    } catch (_) {
      return const {};
    }
  }

  static const tabs = ['songs', 'watch', 'home', 'prayer', 'more'];

  static String? get startTab {
    final t = _params['start']?.toLowerCase();
    return tabs.contains(t) ? t : null;
  }

  static bool get skipWelcome => startTab != null;

  static String? get book => _params['book']?.toLowerCase();
}
