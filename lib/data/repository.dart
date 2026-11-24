import 'models.dart';

/// Everything the UI needs from the backend.
///
/// Two implementations:
///  * [MockRepository] – built-in sample content for demos and design work.
///  * [ApiRepository]  – talks to the Bethel ASP.NET API (`/api/...`).
abstract class BethelRepository {
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp(String name, String email, String password);

  Future<DailyVerse> todayVerse();
  Future<void> likeVerse(int id, bool liked);

  Future<List<Sermon>> sermons();
  Future<List<ChurchEvent>> events();
  Future<List<LiveStream>> liveStreams();
  Future<List<Ministry>> ministries();
  Future<List<Album>> albums();
  Future<List<Song>> trendingSongs();
  Future<List<Song>> songsForAlbum(int albumId);
  Future<List<Book>> books();
  Future<List<GalleryPicture>> pictures();

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
}
