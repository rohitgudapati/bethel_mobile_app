import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'books.dart';

/// Bible versions bundled with the app. Both work offline.
/// NKJV and NASB need a licence and will be added later as online versions.
enum BibleVersion {
  kjv('KJV', 'King James Version', 'assets/bible/kjv.json.gz', telugu: false),
  te('తెలుగు', 'Telugu Bible (BSI)', 'assets/bible/te.json.gz', telugu: true);

  const BibleVersion(this.short, this.name, this.asset, {required this.telugu});
  final String short;
  final String name;
  final String asset;
  final bool telugu;

  static BibleVersion fromName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => kjv);
}

typedef BibleData = List<List<List<String>>>;

/// Loads and caches the bundled texts: books → chapters → verses.
class BibleText {
  static final _cache = <BibleVersion, Future<BibleData>>{};
  static final _ready = <BibleVersion, BibleData>{};

  /// The text if it has already loaded, so screens can draw it straight away.
  static BibleData? ready(BibleVersion v) => _ready[v];

  static Future<BibleData> load(BibleVersion v) {
    return _cache[v] ??= _load(v).then((d) => _ready[v] = d).catchError((Object e) {
      _cache.remove(v);
      throw e;
    });
  }

  static Future<BibleData> _load(BibleVersion v) async {
    final bytes = await rootBundle.load(v.asset);
    return compute(decodeBible, bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }

  /// Verses of one chapter (1-based chapter number).
  static Future<List<String>> chapter(BibleVersion v, int book, int chapter) async => (await load(v))[book][chapter - 1];
}

BibleData decodeBible(Uint8List gz) {
  final data = jsonDecode(utf8.decode(const GZipDecoder().decodeBytes(gz))) as List;
  return [
    for (final b in data) [for (final c in b as List) List<String>.from(c as List)]
  ];
}

/// "John 3", "John 3:16" or "John 3:16–18", in English or Telugu.
String bibleRef(int book, int chapter, {List<int> verses = const [], bool telugu = false}) {
  final b = bibleBooks[book];
  final name = telugu ? b.teName : b.name;
  if (verses.isEmpty) return '$name $chapter';
  final v = [...verses]..sort();
  final contiguous = v.last - v.first == v.length - 1;
  final range = v.length == 1 ? '${v.first}' : (contiguous ? '${v.first}–${v.last}' : v.join(', '));
  return '$name $chapter:$range';
}

/// A parsed reference such as "Proverbs 3:5-6" or "1 John 4:8".
class BibleRef {
  const BibleRef(this.book, this.chapter, this.from, this.to);
  final int book;
  final int chapter;
  final int from;
  final int to;
}

final _refPattern = RegExp(r'^\s*((?:[1-3]\s*)?[A-Za-z][A-Za-z .]*?)\s*(\d+)\s*[:.]\s*(\d+)(?:\s*[-–—]\s*(\d+))?\s*$');

/// Understands English book names as the church writes them ("Psalm 23:1", "Song of Songs 2:4",
/// "1 John 4:8", "Proverbs 3:5–6"). Returns null when it can't.
BibleRef? parseBibleRef(String? text) {
  if (text == null) return null;
  final m = _refPattern.firstMatch(text.replaceAll(RegExp(r'\s*\(.*\)$'), ''));
  if (m == null) return null;
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  var name = norm(m.group(1)!);
  const aliases = {'psalm': 'psalms', 'songofsongs': 'songofsolomon', 'song': 'songofsolomon', 'revelations': 'revelation'};
  name = aliases[name] ?? name;
  final book = bibleBooks.indexWhere((b) => norm(b.name) == name);
  if (book < 0) return null;
  final chapter = int.parse(m.group(2)!);
  final from = int.parse(m.group(3)!);
  final to = int.tryParse(m.group(4) ?? '') ?? from;
  if (chapter < 1 || chapter > bibleBooks[book].chapters || to < from) return null;
  return BibleRef(book, chapter, from, to);
}

/// The text of a reference in a version, or null if it's out of range.
Future<String?> biblePassage(BibleVersion v, BibleRef r) async {
  final verses = await BibleText.chapter(v, r.book, r.chapter);
  if (r.from < 1 || r.to > verses.length) return null;
  return verses.sublist(r.from - 1, r.to).join(' ');
}
