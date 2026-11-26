import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../app/config.dart';
import '../app/launch.dart';
import 'church_content.dart';
import 'daily_verses.dart';
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
    return _delay(_current = UserProfile(name: name, email: email.trim()));
  }

  @override
  Future<UserProfile> signUp(String name, String email, String password) =>
      _delay(_current = UserProfile(name: name.trim(), email: email.trim()));

  String? _pendingPhone;

  /// Demo: no text is sent; any 6-digit code works.
  @override
  Future<void> sendPhoneCode(String phone) {
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      return Future.error('Please enter a valid phone number.');
    }
    _pendingPhone = phone;
    return _delay(null);
  }

  @override
  Future<UserProfile> verifyPhoneCode(String code, {String name = ''}) {
    if (_pendingPhone == null) return Future.error('Please request a code first.');
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) return Future.error('Enter the 6-digit code we texted you.');
    return _delay(_current = UserProfile(name: name.trim().isEmpty ? 'Friend' : name.trim(), email: '', phone: _pendingPhone!));
  }

  UserProfile? _current;

  final Set<String> _providersUsed = {};

  /// Demo: Apple and Google always succeed. The first time each is used after launch it acts as a
  /// new member (no name yet, so the card asks for one); after that, as a returning member.
  @override
  Future<UserProfile> signInWithProvider(String provider) {
    final email = provider == 'apple' ? 'samuel@icloud.com' : 'samuel@gmail.com';
    final isNew = _providersUsed.add(provider);
    return _delay(_current = UserProfile(name: isNew ? '' : 'Samuel Raju', email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) {
    if (!email.contains('@')) return Future.error('Enter your email first.');
    return _delay(null);
  }

  @override
  Future<UserProfile> updateName(String name) {
    final u = _current;
    return _delay(_current = UserProfile(name: name.trim(), email: u?.email ?? '', phone: u?.phone ?? _pendingPhone ?? ''));
  }

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
    (_comments[sermonId] ??= []).insert(0, SermonComment(name: _current?.name ?? 'You', text: text, at: DateTime.now()));
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

  static final _playlists = <VideoPlaylist>[
    const VideoPlaylist(id: 'PLsun', title: 'Sunday Services', thumbnail: 'assets/live_event.jpeg', count: 84),
    const VideoPlaylist(id: 'PLtel', title: 'Telugu Messages', thumbnail: 'assets/sermon-hero.png', count: 42),
    const VideoPlaylist(id: 'PLsp26', title: 'Special Meetings 2026', thumbnail: 'assets/church.jpg', count: 9),
    const VideoPlaylist(id: 'PLtest', title: 'Testimonies', thumbnail: 'assets/picture3.png', count: 27, kind: 'testimony'),
    const VideoPlaylist(id: 'PLkids', title: 'Kids and Youth', thumbnail: 'assets/ministriesimage.png', count: 18),
  ];

  static final _playlistVideos = <String, List<ChannelVideo>>{
    'PLsun': [
      ChannelVideo(id: 'svc1122', title: 'Sunday Worship Service', thumbnail: 'assets/live_event.jpeg', published: DateTime(2026, 11, 22, 15), duration: '2:14:05', preacher: 'Bro. Moses Polugari'),
      ChannelVideo(id: 'svc1115', title: 'Walking in the light', thumbnail: 'assets/sermon-hero.png', published: DateTime(2026, 11, 15, 15), duration: '1:58:40', preacher: 'Bro. Vinod Somepalli'),
      ChannelVideo(id: 'svc1108', title: 'Peace that guards your heart', thumbnail: 'assets/church.jpg', published: DateTime(2026, 11, 8, 15), duration: '2:02:11', preacher: 'Bro. Moses Polugari'),
      ChannelVideo(id: 'svc1101', title: 'Thanksgiving service', thumbnail: 'assets/picture3.png', published: DateTime(2026, 11, 1, 15), duration: '2:20:30'),
      ChannelVideo(id: 'svc1025', title: 'Communion Sunday', thumbnail: 'assets/ministriesimage.png', published: DateTime(2025, 10, 25, 15), duration: '2:05:10'),
    ],
    'PLtel': [
      ChannelVideo(id: 'tel1030', title: 'దేవుని ప్రేమ', thumbnail: 'assets/sermon-hero.png', published: DateTime(2026, 10, 30), duration: '48:12'),
      ChannelVideo(id: 'tel1012', title: 'విశ్వాసము', thumbnail: 'assets/church.jpg', published: DateTime(2026, 10, 12), duration: '51:03'),
    ],
    'PLsp26': [
      ChannelVideo(id: 'sp1', title: 'Special Meetings · Night 1', thumbnail: 'assets/church.jpg', published: DateTime(2026, 3, 6, 19), duration: '1:45:00'),
    ],
    'PLtest': [
      ChannelVideo(id: 'tst1', title: 'How God carried our family through 2025', thumbnail: 'assets/picture3.png', published: DateTime(2026, 9, 14), duration: '6:40'),
    ],
    'PLkids': [
      ChannelVideo(id: 'kid1', title: 'Christmas program 2025', thumbnail: 'assets/ministriesimage.png', published: DateTime(2025, 12, 21), duration: '38:20'),
    ],
  };

  @override
  Future<List<VideoPlaylist>> playlists() => _delay(_playlists);

  @override
  Future<List<ChannelVideo>> playlistVideos(String playlistId, {int limit = 50}) =>
      _delay((_playlistVideos[playlistId] ?? const <ChannelVideo>[]).take(limit).toList());

  @override
  Future<ChannelVideo?> latestService() => _delay(_playlistVideos['PLsun']!.first);

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
        Album(
            id: 11,
            title: 'Hymns of Faith',
            image: 'assets/picture3.png',
            artist: 'English hymn book',
            language: 'English',
            songCount: 20,
            isSongBook: true),
        Album(
            id: 3,
            title: 'Special Meetings 2026',
            image: '',
            artist: 'Bethel Prayer House',
            dates: 'Dec 4–6, 2026',
            isNew: true,
            addedOn: DateTime(2026, 11, 20)),
        Album(id: 1, title: 'Sunday Praise', image: 'assets/live_event.jpeg', artist: 'Bethel Worship', addedOn: DateTime(2026, 6, 1)),
        Album(id: 2, title: 'Kids Worship', image: 'assets/ministriesimage.png', artist: 'Children\'s Ministry', addedOn: DateTime(2026, 3, 1)),
      ]);

  static const _zion = 10;
  static const _hymns = 11;

  static const _songs = <Song>[
    // Songs of Zion: titles from the original app. Lyrics come from the song database (API).
    Song(
      id: 101,
      number: 1,
      title: 'Aadhaaram Naaku Aadhaaram',
      altTitle: 'ఆధారం నాకు ఆధారం',
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
    // Hymns of Faith: public-domain hymns with full sample lyrics.
    Song(
      id: 1,
      number: 1,
      title: 'Amazing Grace',
      artist: 'Traditional',
      lyricist: 'John Newton (1779)',
      image: 'assets/church.jpg',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'G',
      chords: 'G        G7        C        G\n'
          'G        Em        D        D7\n'
          'G        G7        C        G\n'
          'G        D         G',
      lyrics: {
        'English': 'Amazing grace! How sweet the sound\nThat saved a wretch like me!\nI once was lost, but now am found;\nWas blind, but now I see.\n\n'
            '\'Twas grace that taught my heart to fear,\nAnd grace my fears relieved;\nHow precious did that grace appear\nThe hour I first believed.\n\n'
            'Through many dangers, toils and snares,\nI have already come;\n\'Tis grace hath brought me safe thus far,\nAnd grace will lead me home.\n\n'
            'When we\'ve been there ten thousand years,\nBright shining as the sun,\nWe\'ve no less days to sing God\'s praise\nThan when we\'d first begun.',
      },
    ),
    Song(
      id: 2,
      number: 2,
      title: 'It Is Well with My Soul',
      artist: 'Traditional',
      lyricist: 'Horatio Spafford (1873)',
      image: 'assets/doe.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'C',
      chords: 'C        F        C\nC        G        C\nC        Am       Dm       G\nC        F   G    C',
      lyrics: {
        'English':
            'When peace like a river attendeth my way,\nWhen sorrows like sea billows roll;\nWhatever my lot, Thou hast taught me to say,\nIt is well, it is well with my soul.\n\n'
                'It is well with my soul,\nIt is well, it is well with my soul.\n\n'
                'Though Satan should buffet, though trials should come,\nLet this blest assurance control,\nThat Christ has regarded my helpless estate,\nAnd hath shed His own blood for my soul.',
      },
    ),
    Song(
      id: 3,
      number: 3,
      title: 'Blessed Assurance',
      artist: 'Traditional',
      lyricist: 'Fanny Crosby (1873)',
      image: 'assets/live_event.jpeg',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'D',
      chords: 'D        G        D        A\nD        G        A        D',
      lyrics: {
        'English': 'Blessed assurance, Jesus is mine!\nO what a foretaste of glory divine!\nHeir of salvation, purchase of God,\nBorn of His Spirit, washed in His blood.\n\n'
            'This is my story, this is my song,\nPraising my Savior all the day long;\nThis is my story, this is my song,\nPraising my Savior all the day long.\n\n'
            'Perfect submission, perfect delight,\nVisions of rapture now burst on my sight;\nAngels descending bring from above\nEchoes of mercy, whispers of love.',
      },
    ),
    Song(
      id: 4,
      number: 4,
      title: 'Holy, Holy, Holy',
      artist: 'Traditional',
      lyricist: 'Reginald Heber (1826)',
      image: 'assets/picture2.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'D',
      lyrics: {
        'English':
            'Holy, holy, holy! Lord God Almighty!\nEarly in the morning our song shall rise to Thee;\nHoly, holy, holy! Merciful and mighty!\nGod in three Persons, blessed Trinity!\n\n'
                'Holy, holy, holy! All the saints adore Thee,\nCasting down their golden crowns around the glassy sea;\nCherubim and seraphim falling down before Thee,\nWhich wert, and art, and evermore shalt be.',
      },
    ),
    Song(
      id: 5,
      number: 5,
      title: 'What a Friend We Have in Jesus',
      artist: 'Traditional',
      lyricist: 'Joseph Scriven (1855)',
      image: 'assets/pray.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'F',
      lyrics: {
        'English':
            'What a friend we have in Jesus,\nAll our sins and griefs to bear!\nWhat a privilege to carry\nEverything to God in prayer!\n\n'
                'O what peace we often forfeit,\nO what needless pain we bear,\nAll because we do not carry\nEverything to God in prayer!',
      },
    ),
    Song(
      id: 6,
      number: 6,
      title: 'Rock of Ages',
      artist: 'Traditional',
      lyricist: 'Augustus Toplady (1776)',
      image: 'assets/picture3.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'Rock of Ages, cleft for me,\nLet me hide myself in Thee;\nLet the water and the blood,\nFrom Thy wounded side which flowed,\nBe of sin the double cure,\nSave from wrath and make me pure.',
      },
    ),
    Song(
      id: 7,
      number: 7,
      title: 'Abide with Me',
      artist: 'Traditional',
      lyricist: 'Henry F. Lyte (1847)',
      image: 'assets/sermon-hero.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'Abide with me; fast falls the eventide;\nThe darkness deepens; Lord, with me abide;\nWhen other helpers fail and comforts flee,\nHelp of the helpless, O abide with me.',
      },
    ),
    Song(
      id: 8,
      number: 8,
      title: 'Jesus Loves Me',
      artist: 'Traditional',
      lyricist: 'Anna B. Warner (1860)',
      image: 'assets/ministriesimage.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'C',
      lyrics: {
        'English':
            'Jesus loves me! This I know,\nFor the Bible tells me so;\nLittle ones to Him belong;\nThey are weak, but He is strong.\n\n'
                'Yes, Jesus loves me!\nYes, Jesus loves me!\nYes, Jesus loves me!\nThe Bible tells me so.',
      },
    ),
    Song(
      id: 9,
      number: 9,
      title: 'Nearer, My God, to Thee',
      artist: 'Traditional',
      lyricist: 'Sarah F. Adams (1841)',
      image: 'assets/master3.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'Nearer, my God, to Thee,\nNearer to Thee!\nE\'en though it be a cross\nThat raiseth me,\nStill all my song shall be,\nNearer, my God, to Thee,\nNearer, my God, to Thee,\nNearer to Thee!',
      },
    ),
    Song(
      id: 10,
      number: 10,
      title: 'Come, Thou Fount of Every Blessing',
      artist: 'Traditional',
      lyricist: 'Robert Robinson (1758)',
      image: 'assets/master2.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'Come, Thou Fount of every blessing,\nTune my heart to sing Thy grace;\nStreams of mercy, never ceasing,\nCall for songs of loudest praise.',
      },
    ),
    Song(
      id: 11,
      number: 11,
      title: 'To God Be the Glory',
      artist: 'Traditional',
      lyricist: 'Fanny Crosby (1875)',
      image: 'assets/church.jpg',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'To God be the glory, great things He hath done;\nSo loved He the world that He gave us His Son,\nWho yielded His life an atonement for sin,\nAnd opened the life-gate that all may go in.\n\nPraise the Lord, praise the Lord,\nLet the earth hear His voice!\nPraise the Lord, praise the Lord,\nLet the people rejoice!\nO come to the Father, through Jesus the Son,\nAnd give Him the glory, great things He hath done.',
      },
    ),
    Song(
      id: 12,
      number: 12,
      title: 'When I Survey the Wondrous Cross',
      artist: 'Traditional',
      lyricist: 'Isaac Watts (1707)',
      image: 'assets/picture3.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'When I survey the wondrous cross\nOn which the Prince of glory died,\nMy richest gain I count but loss,\nAnd pour contempt on all my pride.\n\nWere the whole realm of nature mine,\nThat were a present far too small;\nLove so amazing, so divine,\nDemands my soul, my life, my all.',
      },
    ),
    Song(
      id: 13,
      number: 13,
      title: 'The Old Rugged Cross',
      artist: 'Traditional',
      lyricist: 'George Bennard (1913)',
      image: 'assets/sermon-hero.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'G',
      lyrics: {
        'English':
            'On a hill far away stood an old rugged cross,\nThe emblem of suffering and shame;\nAnd I love that old cross where the dearest and best\nFor a world of lost sinners was slain.\n\nSo I\'ll cherish the old rugged cross,\nTill my trophies at last I lay down;\nI will cling to the old rugged cross,\nAnd exchange it some day for a crown.',
      },
    ),
    Song(
      id: 14,
      number: 14,
      title: 'I Surrender All',
      artist: 'Traditional',
      lyricist: 'Judson W. Van DeVenter (1896)',
      image: 'assets/pray.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'D',
      lyrics: {
        'English':
            'All to Jesus I surrender,\nAll to Him I freely give;\nI will ever love and trust Him,\nIn His presence daily live.\n\nI surrender all, I surrender all;\nAll to Thee, my blessed Savior,\nI surrender all.',
      },
    ),
    Song(
      id: 15,
      number: 15,
      title: 'Trust and Obey',
      artist: 'Traditional',
      lyricist: 'John H. Sammis (1887)',
      image: 'assets/doe.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'F',
      lyrics: {
        'English':
            'When we walk with the Lord\nIn the light of His Word,\nWhat a glory He sheds on our way!\nWhile we do His good will,\nHe abides with us still,\nAnd with all who will trust and obey.\n\nTrust and obey, for there\'s no other way\nTo be happy in Jesus, but to trust and obey.',
      },
    ),
    Song(
      id: 16,
      number: 16,
      title: 'Leaning on the Everlasting Arms',
      artist: 'Traditional',
      lyricist: 'Elisha A. Hoffman (1887)',
      image: 'assets/picture1.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'A',
      lyrics: {
        'English':
            'What a fellowship, what a joy divine,\nLeaning on the everlasting arms;\nWhat a blessedness, what a peace is mine,\nLeaning on the everlasting arms.\n\nLeaning, leaning,\nSafe and secure from all alarms;\nLeaning, leaning,\nLeaning on the everlasting arms.',
      },
    ),
    Song(
      id: 17,
      number: 17,
      title: 'Count Your Blessings',
      artist: 'Traditional',
      lyricist: 'Johnson Oatman Jr. (1897)',
      image: 'assets/live_event.jpeg',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'D',
      lyrics: {
        'English':
            'When upon life\'s billows you are tempest tossed,\nWhen you are discouraged, thinking all is lost,\nCount your many blessings, name them one by one,\nAnd it will surprise you what the Lord hath done.\n\nCount your blessings, name them one by one;\nCount your blessings, see what God hath done!\nCount your blessings, name them one by one;\nCount your many blessings, see what God hath done.',
      },
    ),
    Song(
      id: 18,
      number: 18,
      title: 'O for a Thousand Tongues to Sing',
      artist: 'Traditional',
      lyricist: 'Charles Wesley (1739)',
      image: 'assets/master2.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      lyrics: {
        'English':
            'O for a thousand tongues to sing\nMy great Redeemer\'s praise,\nThe glories of my God and King,\nThe triumphs of His grace!\n\nJesus! the name that charms our fears,\nThat bids our sorrows cease;\n\'Tis music in the sinner\'s ears,\n\'Tis life, and health, and peace.',
      },
    ),
    Song(
      id: 19,
      number: 19,
      title: 'Joy to the World',
      artist: 'Traditional',
      lyricist: 'Isaac Watts (1719)',
      image: 'assets/master1.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'D',
      lyrics: {
        'English':
            'Joy to the world! the Lord is come;\nLet earth receive her King;\nLet every heart prepare Him room,\nAnd heaven and nature sing,\nAnd heaven and nature sing,\nAnd heaven, and heaven, and nature sing.',
      },
    ),
    Song(
      id: 20,
      number: 20,
      title: 'Softly and Tenderly',
      artist: 'Traditional',
      lyricist: 'Will L. Thompson (1880)',
      image: 'assets/ministriesimage.png',
      albumId: _hymns,
      albumTitle: 'Hymns of Faith',
      chordKey: 'G',
      lyrics: {
        'English':
            'Softly and tenderly Jesus is calling,\nCalling for you and for me;\nSee, on the portals He\'s waiting and watching,\nWatching for you and for me.\n\nCome home, come home,\nYe who are weary, come home;\nEarnestly, tenderly, Jesus is calling,\nCalling, O sinner, come home!',
      },
    ),
  ];

  /// Songs of Zion, loaded from `assets/songs/songs_of_zion.json` when it is bundled
  /// (the file is git-ignored). Without it, the two sample titles above are used.
  List<Song>? _zionCache;

  Future<List<Song>> _zionSongs() async {
    if (_zionCache != null) return _zionCache!;
    try {
      final raw =
          jsonDecode(utf8.decode((await rootBundle.load('assets/songs/songs_of_zion.json')).buffer.asUint8List()))
              as List;
      const images = [
        'assets/church.jpg',
        'assets/picture3.png',
        'assets/pray.png',
        'assets/doe.png',
        'assets/sermon-hero.png'
      ];
      _zionCache = [
        for (final m in raw.cast<Map<String, dynamic>>())
          Song(
            id: 100000 + (m['n'] as int),
            number: m['n'] as int,
            title: m['t'] as String,
            altTitle: (m['tt'] as String?) ?? '',
            reference: (m['r'] as String?) ?? '',
            artist: '',
            image: images[(m['n'] as int) % images.length],
            albumId: _zion,
            albumTitle: 'Songs of Zion',
            lyrics: {
              if ((m['te'] as String?)?.isNotEmpty ?? false) 'Telugu': m['te'] as String,
              if ((m['en'] as String?)?.isNotEmpty ?? false) 'English': m['en'] as String,
            },
          ),
      ];
    } catch (_) {
      _zionCache = _songs.where((s) => s.albumId == _zion).toList();
    }
    return _zionCache!;
  }

  @override
  Future<List<Song>> trendingSongs() async {
    final zion = await _zionSongs();
    Song? z(int n) => zion.where((s) => s.number == n).firstOrNull;
    return _delay([
      ...[z(1), z(500), z(2)].whereType<Song>(),
      for (final id in const [1, 3, 5]) _songs.firstWhere((s) => s.id == id),
    ]);
  }

  @override
  Future<List<Song>> songsForAlbum(int albumId) async {
    if (albumId == _zion) return _delay(await _zionSongs());
    if (albumId == 3) {
      // Special meetings: songs from both books, in the order they'll be sung.
      final zion = await _zionSongs();
      return _delay([...zion.take(2), ..._songs.where((s) => s.albumId == _hymns).take(3)]);
    }
    final list = _songs.where((s) => s.albumId == albumId).toList();
    // Albums that aren't song books reuse a few hymns in the demo.
    return _delay(list.isEmpty ? _songs.where((s) => s.albumId == _hymns).take(3).toList() : list);
  }

  @override
  Future<Song> songDetail(Song song) async =>
      _delay([..._songs, ...await _zionSongs()].firstWhere((s) => s.id == song.id, orElse: () => song));

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

  @override
  Future<List<NotificationItem>> notifications() {
    final now = DateTime.now();
    return _delay([
      NotificationItem(id: 1, title: 'Prayer Meeting is tomorrow', detail: 'Fri · 7:30 PM', at: now.subtract(const Duration(hours: 1)), kind: 'event'),
      NotificationItem(id: 2, title: 'New message: Peace That Guards Your Heart', detail: 'Associate Pastor', at: now.subtract(const Duration(hours: 3)), kind: 'sermon'),
      NotificationItem(id: 3, title: '12 people prayed for your request', detail: 'Prayer wall', at: now.subtract(const Duration(days: 2)), kind: 'prayer'),
      NotificationItem(id: 4, title: 'Day 3 of your reading plan is ready', detail: 'Peace and Strength', at: now.subtract(const Duration(days: 2)), kind: 'reading'),
      NotificationItem(id: 5, title: 'Sunday Worship Service starts in 1 hour', detail: 'Sunday · 3:00 PM', at: now.subtract(const Duration(days: 4)), kind: 'service'),
    ]);
  }
}
