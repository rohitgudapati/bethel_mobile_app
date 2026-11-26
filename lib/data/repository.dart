import 'models.dart';

/// Everything the UI needs from the backend.
///
/// Two implementations:
///  * [MockRepository] – built-in sample content for demos and design work.
///  * [ApiRepository]  – talks to the Bethel ASP.NET API (`/api/...`).
abstract class BethelRepository {
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp(String name, String email, String password);

  /// Phone sign-in, step 1: text a 6-digit code to [phone] (E.164, e.g. +16305551234).
  Future<void> sendPhoneCode(String phone);

  /// Phone sign-in, step 2: check the code. [name] is saved for new accounts.
  Future<UserProfile> verifyPhoneCode(String code, {String name = ''});

  /// Sign in with Apple or Google. [provider] is `'apple'` or `'google'`.
  Future<UserProfile> signInWithProvider(String provider);

  /// Emails a password-reset link.
  Future<void> sendPasswordReset(String email);

  /// Saves the name a new member types after verifying (phone, Apple or Google).
  Future<UserProfile> updateName(String name);

  Future<ChurchInfo> churchInfo();

  // Verse of the day
  Future<DailyVerse> todayVerse();
  Future<List<DailyVerse>> verseArchive();
  Future<void> likeVerse(int id, bool liked);
  Future<void> shareVerse(int id);

  // Watch / resources
  Future<List<LiveStream>> liveStreams();
  Future<List<Sermon>> sermons();
  Future<List<SermonComment>> sermonComments(int sermonId);
  Future<void> addSermonComment(int sermonId, String text);
  Future<List<MediaItem>> shorts();
  Future<List<MediaItem>> interviews();
  Future<List<MediaItem>> testimonies();

  // Church life
  Future<List<ChurchEvent>> events();
  Future<List<ChurchService>> services();
  Future<void> bookService(int serviceId, {required String name, required String phone, required String note});
  Future<List<Ministry>> ministries();
  Future<List<Elder>> elders();
  Future<List<Book>> books();
  Future<List<GalleryPicture>> pictures();

  // Songs & song books
  /// Song books and albums. Song books (`isSongBook`) come first.
  Future<List<Album>> albums();
  Future<List<Song>> songsForAlbum(int albumId);
  Future<List<Song>> trendingSongs();

  /// Full song with lyrics in every available language, lyricist and chords.
  Future<Song> songDetail(Song song);

  // Prayer
  /// Public prayer wall. The API has no list endpoint yet, so the API
  /// implementation returns only what this device submitted.
  Future<List<PrayerRequest>> prayerWall();
  Future<PrayerRequest> submitPrayer({
    required String name,
    required String email,
    required String phone,
    required String request,
    required String category,
    required bool shareOnWall,
  });
  Future<void> prayFor(int prayerId);

  Future<List<BiblePassage>> readingPlan();

  /// Newest first. Read state is kept on the device.
  Future<List<NotificationItem>> notifications();
}
