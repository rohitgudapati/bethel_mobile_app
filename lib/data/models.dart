/// Plain data models used by the UI.
///
/// `image` fields hold either a bundled asset path (`assets/...`) or a
/// network URL (e.g. the API's S3 `presignedUrl`). Use `BethelImage` to show them.
library;

class DailyVerse {
  final int id;
  final DateTime date;
  final String? text; // the API currently only stores an image of the verse
  final String? reference;
  final String? image;
  final int likes;
  final int shares;
  final int views;
  const DailyVerse({
    required this.id,
    required this.date,
    this.text,
    this.reference,
    this.image,
    this.likes = 0,
    this.shares = 0,
    this.views = 0,
  });
}

class Sermon {
  final int id;
  final String title;
  final String preacher;
  final DateTime date;
  final String image;
  final String? videoUrl;
  final String description;
  final String? series;
  final String duration;

  /// YouTube video id, for playing inside the app.
  final String? youtubeId;
  const Sermon({
    required this.id,
    required this.title,
    required this.preacher,
    required this.date,
    required this.image,
    this.videoUrl,
    this.description = '',
    this.series,
    this.duration = '',
    this.youtubeId,
  });
}

class ChurchEvent {
  final int id;
  final String title;
  final DateTime date;
  final String time;
  final String venue;
  final String description;
  final String image;
  final List<String> speakers;
  final String category;
  const ChurchEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.description,
    required this.image,
    this.speakers = const [],
    this.category = 'Event',
  });
}

class LiveStream {
  final int id;
  final String title;
  final String description;
  final String image;
  final String youtubeUrl;
  final bool isLive;
  final String? youtubeId;
  final DateTime? scheduledStart;
  const LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.youtubeUrl,
    this.isLive = false,
    this.youtubeId,
    this.scheduledStart,
  });
}

class Ministry {
  final int id;
  final String name;
  final String info;
  final String image;
  final String meets;
  const Ministry({required this.id, required this.name, required this.info, required this.image, this.meets = ''});
}

/// A song book or album (the API's `Album`), e.g. "Songs of Zion".
class Album {
  final int id;
  final String title;
  final String image;
  final String artist;
  final String language;
  final int songCount;
  final bool isSongBook;

  /// Shown first on Songs with a New label, e.g. songs for this year's special meetings.
  final bool isNew;

  /// When the album is for, e.g. "Dec 4–6, 2026".
  final String dates;
  final DateTime? addedOn;
  const Album({
    required this.id,
    required this.title,
    required this.image,
    this.artist = '',
    this.language = '',
    this.songCount = 0,
    this.isSongBook = false,
    this.isNew = false,
    this.dates = '',
    this.addedOn,
  });
}

class Song {
  final int id;

  /// Number in its song book (e.g. 112 in Songs of Zion). 0 when not numbered.
  final int number;
  final String title;

  /// Title in a second script, e.g. the Telugu title of a Songs of Zion song.
  final String altTitle;

  /// Bible reference printed with the song, e.g. "Psalm 2:1-10".
  final String reference;

  /// Singer or composer.
  final String artist;
  final String lyricist;
  final String image;
  final int? albumId;
  final String? albumTitle;

  /// Lyrics keyed by language name, e.g. {'Telugu': '...', 'English': '...'}.
  /// Stanzas are separated by a blank line.
  final Map<String, String> lyrics;
  final String? chordKey;
  final String? chords;
  final String? audioUrl;
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.image,
    this.number = 0,
    this.altTitle = '',
    this.reference = '',
    this.lyricist = '',
    this.albumId,
    this.albumTitle,
    this.lyrics = const {},
    this.chordKey,
    this.chords,
    this.audioUrl,
  });

  String get label => number > 0 ? '$number. $title' : title;

  Song withLyrics(Map<String, String> lyrics, {String? lyricist, String? chords}) => Song(
        id: id,
        number: number,
        title: title,
        altTitle: altTitle,
        reference: reference,
        artist: artist,
        lyricist: lyricist ?? this.lyricist,
        image: image,
        albumId: albumId,
        albumTitle: albumTitle,
        lyrics: lyrics,
        chordKey: chordKey,
        chords: chords ?? this.chords,
        audioUrl: audioUrl,
      );
}

/// Short clip, interview or testimony video.
class MediaItem {
  final int id;
  final String title;
  final String info;
  final String image;
  final String? videoUrl;
  final String duration;
  final String? youtubeId;
  const MediaItem({
    required this.id,
    required this.title,
    required this.image,
    this.info = '',
    this.videoUrl,
    this.duration = '',
    this.youtubeId,
  });
}

class SermonComment {
  final String name;
  final String text;
  final DateTime at;
  const SermonComment({required this.name, required this.text, required this.at});
}

/// A regular church service (API `Service`), e.g. Sunday Prayer.
class ChurchService {
  final int id;
  final String name;
  final String description;
  final String schedule;
  final String image;
  final IconDataRef icon;
  const ChurchService({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.schedule = '',
    this.icon = IconDataRef.prayer,
  });
}

enum IconDataRef { prayer, worship, bible, family, fasting }

