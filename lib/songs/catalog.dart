import '../data/models.dart';
import '../data/repository.dart';
import 'topics.dart';

/// A section of a song book, by number range (as the printed book is organised).
class SongTopic {
  const SongTopic({required this.en, required this.te, required this.from, required this.to, this.icon = 'music'});
  final String en;
  final String te;
  final int from;
  final int to;
  final String icon;

  bool contains(Song s) => s.number >= from && s.number <= to;
  String get range => '$from–$to';

  static SongTopic? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return SongTopic(
        en: j['en'] as String,
        te: (j['te'] as String?) ?? '',
        from: (j['from'] as num).toInt(),
        to: (j['to'] as num).toInt(),
        icon: (j['icon'] as String?) ?? 'music',
      );
    } catch (_) {
      return null;
    }
  }
}

/// A numbered song book (Songs of Zion, Hymns of Faith, Bethel English Songs).
class SongBook {
  SongBook({required this.album, required this.songs, required this.topics});
  final Album album;
  final List<Song> songs;
  final List<SongTopic> topics;

  List<Song> inTopic(SongTopic t) => songs.where(t.contains).toList();
}

/// Everything the Songs tab shows. Today it's built from the repository and a bundled topics
/// file; once Firebase is set up it comes from the per-book catalog files the server builds
/// (see docs/firebase-setup.md), cached on the phone.
class SongCatalog {
  SongCatalog({required this.books, required this.albums, required this.albumSongs});
  final List<SongBook> books;

  /// Albums that aren't song books, newest first.
  final List<Album> albums;
  final Map<int, List<Song>> albumSongs;

  List<Song> get allSongs => [for (final b in books) ...b.songs];
  Album? get newest => albums.where((a) => a.isNew).firstOrNull;

  static Future<SongCatalog> load(BethelRepository repo) async {
    final all = await repo.albums();
    final topics = await _topics();
    final books = <SongBook>[];
    for (final a in all.where((a) => a.isSongBook)) {
      final songs = await repo.songsForAlbum(a.id);
      songs.sort((x, y) => x.number.compareTo(y.number));
      books.add(SongBook(album: a, songs: songs, topics: topics[a.title] ?? const []));
    }
    final albums = all.where((a) => !a.isSongBook).toList()
      ..sort((x, y) => (y.addedOn ?? DateTime(2000)).compareTo(x.addedOn ?? DateTime(2000)));
    final albumSongs = <int, List<Song>>{};
    for (final a in albums.where((a) => a.isNew)) {
      albumSongs[a.id] = await repo.songsForAlbum(a.id);
    }
    return SongCatalog(books: books, albums: albums, albumSongs: albumSongs);
  }

  static Future<Map<String, List<SongTopic>>> _topics() async => draftTopics;
}
