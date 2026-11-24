/// App-wide configuration.
///
/// Pass values at build time, for example:
///   flutter run --dart-define=API_BASE_URL=https://your-api-host
///
/// When [apiBaseUrl] is empty the app runs in demo mode with built-in
/// sample content (see `lib/data/mock_repository.dart`).
class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Church id used by album/song endpoints (`GetAlbumsByChurchId?id=`).
  static const int churchId =
      int.fromEnvironment('CHURCH_ID', defaultValue: 1);

  /// Online giving page (e.g. a Stripe Payment Link: https://buy.stripe.com/...).
  /// Left empty until the church shares its public giving link.
  static const String givingUrl =
      String.fromEnvironment('GIVING_URL', defaultValue: '');

  static const String youtubeChannelUrl = String.fromEnvironment(
    'YOUTUBE_URL',
    defaultValue: 'https://www.youtube.com/results?search_query=Bethel+Prayer+House+Naperville',
  );

  static const String churchName = 'Bethel Prayer House';
  static const String churchCity = 'Naperville, IL';

  static bool get isDemo => apiBaseUrl.isEmpty;
}
