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
