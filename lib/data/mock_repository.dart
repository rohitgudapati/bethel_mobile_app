import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../app/config.dart';
import '../app/launch.dart';
import 'church_content.dart';
import 'daily_verses.dart';
import 'models.dart';
import 'repository.dart';

/// Sample content for demo mode. Dates are relative to "now" so the demo
/// always looks current. Scripture is KJV (public domain).
class MockRepository implements BethelRepository {
  MockRepository() {
    _wall = [
      PrayerRequest(
        id: 1,
        name: 'Anonymous',
        request: 'Please pray for my mother\'s surgery next week, for the doctors and for a quick recovery.',
        category: 'Healing',
        createdAt: _now.subtract(const Duration(hours: 3)),
        prayedCount: 24,
      ),
      PrayerRequest(
        id: 2,
        name: 'Grace',
        request: 'Starting a new job on Monday. Praying for wisdom, peace and favor with my new team.',
        category: 'Work',
        createdAt: _now.subtract(const Duration(hours: 9)),
        prayedCount: 17,
      ),
      PrayerRequest(
        id: 3,
        name: 'Daniel',
        request: 'For our youth retreat this weekend, that hearts would be open and everyone travels safely.',
        category: 'Church',
        createdAt: _now.subtract(const Duration(days: 1)),
        prayedCount: 41,
      ),
      PrayerRequest(
        id: 4,
        name: 'Anonymous',
        request: 'Pray for restoration in my family and for my brother to come back to faith.',
        category: 'Family',
        createdAt: _now.subtract(const Duration(days: 2)),
        prayedCount: 33,
      ),
    ];
  }

  static final DateTime _now = DateTime.now();
  static DateTime _day(int offset) => DateTime(_now.year, _now.month, _now.day).add(Duration(days: offset));
  static DateTime get _lastSunday => _day(-(_now.weekday % 7));
  static DateTime get _nextSunday => _day(7 - (_now.weekday % 7));

  late List<PrayerRequest> _wall;
  int _nextId = 100;

  Future<T> _delay<T>(T value) => Future.delayed(const Duration(milliseconds: 350), () => value);

