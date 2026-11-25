import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app/config.dart';
import 'daily_verses.dart';
import 'models.dart';
import 'repository.dart';

/// Reads and writes church content in Firebase (see `backend/`).
///
/// Collections: church, videos (synced from YouTube), events, services,
/// ministries, songBooks, songs, verses, prayerRequests, prayerContacts,
/// serviceRequests, books, pictures, readingPlan, users.
///
/// The UI models use `int` ids, so each Firestore document id is mapped to a
/// stable int ([_key]) and remembered here to turn it back into a document id.
class FirebaseRepository implements BethelRepository {
  FirebaseRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Map<int, String> _ids = {};

  /// Stable 31-bit FNV-1a hash of a document id.
  int _key(String docId) {
    var h = 0x811c9dc5;
    for (final c in docId.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    _ids[h] = docId;
    return h;
  }

  String _doc(int key) {
    final id = _ids[key];
    if (id == null) throw StateError('Unknown item. Please refresh and try again.');
    return id;
  }

  /// Guests get an anonymous account so they can post prayer requests.
  Future<String> _uid() async {
    final u = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    return u.uid;
  }

  static String _s(Map<String, dynamic> m, String k, [String fallback = '']) {
    final v = m[k];
    return v == null ? fallback : '$v';
  }

  static DateTime _date(Object? v) => v is Timestamp ? v.toDate() : (v is DateTime ? v : DateTime.now());

  static String _duration(int sec) {
    if (sec <= 0) return '';
    if (sec < 60) return '0:${sec.toString().padLeft(2, '0')}';
    if (sec < 3600) return sec < 600 ? '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}' : '${sec ~/ 60} min';
    return '${sec ~/ 3600}h ${(sec % 3600) ~/ 60}m';
  }

  static String _watchUrl(String id) => 'https://www.youtube.com/watch?v=$id';

  // ------------------------------------------------------------------ auth

  UserProfile _profile(User u) => UserProfile(
        name: u.displayName?.isNotEmpty == true ? u.displayName! : (u.email ?? 'Friend').split('@').first,
        email: u.email ?? '',
      );

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _profile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _authMessage(e);
    }
  }

  @override
  Future<UserProfile> signUp(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      await _db.doc('users/${cred.user!.uid}').set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserProfile(name: name.trim(), email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _authMessage(e);
    }
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'That email and password don\'t match.',
        'email-already-in-use' => 'An account with this email already exists. Try signing in.',
        'weak-password' => 'Please choose a password with at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        'network-request-failed' => 'No internet connection. Please try again.',
        _ => e.message ?? 'Sign in failed.',
      };

  // ------------------------------------------------------------------ church

  @override
  Future<ChurchInfo> churchInfo() async {
    final m = (await _db.doc('church/info').get()).data() ?? const {};
    return ChurchInfo(
      name: _s(m, 'name', AppConfig.churchName),
      address: _s(m, 'address', AppConfig.churchCity),
      country: _s(m, 'country', 'United States'),
      phone: _s(m, 'phone'),
      email: _s(m, 'email'),
    );
  }

  DailyVerse _verse(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return DailyVerse(
      id: _key(d.id),
      date: _date(m['date']),
      text: m['text'] as String?,
      reference: m['reference'] as String?,
      image: m['image'] as String?,
      likes: (m['likes'] as num?)?.toInt() ?? 0,
      shares: (m['shares'] as num?)?.toInt() ?? 0,
      views: (m['views'] as num?)?.toInt() ?? 0,
    );
  }

  /// The verse an admin published for today, otherwise the built-in verse for today's
  /// date (daily_verses.dart). Either way it changes every day by itself.
  @override
  Future<DailyVerse> todayVerse() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final q = await _db
        .collection('verses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(start.add(const Duration(days: 1))))
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return _verse(q.docs.first);

    // Likes for the built-in verse are stored under verses/day-YYYY-MM-DD.
    final dayId = 'day-${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final counts = (await _db.doc('verses/$dayId').get()).data() ?? const {};
    final v = builtInVerse(now);
    return DailyVerse(
      id: _key(dayId),
      date: v.date,
      text: v.text,
      reference: v.reference,
      likes: (counts['likes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<DailyVerse>> verseArchive() async {
    final q = await _db.collection('verses').orderBy('date', descending: true).limit(30).get();
    return q.docs.map(_verse).where((v) => v.image != null && v.image!.isNotEmpty).toList();
  }

  @override
  Future<void> likeVerse(int id, bool liked) async {
    final ref = _db.doc('verses/${_doc(id)}/likes/${await _uid()}');
    liked ? await ref.set({}) : await ref.delete();
  }

  @override
  Future<void> shareVerse(int id) async {}

  // ------------------------------------------------------------------ YouTube videos

  @override
  Future<List<LiveStream>> liveStreams() async {
    final m = (await _db.doc('church/live').get()).data();
    if (m == null || m['status'] == 'none' || m['videoId'] == null) return const [];
    final id = m['videoId'] as String;
    final start = m['scheduledStart'] == null ? null : DateTime.tryParse('${m['scheduledStart']}');
    return [
      LiveStream(
        id: _key('live-$id'),
        title: _s(m, 'title', 'Live service'),
        description: m['status'] == 'live'
            ? (m['viewers'] != null ? '${m['viewers']} watching now' : 'Live now')
            : (start == null ? 'Starting soon' : 'Starts ${_when(start.toLocal())}'),
        image: _s(m, 'thumbnail', 'assets/church.jpg'),
        youtubeUrl: _watchUrl(id),
        youtubeId: id,
        isLive: m['status'] == 'live',
        scheduledStart: start,
      ),
    ];
  }

  static String _when(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${days[d.weekday - 1]} at $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _videos(String kind, {int limit = 50}) async {
    final q = await _db
        .collection('videos')
        .where('kind', isEqualTo: kind)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .get();
    return q.docs.where((d) => d.data()['hidden'] != true && d.data()['removed'] != true).toList();
  }

  @override
  Future<List<Sermon>> sermons() async => (await _videos('sermon')).map((d) {
        final m = d.data();
        return Sermon(
          id: _key(d.id),
          title: _s(m, 'title', 'Sermon'),
          preacher: _s(m, 'preacher'),
          date: _date(m['publishedAt']),
          image: _s(m, 'thumbnail', 'assets/sermon-hero.png'),
          videoUrl: _watchUrl(d.id),
          youtubeId: d.id,
          description: _s(m, 'description'),
          series: (m['seriesOverride'] ?? m['series']) as String?,
          duration: _duration((m['durationSec'] as num?)?.toInt() ?? 0),
        );
      }).toList();

  Future<List<MediaItem>> _media(String kind) async => (await _videos(kind)).map((d) {
        final m = d.data();
        return MediaItem(
          id: _key(d.id),
          title: _s(m, 'title'),
          info: _s(m, 'description').split('\n').first,
          image: _s(m, 'thumbnail', 'assets/videoimage.png'),
          videoUrl: _watchUrl(d.id),
          youtubeId: d.id,
          duration: _duration((m['durationSec'] as num?)?.toInt() ?? 0),
        );
      }).toList();

  @override
  Future<List<MediaItem>> shorts() => _media('short');

  @override
  Future<List<MediaItem>> interviews() => _media('interview');

  @override
  Future<List<MediaItem>> testimonies() => _media('testimony');

  @override
  Future<List<SermonComment>> sermonComments(int sermonId) async {
    final q = await _db.collection('videos/${_doc(sermonId)}/comments').orderBy('createdAt').limit(200).get();
    return q.docs
        .map((d) => SermonComment(
            name: _s(d.data(), 'name', 'Member'), text: _s(d.data(), 'text'), at: _date(d.data()['createdAt'])))
        .toList();
  }

  @override
  Future<void> addSermonComment(int sermonId, String text) async {
    final u = _auth.currentUser;
    if (u == null || u.isAnonymous) throw 'Sign in to leave a comment.';
    await _db.collection('videos/${_doc(sermonId)}/comments').add({
      'uid': u.uid,
      'name': _profile(u).name,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------------ church life

  @override
  Future<List<ChurchEvent>> events() async {
    final today = DateTime.now();
    final q = await _db
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(today.year, today.month, today.day)))
        .orderBy('date')
        .limit(50)
        .get();
    return q.docs.map((d) {
      final m = d.data();
      return ChurchEvent(
        id: _key(d.id),
        title: _s(m, 'title', 'Event'),
        date: _date(m['date']),
        time: _s(m, 'time'),
        venue: _s(m, 'venue'),
        description: _s(m, 'description'),
        image: _s(m, 'image', 'assets/church.jpg'),
        speakers: List<String>.from(m['speakers'] as List? ?? const []),
        category: _s(m, 'category', 'Event'),
      );
    }).toList();
  }

  @override
  Future<List<ChurchService>> services() async {
    final q = await _db.collection('services').orderBy('order').get();
    return q.docs.map((d) {
      final m = d.data();
      return ChurchService(
        id: _key(d.id),
        name: _s(m, 'name'),
        description: _s(m, 'description'),
        schedule: _s(m, 'schedule'),
        image: _s(m, 'image', 'assets/church.jpg'),
        icon: IconDataRef.values.firstWhere((i) => i.name == m['icon'], orElse: () => IconDataRef.prayer),
      );
    }).toList();
  }

  @override
  Future<void> bookService(int serviceId, {required String name, required String phone, required String note}) async {
    await _db.collection('serviceRequests').add({
      'uid': await _uid(),
      'serviceId': _doc(serviceId),
      'name': name,
      'phone': phone,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Ministry>> ministries() async {
    final q = await _db.collection('ministries').orderBy('order').get();
    return q.docs
        .map((d) => Ministry(
              id: _key(d.id),
              name: _s(d.data(), 'name'),
              info: _s(d.data(), 'info'),
              image: _s(d.data(), 'image', 'assets/ministriesimage.png'),
              meets: _s(d.data(), 'meets'),
            ))
        .toList();
  }

  @override
  Future<List<Elder>> elders() async {
    final q = await _db.collection('elders').orderBy('order').get();
    return q.docs
        .map((d) => Elder(
              id: _key(d.id),
              name: _s(d.data(), 'name'),
              role: _s(d.data(), 'role', 'Elder'),
              bio: _s(d.data(), 'bio'),
              image: _s(d.data(), 'image', 'assets/church/logo.png'),
              phone: _s(d.data(), 'phone'),
            ))
        .toList();
  }

  @override
  Future<List<Book>> books() async {
    final q = await _db.collection('books').get();
    return q.docs
        .map((d) => Book(
              id: _key(d.id),
              title: _s(d.data(), 'title'),
              author: _s(d.data(), 'author'),
              image: _s(d.data(), 'image', 'assets/bookimage3.png'),
              description: _s(d.data(), 'description'),
            ))
        .toList();
  }

  @override
  Future<List<GalleryPicture>> pictures() async {
    final q = await _db.collection('pictures').orderBy('order').get();
    return q.docs
        .map((d) => GalleryPicture(id: _key(d.id), image: _s(d.data(), 'image'), caption: _s(d.data(), 'caption')))
        .toList();
  }

  // ------------------------------------------------------------------ songs

  @override
  Future<List<Album>> albums() async {
    final q = await _db.collection('songBooks').orderBy('order').get();
    return q.docs.map((d) {
      final m = d.data();
      return Album(
        id: _key(d.id),
        title: _s(m, 'title'),
        image: _s(m, 'image', 'assets/church.jpg'),
        artist: m['language'] == null ? '' : '${m['language']} song book',
        language: _s(m, 'language'),
        songCount: (m['songCount'] as num?)?.toInt() ?? 0,
        isSongBook: true,
      );
    }).toList();
  }

  Song _song(DocumentSnapshot<Map<String, dynamic>> d, {String? bookTitle}) {
    final m = d.data()!;
    return Song(
      id: _key(d.id),
      number: (m['number'] as num?)?.toInt() ?? 0,
      title: _s(m, 'title'),
      altTitle: _s(m, 'altTitle'),
      reference: _s(m, 'reference'),
      artist: _s(m, 'artist'),
      lyricist: _s(m, 'lyricist'),
      image: _s(m, 'image', 'assets/church.jpg'),
      albumId: m['bookId'] == null ? null : _key(m['bookId'] as String),
      albumTitle: bookTitle ?? _s(m, 'bookTitle'),
      lyrics: Map<String, String>.from(m['lyrics'] as Map? ?? const {}),
      chordKey: m['chordKey'] as String?,
      chords: m['chords'] as String?,
      audioUrl: m['audioUrl'] as String?,
    );
  }

  final Map<String, String> _bookTitles = {};

  Future<String?> _bookTitle(String bookId) async {
    if (_bookTitles.containsKey(bookId)) return _bookTitles[bookId];
    final t = (await _db.doc('songBooks/$bookId').get()).data()?['title'] as String?;
    if (t != null) _bookTitles[bookId] = t;
    return t;
  }

  @override
  Future<List<Song>> songsForAlbum(int albumId) async {
    final bookId = _doc(albumId);
    final title = await _bookTitle(bookId);
    final q = await _db.collection('songs').where('bookId', isEqualTo: bookId).orderBy('number').get();
    return q.docs.map((d) => _song(d, bookTitle: title)).toList();
  }

  @override
  Future<List<Song>> trendingSongs() async {
    final q = await _db.collection('songs').orderBy('trendingScore', descending: true).limit(8).get();
    return [
      for (final d in q.docs) _song(d, bookTitle: await _bookTitle(d.data()['bookId'] as String? ?? '')),
    ];
  }

  @override
  Future<Song> songDetail(Song song) async {
    final id = _ids[song.id];
    if (id == null) return song;
    final d = await _db.doc('songs/$id').get();
    return d.exists ? _song(d, bookTitle: song.albumTitle) : song;
  }

  // ------------------------------------------------------------------ prayer

  PrayerRequest _prayer(DocumentSnapshot<Map<String, dynamic>> d, String? myUid) {
    final m = d.data()!;
    return PrayerRequest(
      id: _key(d.id),
      name: _s(m, 'name', 'Anonymous'),
      request: _s(m, 'request'),
      category: _s(m, 'category', 'Other'),
      createdAt: _date(m['createdAt']),
      prayedCount: (m['prayedCount'] as num?)?.toInt() ?? 0,
      isMine: myUid != null && m['uid'] == myUid,
    );
  }

  @override
  Future<List<PrayerRequest>> prayerWall() async {
    final uid = _auth.currentUser?.uid;
    final public = await _db
        .collection('prayerRequests')
        .where('public', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    final mine = uid == null
        ? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : (await _db.collection('prayerRequests').where('uid', isEqualTo: uid).limit(20).get()).docs;
    final all = {
      for (final d in [...public.docs, ...mine]) d.id: _prayer(d, uid)
    }.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  @override
  Future<PrayerRequest> submitPrayer({
    required String name,
    required String email,
    required String phone,
    required String request,
    required String category,
    required bool shareOnWall,
  }) async {
    final uid = await _uid();
    final first = name.trim().split(RegExp(r'\s+')).first;
    final ref = _db.collection('prayerRequests').doc();
    await ref.set({
      'uid': uid,
      'name': shareOnWall && first.isNotEmpty ? first : 'Anonymous',
      'request': request.trim(),
      'category': category,
      'public': shareOnWall,
      'createdAt': FieldValue.serverTimestamp(),
      'prayedCount': 0,
    });
    if (email.trim().isNotEmpty || phone.trim().isNotEmpty) {
      await _db.doc('prayerContacts/${ref.id}').set({
        'uid': uid,
        'email': email.trim(),
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return PrayerRequest(
      id: _key(ref.id),
      name: shareOnWall && first.isNotEmpty ? first : 'Anonymous',
      request: request.trim(),
      category: category,
      createdAt: DateTime.now(),
      isMine: true,
    );
  }

  @override
  Future<void> prayFor(int prayerId) async {
    final uid = await _uid();
    await _db.doc('prayerRequests/${_doc(prayerId)}/prayedBy/$uid').set({'at': FieldValue.serverTimestamp()});
  }

  @override
  Future<List<BiblePassage>> readingPlan() async {
    final q = await _db.collection('readingPlan').orderBy('order').get();
    return q.docs
        .map((d) => BiblePassage(
              reference: _s(d.data(), 'reference'),
              title: _s(d.data(), 'title'),
              verses: List<String>.from(d.data()['verses'] as List? ?? const []),
            ))
        .toList();
  }
}
