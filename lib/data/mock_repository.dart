import 'models.dart';
import 'repository.dart';

/// Sample content for demo mode. Dates are relative to "now" so the demo
/// always looks current. Scripture is KJV and hymns are public domain.
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
  Future<DailyVerse> todayVerse() => _delay(DailyVerse(
        id: 1,
        date: _now,
        text: 'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; '
            'they shall run, and not be weary; and they shall walk, and not faint.',
        reference: 'Isaiah 40:31',
        image: 'assets/doe.png',
        likes: 128,
      ));

  @override
  Future<void> likeVerse(int id, bool liked) => _delay(null);

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
          videoUrl: 'https://www.youtube.com/',
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
  Future<List<ChurchEvent>> events() => _delay(<ChurchEvent>[
        ChurchEvent(
          id: 1,
          title: 'Sunday Worship Service',
          date: _nextSunday,
          time: '10:30 AM',
          venue: 'Main Sanctuary',
          description: 'Join us for praise, worship and the Word. Children\'s church runs during the message.',
          image: 'assets/church.jpg',
          speakers: const ['Senior Pastor', 'Worship Team'],
          category: 'Worship',
        ),
        ChurchEvent(
          id: 2,
          title: 'Friday Night Prayer',
          date: _day((5 - _now.weekday) % 7 == 0 ? 7 : (5 - _now.weekday) % 7),
          time: '7:30 PM',
          venue: 'Prayer Hall',
          description: 'An evening of intercession for our families, our city and the nations.',
          image: 'assets/picture3.png',
          category: 'Prayer',
        ),
        ChurchEvent(
          id: 3,
          title: 'Night of Worship',
          date: _day(12),
          time: '6:00 PM',
          venue: 'Main Sanctuary',
          description: 'A full evening of worship led by our worship team and guest musicians. Bring a friend!',
          image: 'assets/live_event.jpeg',
          speakers: const ['Worship Team'],
          category: 'Worship',
        ),
        ChurchEvent(
          id: 4,
          title: 'Kids Summer Bible Camp',
          date: _day(20),
          time: '9:00 AM',
          venue: 'Fellowship Hall',
          description: 'Games, crafts, Bible stories and worship for ages 4 to 12. Registration required.',
          image: 'assets/ministriesimage.png',
          category: 'Kids',
        ),
      ]..sort((a, b) => a.date.compareTo(b.date)));

  @override
  Future<List<LiveStream>> liveStreams() => _delay(const [
        LiveStream(
          id: 1,
          title: 'Sunday Worship Service – Live',
          description: 'Every Sunday at 10:30 AM CT',
          image: 'assets/church.jpg',
          youtubeUrl: 'https://www.youtube.com/',
          isLive: true,
        ),
      ]);

  @override
  Future<List<Ministry>> ministries() => _delay(const [
        Ministry(
          id: 1,
          name: 'Children\'s Ministry',
          info: 'Helping kids know and love Jesus through Bible stories, songs and play.',
          image: 'assets/ministriesimage.png',
          meets: 'Sundays · 10:30 AM',
        ),
        Ministry(
          id: 2,
          name: 'Youth',
          info: 'Students in grades 6 to 12 growing in faith and friendship.',
          image: 'assets/picture2.png',
          meets: 'Fridays · 7:00 PM',
        ),
        Ministry(
          id: 3,
          name: 'Worship & Music',
          info: 'Singers and musicians leading the church in praise.',
          image: 'assets/live_event.jpeg',
          meets: 'Thursdays · 7:30 PM',
        ),
        Ministry(
          id: 4,
          name: 'Prayer Ministry',
          info: 'Standing in the gap for our church family and city.',
          image: 'assets/pray.png',
          meets: 'Daily · 6:00 AM (online)',
        ),
        Ministry(
          id: 5,
          name: 'Families & Fellowship',
          info: 'Meals, home groups and support for every season of life.',
          image: 'assets/picture1.png',
          meets: 'Monthly',
        ),
      ]);

  @override
  Future<List<Album>> albums() => _delay(const [
        Album(id: 1, title: 'Classic Hymns', image: 'assets/church.jpg', artist: 'Bethel Worship'),
        Album(id: 2, title: 'Sunday Praise', image: 'assets/live_event.jpeg', artist: 'Bethel Worship'),
        Album(id: 3, title: 'Quiet Prayer', image: 'assets/picture3.png', artist: 'Instrumental'),
        Album(id: 4, title: 'Kids Worship', image: 'assets/ministriesimage.png', artist: 'Children\'s Ministry'),
      ]);

  static const _songs = [
    Song(
      id: 1,
      title: 'Amazing Grace',
      artist: 'John Newton',
      image: 'assets/church.jpg',
      albumTitle: 'Classic Hymns',
      chordKey: 'G',
      lyrics: {
        'English': 'Amazing grace! How sweet the sound\nThat saved a wretch like me!\nI once was lost, but now am found;\nWas blind, but now I see.\n\n'
            '\'Twas grace that taught my heart to fear,\nAnd grace my fears relieved;\nHow precious did that grace appear\nThe hour I first believed.',
      },
    ),
    Song(
      id: 2,
      title: 'It Is Well with My Soul',
      artist: 'Horatio Spafford',
      image: 'assets/doe.png',
      albumTitle: 'Classic Hymns',
      chordKey: 'C',
      lyrics: {
        'English': 'When peace like a river attendeth my way,\nWhen sorrows like sea billows roll;\nWhatever my lot, Thou hast taught me to say,\nIt is well, it is well with my soul.\n\n'
            'It is well with my soul,\nIt is well, it is well with my soul.',
      },
    ),
    Song(
      id: 3,
      title: 'Blessed Assurance',
      artist: 'Fanny Crosby',
      image: 'assets/live_event.jpeg',
      albumTitle: 'Sunday Praise',
      chordKey: 'D',
      lyrics: {
        'English': 'Blessed assurance, Jesus is mine!\nO what a foretaste of glory divine!\nHeir of salvation, purchase of God,\nBorn of His Spirit, washed in His blood.\n\n'
            'This is my story, this is my song,\nPraising my Savior all the day long.',
      },
    ),
    Song(
      id: 4,
      title: 'Holy, Holy, Holy',
      artist: 'Reginald Heber',
      image: 'assets/picture2.png',
      albumTitle: 'Sunday Praise',
      chordKey: 'D',
      lyrics: {
        'English': 'Holy, holy, holy! Lord God Almighty!\nEarly in the morning our song shall rise to Thee;\nHoly, holy, holy! Merciful and mighty!\nGod in three Persons, blessed Trinity!',
      },
    ),
    Song(
      id: 5,
      title: 'What a Friend We Have in Jesus',
      artist: 'Joseph Scriven',
      image: 'assets/pray.png',
      albumTitle: 'Quiet Prayer',
      chordKey: 'F',
      lyrics: {
        'English': 'What a friend we have in Jesus,\nAll our sins and griefs to bear!\nWhat a privilege to carry\nEverything to God in prayer!',
      },
    ),
  ];

  @override
  Future<List<Song>> trendingSongs() => _delay(_songs);

  @override
  Future<List<Song>> songsForAlbum(int albumId) async {
    final albums = await this.albums();
    final title = albums.firstWhere((a) => a.id == albumId).title;
    final list = _songs.where((s) => s.albumTitle == title).toList();
    return list.isEmpty ? _songs.take(2).toList() : list;
  }

  @override
  Future<List<Book>> books() => _delay(const [
        Book(id: 1, title: 'Uncle John', author: 'G. J. Whyte-Melville', image: 'assets/bookimage3.png',
            description: 'A classic novel from 1898, available to read in the app.'),
        Book(id: 2, title: 'A Walk with John', author: 'F. E. Henderson', image: 'assets/bookimage2.png',
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
