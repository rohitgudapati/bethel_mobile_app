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
  const DailyVerse({required this.id, required this.date, this.text, this.reference, this.image, this.likes = 0});
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
  const LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.youtubeUrl,
    this.isLive = false,
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

class Album {
  final int id;
  final String title;
  final String image;
  final String artist;
  const Album({required this.id, required this.title, required this.image, this.artist = ''});
}

class Song {
  final int id;
  final String title;
  final String artist;
  final String image;
  final String? albumTitle;
  /// Lyrics keyed by language name, e.g. {'English': '...', 'Telugu': '...'}.
  final Map<String, String> lyrics;
  final String? chordKey;
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.image,
    this.albumTitle,
    this.lyrics = const {},
    this.chordKey,
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

class UserProfile {
  final String name;
  final String email;
  final String? token;
  const UserProfile({required this.name, required this.email, this.token});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
