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
    this.ref = 0,
    this.live = false,
    this.short = false,
    this.playlistIds = const [],
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

  /// The app's id for this video, used for comments and notes (as a [Sermon] id).
  final int ref;

  /// A finished live stream (a service), shown under Live.
  final bool live;

  /// A YouTube Short, shown under Shorts.
  final bool short;

  /// The channel playlists this video is in.
  final List<String> playlistIds;

  Sermon toSermon() => Sermon(
        id: ref,
        title: title,
        preacher: preacher,
        date: published,
        image: thumbnail,
        videoUrl: 'https://www.youtube.com/watch?v=$id',
        youtubeId: embeddable ? id : null,
        description: description,
        duration: duration,
      );
}
