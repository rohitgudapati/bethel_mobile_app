import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/config.dart';
import 'church_content.dart';
import 'mock_repository.dart';
import 'models.dart';
import 'repository.dart';

/// Talks to the Bethel Prayer House ASP.NET API (`bethel_app_backend`).
///
/// Routes follow `api/[controller]/[action]`, e.g. `api/EventApi/GetAllEvents`.
/// Paged endpoints return `{ pageSize, totalPages, currentPage, data: [...] }`.
/// JSON keys are camelCase (ASP.NET default). Parsing is tolerant: unknown or
/// missing fields fall back to sensible defaults so a schema tweak on the
/// server won't crash the app.
class ApiRepository implements BethelRepository {
  ApiRepository({String? baseUrl, http.Client? client})
      : _base = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;
  String? _token;

  // Content the API does not provide yet (reading plan) comes from here.
  final _fallback = MockRepository();
  final List<PrayerRequest> _mySubmitted = [];

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) => Uri.parse('$_base/api/$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final res = await _client.get(_uri(path, query), headers: _headers);
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  Future<dynamic> _postForm(String path, Map<String, String> fields, [Map<String, dynamic>? query]) async {
    final req = http.MultipartRequest('POST', _uri(path, query))
      ..headers.addAll(_headers)
      ..fields.addAll(fields);
    final res = await http.Response.fromStream(await _client.send(req));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  static List<Map<String, dynamic>> _list(dynamic json) {
    final raw = json is Map ? (json['data'] ?? json['Data'] ?? json['items'] ?? const []) : json;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }

  static String _s(Map<String, dynamic> m, List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && '$v'.trim().isNotEmpty) return '$v';
    }
    return fallback;
  }

  static int _i(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is int) return v;
      if (v is String && int.tryParse(v) != null) return int.parse(v);
    }
    return 0;
  }

  static DateTime _d(Map<String, dynamic> m, List<String> keys) => DateTime.tryParse(_s(m, keys)) ?? DateTime.now();

  // ---------------------------------------------------------------- auth

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final json = await _get('UserApi/SignIn', {'email': email, 'password': password});
    final m = (json as Map).cast<String, dynamic>();
    final token = _s(m, ['token']);
    if (token.isEmpty) throw _s(m, ['statusMessage'], 'Sign in failed.');
    _token = token;
    return UserProfile(name: email.split('@').first, email: email, token: token);
  }

  @override
  Future<UserProfile> signUp(String name, String email, String password) async {
    await _postForm('UserApi/SignUp', {'Name': name, 'Email': email, 'Password': password});
    return signIn(email, password);
  }

  // The .NET API has no phone sign-in.
  @override
  Future<void> sendPhoneCode(String phone) => Future.error('Phone sign-in isn\'t available yet. Please use email.');

  @override
  Future<UserProfile> verifyPhoneCode(String code, {String name = ''}) =>
      Future.error('Phone sign-in isn\'t available yet. Please use email.');

  // The .NET API has no Apple/Google sign-in or password reset.
  @override
  Future<UserProfile> signInWithProvider(String provider) =>
      Future.error('This sign-in option isn\'t available yet. Please use email.');

  @override
  Future<void> sendPasswordReset(String email) =>
      Future.error('Password reset isn\'t available yet. Please contact the church office.');

  @override
  Future<UserProfile> updateName(String name) async => UserProfile(name: name.trim(), email: '', token: _token);

  // ---------------------------------------------------------------- content

  @override
  Future<DailyVerse> todayVerse() async {
    final json = await _get('DailyVerseAPI/GetTodayVerse');
    final m = json is List ? (json.first as Map).cast<String, dynamic>() : (json as Map).cast<String, dynamic>();
    return DailyVerse(
      id: _i(m, ['dailyVerseId']),
      date: _d(m, ['dateToBePublish']),
      image: _s(m, ['presignedUrl']),
      likes: _i(m, ['countOfLikes']),
    );
  }

  @override
  Future<void> likeVerse(int id, bool liked) =>
      _postForm('DailyVerseAPI/LikeDailyVerse', const {}, {'id': id, 'isLiked': liked});

  @override
  Future<List<Sermon>> sermons() async {
    final json = await _get('SermonApi/GetAllSermons', {'page': 1, 'pageSize': 20});
    return _list(json)
        .map((m) => Sermon(
              id: _i(m, ['sermonId']),
              title: _s(m, ['sermonTitle'], 'Sermon'),
              preacher: _s(m, ['sermonHostName']),
              date: _d(m, ['sermonDate']),
              image: _s(m, ['presignedUrl', 'sermonPicture'], 'assets/sermon-hero.png'),
              videoUrl: _s(m, ['sermonVideo']),
              description: _s(m, ['sermonInfo']),
            ))
        .toList();
  }

  @override
  Future<List<ChurchEvent>> events() async {
    final json = await _get('EventApi/GetAllEvents', {'page': 1, 'pageSize': 20});
    return _list(json).map((m) {
      final speakers = (m['speakers'] as List?)
              ?.whereType<Map>()
              .map((s) => '${s['speakerName'] ?? ''}')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];
      return ChurchEvent(
        id: _i(m, ['eventId']),
        title: _s(m, ['eventTitle'], 'Event'),
        date: _d(m, ['eventDate']),
        time: _s(m, ['eventTime']),
        venue: _s(m, ['venueDate']),
        description: _s(m, ['description']),
        image: _s(m, ['presignedUrl'], 'assets/church.jpg'),
        speakers: speakers,
      );
    }).toList();
  }

  @override
  Future<List<LiveStream>> liveStreams() async {
    final json = await _get('LiveStreamApi/GetAllLiveStreamings', {'page': 1, 'pageSize': 10});
    return _list(json)
        .map((m) => LiveStream(
              id: _i(m, ['liveStreamId']),
              title: _s(m, ['liveStreamTitle'], 'Live stream'),
              description: _s(m, ['liveStreamDescription']),
              image: _s(m, ['presignedUrl', 'liveStreamThumbNail'], 'assets/videoimage.png'),
              youtubeUrl: _s(m, ['youTubeLink'], AppConfig.youtubeChannelUrl),
            ))
        .toList();
  }

  @override
  Future<List<Ministry>> ministries() async {
    final json = await _get('MinistryApi/GetAllMinistries');
    return _list(json)
        .map((m) => Ministry(
              id: _i(m, ['ministryId']),
              name: _s(m, ['ministryName'], 'Ministry'),
              info: _s(m, ['ministryInfo']),
              image: _s(m, ['presignedUrl'], 'assets/ministriesimage.png'),
            ))
        .toList();
  }

  @override
  Future<List<Album>> albums() async {
    final json = await _get('AlbumApi/GetAlbumsByChurchId', {'id': AppConfig.churchId});
    return _list(json)
        .map((m) => Album(
              id: _i(m, ['albumId']),
              title: _s(m, ['albumName'], 'Album'),
              artist: _s(m, ['albumBelongsTo']),
              image: _s(m, ['presignedUrl'], 'assets/church.jpg'),
              // Every album in the backend is a numbered song book (e.g. Songs of Zion).
              isSongBook: true,
            ))
        .toList();
  }

  Song _song(Map<String, dynamic> m, [int number = 0]) => Song(
        id: _i(m, ['songId']),
        number: number,
        title: _s(m, ['songTitle', 'songName', 'mainTitle'], 'Song'),
        artist: _s(m, ['singerName']),
        image: _s(m, ['presignedUrl', 'albumPic', 'albumPresignedUrl'], 'assets/church.jpg'),
        albumId: _i(m, ['albumId']),
        albumTitle: _s(m, ['albumName']),
      );

  @override
  Future<List<Song>> trendingSongs() async {
    final json =
        await _get('AlbumApi/GetTrendingSongsByChurchId', {'id': AppConfig.churchId, 'page': 1, 'pageSize': 20});
    return _list(json).map((m) => _song(m)).toList();
  }

  @override
  Future<List<Song>> songsForAlbum(int albumId) async {
    // Note: the backend names this query parameter `SongId` but it is the album id.
    final json = await _get('AlbumApi/GetSongsByAlbumId', {'SongId': albumId});
    final list = _list(json);
    return [for (var i = 0; i < list.length; i++) _song(list[i], i + 1)];
  }

  @override
  Future<Song> songDetail(Song song) async {
    final langs = _list(await _get('AlbumApi/LanguageVersionsBySongId', {'id': song.id}));
    final lyrics = <String, String>{};
    String? lyricist;
    for (final l in langs) {
      final name = _s(l, ['languageName', 'value']);
      if (name.isEmpty) continue;
      final v = await _get('AlbumApi/SongVerByLanVNameandSongId', {'name': name, 'id': song.id});
      final m = v is List && v.isNotEmpty
          ? (v.first as Map).cast<String, dynamic>()
          : (v is Map ? v.cast<String, dynamic>() : null);
      if (m == null) continue;
      final text = _s(m, ['lyrics']);
      if (text.isNotEmpty) lyrics[name] = text;
      lyricist ??= _s(m, ['lyricsWritter', 'author']);
    }
    String? chords;
    try {
      final c = await _get('AlbumApi/GetKeyBoardChordsBySongId', {'id': song.id});
      if (c is Map) chords = _s(c.cast<String, dynamic>(), ['keyBoardChordsText']);
    } catch (_) {}
    return song.withLyrics(lyrics, lyricist: lyricist, chords: (chords?.isEmpty ?? true) ? null : chords);
  }

  /// The old API has no elders endpoint; uses the website content.
  @override
  Future<List<Elder>> elders() async => churchElders;

  @override
  Future<List<Book>> books() async {
    final json = await _get('BookApi/GetBooksListForMobiles', {'page': 1, 'pageSize': 20});
    return _list(json)
        .map((m) => Book(
              id: _i(m, ['bookId']),
              title: _s(m, ['bookName'], 'Book'),
              author: _s(m, ['authorName', 'bookAuthorName']),
              image: _s(m, ['presignedUrl', 'bookPicPresignedUrl'], 'assets/bookimage3.png'),
              description: _s(m, ['bookInfo']),
            ))
        .toList();
  }

  @override
  Future<List<GalleryPicture>> pictures() async {
    final json = await _get('PictureApi/GetAllPictures', {'page': 1, 'pageSize': 30});
    return _list(json)
        .map((m) => GalleryPicture(id: _i(m, ['pictureId']), image: _s(m, ['presignedUrl'], 'assets/picture1.png')))
        .toList();
  }

  // ---------------------------------------------------------------- church & resources

  @override
  Future<ChurchInfo> churchInfo() async {
    final json = await _get('ChurchApi/ChurchDetailsById', {'id': AppConfig.churchId});
    final m = json is List ? (json.first as Map).cast<String, dynamic>() : (json as Map).cast<String, dynamic>();
    return ChurchInfo(
      name: _s(m, ['churchName'], AppConfig.churchName),
      address: _s(m, ['churchAddress'], AppConfig.churchCity),
      country: 'United States',
    );
  }

  @override
  Future<List<DailyVerse>> verseArchive() async {
    final json = await _get('DailyVerseAPI/GetAllDailyVerses', {'page': 1, 'pageSize': 20});
    return _list(json)
        .map((m) => DailyVerse(
              id: _i(m, ['dailyVerseId']),
              date: _d(m, ['dateToBePublish']),
              image: _s(m, ['presignedUrl']),
              likes: _i(m, ['countOfLikes']),
              shares: _i(m, ['countOfShares']),
            ))
        .toList();
  }

  @override
  Future<void> shareVerse(int id) => _postForm('DailyVerseAPI/ShareDailyVerse', const {}, {'id': id, 'isShared': true});

  @override
  Future<List<SermonComment>> sermonComments(int sermonId) async {
    final json = await _get('SermonApi/GetSermonCommentsBySermonId', {'id': sermonId});
    return _list(json)
        .map((m) =>
            SermonComment(name: _s(m, ['userName'], 'Member'), text: _s(m, ['comment']), at: _d(m, ['createdAt'])))
        .toList();
  }

  @override
  Future<void> addSermonComment(int sermonId, String text) =>
      _postForm('SermonApi/SaveCommentForSermon', const {}, {'id': sermonId, 'comment': text});

  List<MediaItem> _media(dynamic json, String prefix) => _list(json)
      .map((m) => MediaItem(
            id: _i(m, ['${prefix}Id']),
            title: _s(m, ['${prefix}Title', '${prefix}ServiceName'], 'Video'),
            info: _s(m, ['${prefix}Info']),
            image: _s(m, ['presignedUrl', '${prefix}Picture'], 'assets/videoimage.png'),
            videoUrl: _s(m, ['${prefix}Video', '${prefix}ServiceURL']),
          ))
      .toList();

  @override
  Future<List<MediaItem>> shorts() async =>
      _media(await _get('ShortsApi/GetAllShortVideos', {'page': 1, 'pageSize': 20}), 'short');

  @override
  Future<List<MediaItem>> interviews() async =>
      _media(await _get('InterviewApi/GetAllInterviewVideos', {'page': 1, 'pageSize': 20}), 'interview');

  @override
  Future<List<MediaItem>> testimonies() async => _media(await _get('TestimoniesApi/GetAllTestimonies'), 'testimony');

  @override
  Future<List<ChurchService>> services() async {
    final json = await _get('ServiceApi/GetAllService', {'page': 1, 'pageSize': 20});
    return _list(json)
        .map((m) => ChurchService(
              id: _i(m, ['serviceId']),
              name: _s(m, ['serviceName'], 'Service'),
              description: _s(m, ['description']),
              image: _s(m, ['presignedUrl'], 'assets/church.jpg'),
            ))
        .toList();
  }

  @override
  Future<void> bookService(int serviceId, {required String name, required String phone, required String note}) =>
      _postForm('ServiceApi/BookTheServiceForUser', {'Name': name, 'Phone': phone, 'Comment': note}, {'id': serviceId});

  // ---------------------------------------------------------------- prayer

  @override
  Future<List<PrayerRequest>> prayerWall() async => List.of(_mySubmitted);

  @override
  Future<PrayerRequest> submitPrayer({
    required String name,
    required String email,
    required String phone,
    required String request,
    required String category,
    required bool shareOnWall,
  }) async {
    await _postForm('PrayerRequestAPI/SavePrayerRequest', {
      'Name': name,
      'Email': email,
      'Phone': phone,
      'Prayer_Request': request,
    });
    final p = PrayerRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name.isEmpty ? 'Anonymous' : name,
      request: request,
      category: category,
      createdAt: DateTime.now(),
      isMine: true,
    );
    _mySubmitted.insert(0, p);
    return p;
  }

  @override
  Future<void> prayFor(int prayerId) async {}

  @override
  Future<List<BiblePassage>> readingPlan() => _fallback.readingPlan();
}

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);
  @override
  String toString() => status == 401 ? 'Please sign in to continue.' : 'Server error ($status).';
}
