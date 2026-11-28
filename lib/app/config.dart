/// App-wide configuration.
///
/// Pass values at build time, for example:
///   flutter run --dart-define=API_BASE_URL=https://your-api-host
///
/// When [apiBaseUrl] is empty the app runs in demo mode with built-in
/// sample content (see `lib/data/mock_repository.dart`).
class AppConfig {
  /// `firebase` to use Firebase. Otherwise the old .NET API is used when [apiBaseUrl] is set, else built-in samples.
  static const String backend = String.fromEnvironment('BACKEND', defaultValue: 'demo');

  /// Use the local Firebase emulators (see backend/README.md) instead of the live project.
  static const bool useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  static const String emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '127.0.0.1');

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Church id used by album/song endpoints (`GetAlbumsByChurchId?id=`).
  static const int churchId = int.fromEnvironment('CHURCH_ID', defaultValue: 1);

  /// The church's YouTube channel.
  static const String youtubeChannelUrl =
      String.fromEnvironment('YOUTUBE_URL', defaultValue: 'https://www.youtube.com/@bethelprayerhousenaperville');

  /// Opens whatever the channel is streaming now (or its next scheduled stream).
  static String get youtubeLiveUrl => '$youtubeChannelUrl/live';

  /// Sunday worship starts at 3:00 PM.
  static const int sundayServiceHour = 15;

  static const String churchName = 'Bethel Prayer House';
  static const String churchCity = 'Naperville, IL';
  static const String churchAddress = '7S201 South River Rd, Naperville, IL 60540';

  /// Google Maps Static API key for the map on Home (`--dart-define=MAPS_API_KEY=...`).
  /// Without it, Home shows a photo of the church instead of the map.
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Google Maps pin for the church.
  static String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$churchName, $churchAddress')}';

  /// Privacy policy and terms pages linked from the welcome screen. Empty shows "Link not available yet".
  static const String privacyUrl = String.fromEnvironment('PRIVACY_URL', defaultValue: '');
  static const String termsUrl = String.fromEnvironment('TERMS_URL', defaultValue: '');

  static bool get isFirebase => backend == 'firebase';
  static bool get isDemo => !isFirebase && apiBaseUrl.isEmpty;
}