class Elder {
  final int id;
  final String name;
  final String role;
  final String bio;
  final String image;
  final String phone;
  const Elder(
      {required this.id,
      required this.name,
      required this.role,
      required this.bio,
      required this.image,
      this.phone = ''});
}

class ChurchInfo {
  final String name;
  final String address;
  final String country;
  final String phone;
  final String email;
  const ChurchInfo({
    required this.name,
    required this.address,
    required this.country,
    this.phone = '',
    this.email = '',
  });
}

class PrayerRequest {
  final int id;
  final String name;
  final String request;
  final String category;
  final DateTime createdAt;
  final int prayedCount;
  final bool isMine;
  const PrayerRequest({
    required this.id,
    required this.name,
    required this.request,
    required this.category,
    required this.createdAt,
    this.prayedCount = 0,
    this.isMine = false,
  });

  PrayerRequest copyWith({int? prayedCount}) => PrayerRequest(
        id: id,
        name: name,
        request: request,
        category: category,
        createdAt: createdAt,
        prayedCount: prayedCount ?? this.prayedCount,
        isMine: isMine,
      );
}

class Book {
  final int id;
  final String title;
  final String author;
  final String image;
  final String description;
  const Book({required this.id, required this.title, required this.author, required this.image, this.description = ''});
}

class GalleryPicture {
  final int id;
  final String image;
  final String caption;
  const GalleryPicture({required this.id, required this.image, this.caption = ''});
}

class BiblePassage {
  final String reference;
  final String title;
  final List<String> verses;
  const BiblePassage({required this.reference, required this.title, required this.verses});
}

/// Something the church or the app wants the member to see (service reminders, new messages, prayer updates).
class NotificationItem {
  final int id;
  final String title;
  final String detail;
  final DateTime at;

  /// `event`, `sermon`, `prayer`, `reading` or `service`; picks the icon and where a tap goes.
  final String kind;
  const NotificationItem({required this.id, required this.title, required this.detail, required this.at, required this.kind});
}

class UserProfile {
  final String name;
  final String email;
  final String? token;

  /// Set when the person signed in with their phone number.
  final String phone;
  const UserProfile({required this.name, required this.email, this.token, this.phone = ''});

  /// Email, or phone number for phone sign-ins.
  String get contact => email.isNotEmpty ? email : phone;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// A playlist on the church's YouTube channel (Watch shows one shelf per playlist).
class VideoPlaylist {
  const VideoPlaylist({required this.id, required this.title, required this.thumbnail, required this.count, this.kind = 'series'});
  final String id;
  final String title;
  final String thumbnail;
  final int count;

  /// series, testimony or interview.
  final String kind;
}

/// A video from the church's YouTube channel.
class ChannelVideo {
  const ChannelVideo({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.published,
    this.duration = '',
    this.description = '',
    this.preacher = '',
    this.embeddable = true,
    this.type = 'sermon',
    this.liveRecording = false,
  });

  /// The YouTube video id.
  final String id;
  final String title;
  final String thumbnail;
  final DateTime published;
  final String duration;
  final String description;
  final String preacher;
  final bool embeddable;

  /// sermon, song, testimony, interview or short (as sorted by the YouTube sync).
  final String type;

  /// A recording of a live stream (a service), not an upload.
  final bool liveRecording;
}

/// One of today's trivia questions (no answer: that stays on the server).
class QuizItem {
  const QuizItem({required this.id, required this.question, required this.choices});
  final String id;
  final String question;
  final List<String> choices;
}

/// A member's answer to one question, once the server has checked it.
class QuizAnswer {
  const QuizAnswer({required this.choice, this.correct, this.answer, this.ref = '', this.points = 0, this.rightPercent});
  final int choice;
  final bool? correct;
  final int? answer;
  final String ref;
  final int points;

  /// How much of the church got this one right (0–100), when known.
  final int? rightPercent;
}

/// Today's five trivia questions and this member's answers so far.
class DailyQuiz {
  const DailyQuiz({required this.date, required this.week, required this.items, this.answers = const {}, this.players = 0});
  final String date;
  final String week;
  final List<QuizItem> items;
  final Map<int, QuizAnswer> answers;

  /// People who have played today.
  final int players;

  int get total => items.length;
  int get done => answers.length;
  int get right => answers.values.where((a) => a.correct == true).length;
  int get points => answers.values.fold(0, (s, a) => s + a.points);
  bool get finished => total > 0 && done >= total;
  int? get nextIndex {
    for (var i = 0; i < items.length; i++) {
      if (!answers.containsKey(i)) return i;
    }
    return null;
  }

  DailyQuiz withAnswer(int index, QuizAnswer a) =>
      DailyQuiz(date: date, week: week, items: items, answers: {...answers, index: a}, players: players);
}

class LeaderboardEntry {
  const LeaderboardEntry({required this.uid, required this.name, required this.points, this.correct = 0, this.streak = 0});
  final String uid;
  final String name;
  final int points;
  final int correct;
  final int streak;
}

/// This week's leaderboard: the top players and where the signed-in member stands.
class Leaderboard {
  const Leaderboard({required this.week, required this.top, this.me, this.myRank});
  final String week;
  final List<LeaderboardEntry> top;
  final LeaderboardEntry? me;
  final int? myRank;
}