  @override
  Future<UserProfile> signIn(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      return Future.error('Please enter your email and password.');
    }
    final local = email.split('@').first;
    final name = local.isEmpty ? 'Friend' : '${local[0].toUpperCase()}${local.substring(1)}';
    return _delay(UserProfile(name: name, email: email.trim()));
  }

  @override
  Future<UserProfile> signUp(String name, String email, String password) =>
      _delay(UserProfile(name: name.trim(), email: email.trim()));

  @override
  Future<DailyVerse> todayVerse() {
    // A different verse every day (see daily_verses.dart), with sample counts.
    final v = builtInVerse(DateTime.now());
    return _delay(DailyVerse(
      id: v.id,
      date: v.date,
      text: v.text,
      reference: v.reference,
      likes: 40 + v.id % 90,
      shares: 10 + v.id % 30,
      views: 900 + v.id % 1000,
    ));
  }

  @override
  Future<void> likeVerse(int id, bool liked) => _delay(null);

  @override
  Future<void> shareVerse(int id) => _delay(null);

  @override
  Future<List<DailyVerse>> verseArchive() => _delay([
        DailyVerse(
            id: 11,
            date: _day(-1),
            image: 'assets/verse1.png',
            reference: 'Romans 1:16',
            likes: 4241,
            shares: 217,
            views: 18300),
        DailyVerse(
            id: 12,
            date: _day(-2),
            image: 'assets/verse2.png',
            reference: 'Romans 1:16',
            likes: 3870,
            shares: 190,
            views: 15200),
        DailyVerse(
            id: 13,
            date: _day(-3),
            image: 'assets/verse3.png',
            reference: 'Romans 1:16',
            likes: 2954,
            shares: 172,
            views: 12900),
        DailyVerse(
            id: 14,
            date: _day(-4),
            image: 'assets/doe.png',
            reference: 'Isaiah 40:31',
            likes: 2102,
            shares: 98,
            views: 9400),
      ]);

  @override
  Future<ChurchInfo> churchInfo() => _delay(const ChurchInfo(
        name: AppConfig.churchName,
        address: AppConfig.churchAddress,
        country: 'United States',
        phone: '(818) 610-9650 · (630) 854-7335',
        email: 'info@bethelph.com',
      ));

  final Map<int, List<SermonComment>> _comments = {
    1: [
      SermonComment(
          name: 'Grace',
          text: 'This message was exactly what I needed this week. Thank you, Pastor!',
          at: _now.subtract(const Duration(days: 2))),
      SermonComment(
          name: 'Daniel', text: 'Sharing this with my small group.', at: _now.subtract(const Duration(days: 1))),
    ],
  };

  @override
  Future<List<SermonComment>> sermonComments(int sermonId) => _delay(List.of(_comments[sermonId] ?? const []));

  @override
  Future<void> addSermonComment(int sermonId, String text) async {
    (_comments[sermonId] ??= []).add(SermonComment(name: 'You', text: text, at: DateTime.now()));
  }

  @override
  Future<List<MediaItem>> shorts() => _delay(const [
        MediaItem(id: 1, title: 'A one-minute prayer for peace', image: 'assets/shortsimage.png', duration: '0:58'),
        MediaItem(id: 2, title: 'Why we pray together', image: 'assets/pray.png', duration: '0:45'),
        MediaItem(id: 3, title: 'Worship night moments', image: 'assets/live_event.jpeg', duration: '0:52'),
        MediaItem(id: 4, title: 'Verse for your week', image: 'assets/verse2.png', duration: '0:30'),
      ]);

  @override
  Future<List<MediaItem>> interviews() => _delay(const [
        MediaItem(
            id: 1,
            title: 'How Bethel began',
            info: 'Our founding members share the story of the first prayer meetings in Naperville.',
            image: 'assets/picture1.png',
            duration: '18 min'),
        MediaItem(
            id: 2,
            title: 'Raising kids in faith',
            info: 'A conversation with our children\'s ministry team.',
            image: 'assets/ministriesimage.png',
            duration: '22 min'),
      ]);

  @override
  Future<List<MediaItem>> testimonies() => _delay(const [
        MediaItem(
            id: 1,
            title: 'Healed and restored',
            info: 'A church member shares how God carried their family through illness.',
            image: 'assets/doe.png',
            duration: '9 min'),
        MediaItem(
            id: 2,
            title: 'From doubt to faith',
            info: 'A student\'s journey back to Jesus during college.',
            image: 'assets/sermon-hero.png',
            duration: '7 min'),
        MediaItem(
            id: 3,
            title: 'God provided a home',
            info: 'A new family to Naperville on finding a church home.',
            image: 'assets/picture1.png',
            duration: '6 min'),
      ]);

  @override
  Future<List<ChurchService>> services() => _delay(churchServices);

  @override
  Future<void> bookService(int serviceId, {required String name, required String phone, required String note}) =>
      _delay(null);

  @override
  Future<List<Sermon>> sermons() => _delay([
        Sermon(
          id: 1,
          title: 'Not Ashamed of the Gospel',
          preacher: 'Senior Pastor',
          date: _lastSunday,
          image: 'assets/videoimage.png',
          series: 'Romans: The Power of God',
          duration: '48 min',
          description: 'A walk through Romans 1:16-17 on the power of the gospel to change every life it touches, '
              'and what it means to live unashamed in Naperville and beyond.',
          videoUrl: AppConfig.youtubeChannelUrl,
        ),
        Sermon(
          id: 2,
          title: 'Peace That Guards Your Heart',
          preacher: 'Associate Pastor',
          date: _lastSunday.subtract(const Duration(days: 7)),
          image: 'assets/pray.png',
          series: 'Philippians',
          duration: '41 min',
          description: 'Philippians 4:6-7. Trading anxiety for prayer and thanksgiving.',
        ),
        Sermon(
          id: 3,
          title: 'The Good Shepherd',
          preacher: 'Guest Speaker',
          date: _lastSunday.subtract(const Duration(days: 14)),
          image: 'assets/church.jpg',
          series: 'Psalms for Every Season',
          duration: '52 min',
          description: 'Psalm 23 and the God who leads, restores and stays with us in every valley.',
        ),
        Sermon(
          id: 4,
          title: 'Faith That Lifts Its Hands',
          preacher: 'Worship Pastor',
          date: _lastSunday.subtract(const Duration(days: 21)),
          image: 'assets/shortsimage.png',
          series: 'Psalms for Every Season',
          duration: '37 min',
          description: 'Worship as a response to who God is, not only to what He has done.',
        ),
      ]);

  @override
  Future<List<ChurchEvent>> events() {
    // Regular meetings from the church website, on their next dates.
    final nextFriday = _day(((5 - _now.weekday) % 7) == 0 ? 7 : (5 - _now.weekday) % 7);
    var firstFriday = DateTime(_now.year, _now.month, 1);
    while (firstFriday.weekday != DateTime.friday) {
      firstFriday = firstFriday.add(const Duration(days: 1));
    }
    if (firstFriday.isBefore(_day(0))) {
      firstFriday = DateTime(_now.year, _now.month + 1, 1);
      while (firstFriday.weekday != DateTime.friday) {
        firstFriday = firstFriday.add(const Duration(days: 1));
      }
    }
    return _delay(<ChurchEvent>[
      ChurchEvent(
        id: 1,
        title: 'Sunday Worship Service',
        date: _nextSunday,
        time: '3:00 PM',
        venue: AppConfig.churchName,
        description: 'Worship, a message from the Word, Sunday School for children, and a fellowship dinner together. '
            'Bring your family and friends. All are welcome!',
        image: 'assets/church/worship.jpg',
        speakers: const ['Bro. Moses Polugari', 'Bro. Vinod Somepalli'],
        category: 'Worship',
      ),
      ChurchEvent(
        id: 2,
        title: 'Prayer Meeting',
        date: nextFriday,
        time: '7:30 PM',
        venue: AppConfig.churchName,
        description: 'Corporate prayer and intercession for church and community needs.',
        image: 'assets/pray.png',
        category: 'Prayer',
      ),
      ChurchEvent(
        id: 3,
        title: 'Youth Meeting',
        date: _nextSunday,
        time: '6:30 PM',
        venue: AppConfig.churchName,
        description: 'Practical teaching, small group discussions and mentorship for young people.',
        image: 'assets/picture2.png',
        category: 'Youth',
      ),
      ChurchEvent(
        id: 4,
        title: 'All Night Prayer',
        date: firstFriday,
        time: 'All night',
        venue: AppConfig.churchName,
        description: 'Extended time in God\'s presence: corporate intercession and worship, fellowship and renewal.',
        image: 'assets/church/building.jpg',
        category: 'Prayer',
      ),
    ]..sort((a, b) => a.date.compareTo(b.date)));
  }

  @override

  /// Demo: live only during the Sunday service (3:00–5:30 PM), like the real
  /// YouTube check. Otherwise nothing is streaming and the app shows the next service.
  Future<List<LiveStream>> liveStreams() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, AppConfig.sundayServiceHour);
    final duringService = now.weekday == DateTime.sunday &&
        !now.isBefore(start) &&
        now.isBefore(start.add(const Duration(hours: 2, minutes: 30)));
    if (!duringService && !LaunchOptions.forceLive) return _delay(const <LiveStream>[]);
    return _delay([
      const LiveStream(
        id: 1,
        title: 'Sunday Worship Service – Live',
        description: '87 watching now',
        image: 'assets/church/worship.jpg',
        youtubeUrl: '${AppConfig.youtubeChannelUrl}/live',
        isLive: true,
      ),
    ]);
  }

  @override
  Future<List<Ministry>> ministries() => _delay(churchMinistries);

  @override
  Future<List<Elder>> elders() => _delay(churchElders);

  @override
  Future<List<Album>> albums() async => _delay([
        Album(
            id: 10,
            title: 'Songs of Zion',
            image: 'assets/church.jpg',
            artist: 'Telugu song book',
            language: 'Telugu',
            songCount: (await _zionSongs()).length,
            isSongBook: true),
        if ((await _bundledBook(_bethelEnglish)).isNotEmpty)
          Album(
              id: _bethelEnglish,
              title: 'Bethel English Songs',
              image: 'assets/church/worship.jpg',
              artist: 'English worship songs',
              language: 'English',
              songCount: (await _bundledBook(_bethelEnglish)).length,
              isSongBook: true),
        Album(id: 1, title: 'Sunday Praise', image: 'assets/live_event.jpeg', artist: 'Bethel Worship'),
        Album(id: 2, title: 'Kids Worship', image: 'assets/ministriesimage.png', artist: 'Children\'s Ministry'),
      ]);

  static const _zion = 10;
  static const _bethelEnglish = 12;

  static const _songs = <Song>[
    // Songs of Zion: titles from the original app. Lyrics come from the song database (API).
    Song(
      id: 101,
      number: 1,
      title: 'Aadhaaram Naaku Aadhaaram',
      artist: 'Bethel Worship',
      lyricist: 'Bonigala Babu Rao',
      image: 'assets/church.jpg',
      albumId: _zion,
      albumTitle: 'Songs of Zion',
    ),
    Song(
      id: 102,
      number: 2,
      title: 'Aagi Mandimchu',
      artist: 'Manoju Varma, Karthik',
      lyricist: 'Manoju Varma',
      image: 'assets/godsplan.png',
      albumId: _zion,
      albumTitle: 'Songs of Zion',
    ),
  ];

  /// Songs of Zion, loaded from `assets/songs/songs_of_zion.json` when it is bundled
  /// (the file is git-ignored). Without it, the two sample titles above are used.
  /// Song books bundled as JSON in assets/songs/ (git-ignored; see its README).
  /// Without the file, Songs of Zion falls back to the two sample titles above
  /// and other books are hidden.
  final Map<int, List<Song>> _bookCache = {};

  static const _bundledBooks = {
    _zion: ('assets/songs/songs_of_zion.json', 'Songs of Zion', 100000),
    _bethelEnglish: ('assets/songs/bethel_english.json', 'Bethel English Songs', 200000),
  };

  Future<List<Song>> _bundledBook(int bookId) async {
    final cached = _bookCache[bookId];
    if (cached != null) return cached;
    final (file, title, idBase) = _bundledBooks[bookId]!;
    List<Song> songs;
    try {
      final raw = jsonDecode(utf8.decode((await rootBundle.load(file)).buffer.asUint8List())) as List;
      const images = [
        'assets/church/worship.jpg',
        'assets/picture3.png',
        'assets/pray.png',
        'assets/doe.png',
        'assets/sermon-hero.png'
      ];
      songs = [
        for (final m in raw.cast<Map<String, dynamic>>())
          Song(
            id: idBase + (m['n'] as int),
            number: m['n'] as int,
            title: m['t'] as String,
            altTitle: (m['tt'] as String?) ?? '',
            reference: (m['r'] as String?) ?? '',
            artist: '',
            lyricist: (m['a'] as String?) ?? '',
            image: images[(m['n'] as int) % images.length],
            albumId: bookId,
            albumTitle: title,
            lyrics: {
              if ((m['te'] as String?)?.isNotEmpty ?? false) 'Telugu': m['te'] as String,
              if ((m['en'] as String?)?.isNotEmpty ?? false) 'English': m['en'] as String,
            },
          ),
      ];
    } catch (_) {
      songs = _songs.where((s) => s.albumId == bookId).toList();
    }
    return _bookCache[bookId] = songs;
  }

  Future<List<Song>> _zionSongs() => _bundledBook(_zion);

  @override
  Future<List<Song>> trendingSongs() async {
    final zion = await _zionSongs();
    final english = await _bundledBook(_bethelEnglish);
    Song? pick(List<Song> book, int n) => book.where((s) => s.number == n).firstOrNull;
    return _delay([
      ...[pick(zion, 1), pick(english, 1), pick(zion, 500), pick(english, 30), pick(zion, 2), pick(english, 60)]
          .whereType<Song>(),
    ]);
  }

  @override
  Future<List<Song>> songsForAlbum(int albumId) async {
    if (_bundledBooks.containsKey(albumId)) return _delay(await _bundledBook(albumId));
    final list = _songs.where((s) => s.albumId == albumId).toList();
    // Albums that aren't song books reuse a few Bethel English songs in the demo.
    return _delay(list.isEmpty ? (await _bundledBook(_bethelEnglish)).take(5).toList() : list);
  }

  @override
  Future<Song> songDetail(Song song) async => _delay([
        ..._songs,
        ...await _zionSongs(),
        ...await _bundledBook(_bethelEnglish)
      ].firstWhere((s) => s.id == song.id, orElse: () => song));

  @override
  Future<List<Book>> books() => _delay(const [
        Book(
            id: 1,
            title: 'Uncle John',
            author: 'G. J. Whyte-Melville',
            image: 'assets/bookimage3.png',
            description: 'A classic novel from 1898, available to read in the app.'),
        Book(
            id: 2,
            title: 'A Walk with John',
            author: 'F. E. Henderson',
            image: 'assets/bookimage2.png',
            description: 'A biography from the church library.'),
      ]);

  @override
  Future<List<GalleryPicture>> pictures() => _delay(const [
        GalleryPicture(id: 1, image: 'assets/picture1.png', caption: 'Church family Sunday'),
        GalleryPicture(id: 2, image: 'assets/master4.png', caption: 'Anniversary celebration'),
        GalleryPicture(id: 3, image: 'assets/ministriesimage.png', caption: 'Kids camp'),
        GalleryPicture(id: 4, image: 'assets/live_event.jpeg', caption: 'Night of worship'),
        GalleryPicture(id: 5, image: 'assets/church.jpg', caption: 'Sanctuary'),
        GalleryPicture(id: 6, image: 'assets/pray.png', caption: 'Prayer meeting'),
      ]);

  @override
  Future<List<PrayerRequest>> prayerWall() => _delay(List.of(_wall));

  @override
  Future<PrayerRequest> submitPrayer({
    required String name,
    required String email,
    required String phone,
    required String request,
    required String category,
    required bool shareOnWall,
  }) {
    final p = PrayerRequest(
      id: _nextId++,
      name: shareOnWall && name.trim().isNotEmpty ? name.trim().split(RegExp(r'\s+')).first : 'Anonymous',
      request: request.trim(),
      category: category,
      createdAt: DateTime.now(),
      isMine: true,
    );
    if (shareOnWall) _wall = [p, ..._wall];
    return _delay(p);
  }

  @override
  Future<void> prayFor(int prayerId) async {
    _wall = [for (final p in _wall) p.id == prayerId ? p.copyWith(prayedCount: p.prayedCount + 1) : p];
  }

  @override
  Future<List<BiblePassage>> readingPlan() => _delay(const [
        BiblePassage(reference: 'Psalm 23', title: 'The Lord is my shepherd', verses: [
          'The LORD is my shepherd; I shall not want.',
          'He maketh me to lie down in green pastures: he leadeth me beside the still waters.',
          'He restoreth my soul: he leadeth me in the paths of righteousness for his name\'s sake.',
          'Yea, though I walk through the valley of the shadow of death, I will fear no evil: for thou art with me; thy rod and thy staff they comfort me.',
          'Thou preparest a table before me in the presence of mine enemies: thou anointest my head with oil; my cup runneth over.',
          'Surely goodness and mercy shall follow me all the days of my life: and I will dwell in the house of the LORD for ever.',
        ]),
        BiblePassage(reference: 'John 3:16–17', title: 'God so loved the world', verses: [
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
          'For God sent not his Son into the world to condemn the world; but that the world through him might be saved.',
        ]),
        BiblePassage(reference: 'Romans 1:16', title: 'Not ashamed of the gospel', verses: [
          'For I am not ashamed of the gospel of Christ: for it is the power of God unto salvation to every one that believeth; to the Jew first, and also to the Greek.',
        ]),
        BiblePassage(reference: 'Philippians 4:6–7', title: 'The peace of God', verses: [
          'Be careful for nothing; but in every thing by prayer and supplication with thanksgiving let your requests be made known unto God.',
          'And the peace of God, which passeth all understanding, shall keep your hearts and minds through Christ Jesus.',
        ]),
        BiblePassage(reference: 'Isaiah 40:31', title: 'Renewed strength', verses: [
          'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.',
        ]),
      ]);
}
