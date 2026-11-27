/// A note from a sermon or Bible reading. Date, speaker and passage are optional and filterable.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.speaker = '',
    this.passage = '',
    this.sermonId,
    required this.updated,
  });

  final String id;
  final String title;
  final String body;

  /// The day it's about (the sermon's date, or when it was written).
  final DateTime date;
  final String speaker;

  /// A Bible reference such as "Philippians 4:6–7".
  final String passage;

  /// Set when the note belongs to a sermon page.
  final int? sermonId;
  final DateTime updated;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  /// Title for lists: the title, or the first line of the text.
  String get heading {
    if (title.trim().isNotEmpty) return title.trim();
    final first = body.trim().split('\n').first;
    return first.isEmpty ? 'Untitled note' : first;
  }

  Note copyWith({String? title, String? body, DateTime? date, String? speaker, String? passage, DateTime? updated}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        date: date ?? this.date,
        speaker: speaker ?? this.speaker,
        passage: passage ?? this.passage,
        sermonId: sermonId,
        updated: updated ?? this.updated,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'date': date.toIso8601String(),
        'speaker': speaker,
        'passage': passage,
        'sermonId': sermonId,
        'updated': updated.toIso8601String(),
      };

  static Note? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      return Note(
        id: j['id'] as String,
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        speaker: (j['speaker'] as String?) ?? '',
        passage: (j['passage'] as String?) ?? '',
        sermonId: (j['sermonId'] as num?)?.toInt(),
        updated: DateTime.tryParse((j['updated'] as String?) ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Which notes to show.
class NoteFilter {
  const NoteFilter({this.speaker, this.from, this.to, this.book, this.query = ''});
  final String? speaker;
  final DateTime? from;
  final DateTime? to;

  /// A book name; matches notes whose passage starts with it.
  final String? book;
  final String query;

  bool get isEmpty => speaker == null && from == null && to == null && book == null && query.trim().isEmpty;

  bool matches(Note n) {
    if (speaker != null && n.speaker != speaker) return false;
    final d = DateTime(n.date.year, n.date.month, n.date.day);
    if (from != null && d.isBefore(from!)) return false;
    if (to != null && d.isAfter(to!)) return false;
    if (book != null && !n.passage.startsWith('${book!} ')) return false;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final hay = '${n.title}\n${n.body}\n${n.speaker}\n${n.passage}'.toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  NoteFilter copyWith({String? speaker, DateTime? from, DateTime? to, String? book, String? query, bool clearSpeaker = false, bool clearDates = false, bool clearBook = false}) =>
      NoteFilter(
        speaker: clearSpeaker ? null : (speaker ?? this.speaker),
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        book: clearBook ? null : (book ?? this.book),
        query: query ?? this.query,
      );
}
