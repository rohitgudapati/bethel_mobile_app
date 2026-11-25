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

  /// Online giving page (e.g. a Stripe Payment Link: https://buy.stripe.com/...).
  /// Left empty until the church shares its public giving link.
  static const String givingUrl = String.fromEnvironment('GIVING_URL', defaultValue: '');

  static const String youtubeChannelUrl = String.fromEnvironment(
    'YOUTUBE_URL',
    defaultValue: 'https://www.youtube.com/results?search_query=Bethel+Prayer+House+Naperville',
  );

  static const String churchName = 'Bethel Prayer House';
  static const String churchCity = 'Naperville, IL';

  static bool get isFirebase => backend == 'firebase';
  static bool get isDemo => !isFirebase && apiBaseUrl.isEmpty;
}
