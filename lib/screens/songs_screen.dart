import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/launch.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../songs/catalog.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';

/// Songs tab: the newest album, the song books, albums, and search by title, lyrics or number.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  bool _numbers = false;

  /// Search results replace the library while this is on. Focusing the field turns it on;
  /// only Cancel (or clearing an unfocused field) turns it off.
  bool _searchMode = false;
  late Future<SongCatalog> _catalog = SongCatalog.load(AppScope.read(context).repo);
  bool _openedLaunchBook = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {
          if (_focus.hasFocus) _searchMode = true;
        }));
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _reload() {
    final c = SongCatalog.load(AppScope.read(context).repo);
    setState(() {
      _catalog = c;
    });
  }

  void _toggleNumbers() {
    // The focused field updates its keyboard in place when the type changes.
    setState(() {
      _numbers = !_numbers;
      _searchMode = true;
    });
    if (!_focus.hasFocus) _focus.requestFocus();
  }

  void _cancelSearch() {
    _search.clear();
    _focus.unfocus();
    setState(() {
      _numbers = false;
      _searchMode = false;
    });
  }

  void _openFirst(SongCatalog c) {
    final hits = _hits(c, _search.text.trim());
    final first = [...hits.numbers, ...hits.titles, ...hits.lyrics].firstOrNull;
    if (first != null) openSong(context, first.$1);
  }

  void _maybeOpenLaunchBook(SongCatalog c) {
    final wanted = LaunchOptions.book;
    if (_openedLaunchBook || wanted == null) return;
    _openedLaunchBook = true;
    final b = c.books.where((b) => b.album.title.toLowerCase().contains(wanted)).firstOrNull;
    if (b != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SongBookScreen(book: b)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final searching = _searchMode || _search.text.isNotEmpty;
    return SafeArea(
      bottom: false,
      child: FutureBuilder<SongCatalog>(
        future: _catalog,
        builder: (context, snap) {
          final c = snap.data;
          if (c != null) _maybeOpenLaunchBook(c);
          return CustomScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(children: [
                if (!searching)
                  ScreenTitle(
                    'Songs',
                    trailing: IconButton(
                      tooltip: 'Saved songs',
                      icon: const Icon(Icons.favorite_border_rounded),
                      onPressed: c == null
                          ? null
                          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedSongsScreen(catalog: c))),
                    ),
                  ),
                if (!searching) const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _SearchField(
                      controller: _search,
                      focus: _focus,
                      numbers: _numbers,
                      onChanged: () => setState(() {}),
                      onToggleNumbers: _toggleNumbers,
                      onSubmitted: c == null ? null : () => _openFirst(c),
                    ),
                  ),
                  if (searching) TextButton(onPressed: _cancelSearch, child: const Text('Cancel')),
                ]),
              ]),
            ),
            if (c == null)
              SliverToBoxAdapter(
                child: snap.hasError
                    ? BethelEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Couldn’t load songs',
                        message: 'Check your connection and try again',
                        action: OutlinedButton(onPressed: _reload, child: const Text('Try again')),
                      )
                    : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              )
            else if (searching)
              ..._searchResults(c, _search.text.trim(), t)
            else
              ..._library(c, t),
            SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
          ]);
        },
      ),
    );
  }

  // ------------------------------------------------------------------ library

  List<Widget> _library(SongCatalog c, ThemeData t) {
    final state = AppScope.of(context);
    final tk = BethelTokens.of(context);
    final newest = c.newest;
    final recent = state.recentSongs.take(8).toList();
    // Heights fit the cover plus two lines of text, with room for larger text sizes.
    Widget shelf(List<Widget> items, {required double height}) => SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => items[i],
          ),
        );
    return [
      if (newest != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Pressable(
              semanticLabel: 'New album: ${newest.title}',
              onTap: () => openAlbum(context, newest),
              child: Row(children: [
                SongCover(title: newest.title, sub: _year(newest), color: SongCover.colorFor(newest.id), size: 96),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(newest.addedOn == null ? 'New' : 'New · added ${_mon(newest.addedOn!)}',
                        style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
                    const SizedBox(height: 2),
                    Text(newest.title, style: t.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (c.albumSongs[newest.id] != null) '${c.albumSongs[newest.id]!.length} songs',
                        if (newest.dates.isNotEmpty) newest.dates,
                      ].join(' · '),
                      style: t.textTheme.bodySmall,
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      if (c.books.isNotEmpty) ...[
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 28, 20, 12), sliver: SliverToBoxAdapter(child: BethelSectionTitle('Song books'))),
        SliverToBoxAdapter(
          child: shelf([
            for (final b in c.books)
              Pressable(
                semanticLabel: '${b.album.title}, ${b.songs.length} songs',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongBookScreen(book: b))),
                child: SizedBox(
                  width: 148,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SongCover(
                      title: b.album.title == 'Songs of Zion' ? 'సీయోను\nగీతములు' : b.album.title,
                      sub: '',
                      color: SongCover.colorFor(b.album.id),
                      size: 148,
                      telugu: b.album.title == 'Songs of Zion',
                    ),
                    const SizedBox(height: 8),
                    Text(b.album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                    Text('${b.songs.length} songs${b.album.language.isEmpty ? '' : ' · ${b.album.language}'}', style: t.textTheme.bodySmall),
                  ]),
                ),
              ),
          ], height: 148 + 8 + 64),
        ),
      ],
      if (c.albums.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: BethelSectionTitle('Albums',
                action: c.albums.length > 3 ? 'See all' : null,
                onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumsScreen(albums: c.albums)))),
          ),
        ),
        SliverToBoxAdapter(
          child: shelf([
            for (final a in c.albums)
              Pressable(
                semanticLabel: a.title,
                onTap: () => openAlbum(context, a),
                child: SizedBox(
                  width: 120,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    a.image.isEmpty
                        ? SongCover(title: a.title, sub: _year(a), color: SongCover.colorFor(a.id), size: 120)
                        : BethelImage(a.image, width: 120, height: 120, radius: 12),
                    const SizedBox(height: 8),
                    Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
          ], height: 120 + 8 + 52),
        ),
      ],
      if (recent.isNotEmpty) ...[
        const SliverPadding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), sliver: SliverToBoxAdapter(child: BethelSectionTitle('Recently viewed'))),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [for (final s in recent.take(4)) SongRow(song: s, showBook: true)]),
        ),
      ],
    ];
  }

  // ------------------------------------------------------------------ search

  static bool _matches(Song s, String q) =>
      s.title.toLowerCase().contains(q) ||
      s.altTitle.toLowerCase().contains(q) ||
      s.lyricist.toLowerCase().contains(q) ||
      s.artist.toLowerCase().contains(q);

  ({List<(Song, String)> numbers, List<(Song, String)> titles, List<(Song, String)> lyrics}) _hits(SongCatalog c, String query) {
    final q = query.toLowerCase();
    final n = int.tryParse(q);
    final numbers = <(Song, String)>[], titles = <(Song, String)>[], lyrics = <(Song, String)>[];
    if (q.isEmpty) return (numbers: numbers, titles: titles, lyrics: lyrics);
    for (final b in c.books) {
      for (final s in b.songs) {
        if (n != null) {
          if (s.number == n) numbers.add((s, b.album.title));
        } else if (_matches(s, q)) {
          titles.add((s, b.album.title));
        } else if (s.lyrics.values.any((l) => l.toLowerCase().contains(q))) {
          lyrics.add((s, b.album.title));
        }
      }
    }
    return (numbers: numbers, titles: titles, lyrics: lyrics);
  }

  List<Widget> _searchResults(SongCatalog c, String query, ThemeData t) {
    if (query.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              _numbers ? 'Type a song number. Return opens the first match.' : 'Search by title, words from the song, or a number. Tap # for the number pad.',
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ];
    }
    final h = _hits(c, query);
    if (h.numbers.isEmpty && h.titles.isEmpty && h.lyrics.isEmpty) {
      final n = int.tryParse(query);
      final max = c.books.isEmpty ? 0 : c.books.map((b) => b.songs.isEmpty ? 0 : b.songs.last.number).reduce((a, b) => a > b ? a : b);
      return [
        SliverToBoxAdapter(
          child: BethelEmptyState(
            icon: Icons.search_rounded,
            title: n != null ? 'No song number $n' : 'No songs match “$query”',
            message: n != null ? 'Our books go up to $max' : 'Try a song number, a shorter word or another spelling',
          ),
        ),
      ];
    }
    final tk = BethelTokens.of(context);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverList.list(children: [
          if (h.numbers.isNotEmpty) ...[
            // The first match gets a big card; the same number in other books follows.
            Pressable(
              semanticLabel: 'Song ${h.numbers.first.$1.number}, ${h.numbers.first.$1.title}',
              onTap: () => openSong(context, h.numbers.first.$1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
                child: Row(children: [
                  HymnPlaque('${h.numbers.first.$1.number}', large: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.numbers.first.$2, style: t.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(_display(h.numbers.first.$1), style: _titleStyle(context, _display(h.numbers.first.$1), size: BethelType.lead)),
                      if (_isTelugu(_display(h.numbers.first.$1))) Text(h.numbers.first.$1.title, style: t.textTheme.bodySmall),
                    ]),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: t.colorScheme.primary),
                ]),
              ),
            ),
            if (h.numbers.length > 1) ...[
              const SizedBox(height: 16),
              Text('Also number ${h.numbers.first.$1.number}', style: t.textTheme.bodySmall),
              for (final (s, _) in h.numbers.skip(1)) SongRow(song: s, showBook: true),
            ],
          ],
          if (h.titles.isNotEmpty) ...[
            const BethelSectionTitle('Titles'),
            for (final (s, _) in h.titles.take(40)) SongRow(song: s, showBook: true),
          ],
          if (h.lyrics.isNotEmpty) ...[
            if (h.titles.isNotEmpty) const SizedBox(height: 20),
            const BethelSectionTitle('In lyrics'),
            for (final (s, _) in h.lyrics.take(40)) SongRow(song: s, showBook: true, lyricMatch: _lyricLine(s, query.toLowerCase())),
          ],
        ]),
      ),
    ];
  }

  static String? _lyricLine(Song s, String q) {
    for (final l in s.lyrics.values) {
      for (final line in l.split('\n')) {
        if (line.toLowerCase().contains(q)) return '“${line.trim()}”';
      }
    }
    return null;
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _mon(DateTime d) => '${_months[d.month - 1]} ${d.day}';
String _year(Album a) => RegExp(r'\d{4}').firstMatch('${a.title} ${a.dates}')?.group(0) ?? '';

void openSong(BuildContext context, Song song) {
  AppScope.read(context).openedSong(song);
  Navigator.push(context, MaterialPageRoute(builder: (_) => SongScreen(song: song)));
}

void openAlbum(BuildContext context, Album album) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumScreen(album: album)));

/// True when the text is mostly Telugu script, so it gets the Telugu serif.
bool _isTelugu(String s) => s.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F);

/// The title to show first: the Telugu title when there is one.
String _display(Song s) => s.altTitle.isNotEmpty && _isTelugu(s.altTitle) ? s.altTitle : s.title;

TextStyle? _titleStyle(BuildContext context, String title, {double? size}) {
  final base = Theme.of(context).textTheme.titleSmall;
  if (!_isTelugu(title)) return size == null ? base : base?.copyWith(fontSize: size);
  return base?.copyWith(fontFamily: BethelFonts.telugu, fontWeight: FontWeight.w400, fontSize: size ?? BethelType.lead, height: 1.4);
}

/// Typographic cover for a book or album without a picture: Forest-family colour, brass rule, title.
class SongCover extends StatelessWidget {
  const SongCover({super.key, required this.title, required this.sub, required this.color, required this.size, this.telugu = false});
  final String title;
  final String sub;
  final Color color;
  final double size;
  final bool telugu;

  static const _colors = [BethelColors.forest, Color(0xFF3C5A52), BethelColors.ink, Color(0xFF8E7449)];
  static Color colorFor(int id) => _colors[id % _colors.length];

  @override
  Widget build(BuildContext context) {
    final big = size >= 120;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size >= 96 ? 12 : 8)),
        child: Stack(children: [
          Positioned(
            right: -size * 0.22,
            top: -size * 0.22,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BethelColors.brassLight.withValues(alpha: 0.35))),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 20, height: 1, color: BethelColors.brassLight),
            SizedBox(height: size * 0.05),
            Text(title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: telugu ? BethelFonts.telugu : BethelFonts.display,
                  fontSize: big ? size * 0.13 : size * 0.15,
                  height: telugu ? 1.35 : 1.15,
                  color: BethelColors.ivory,
                )),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: size >= 96 ? 11 : 10, color: BethelColors.brassLight)),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focus,
    required this.numbers,
    required this.onChanged,
    required this.onToggleNumbers,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final bool numbers;
  final VoidCallback onChanged;
  final VoidCallback onToggleNumbers;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return TextField(
      controller: controller,
      focusNode: focus,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted?.call(),
      keyboardType: numbers ? TextInputType.number : TextInputType.text,
      inputFormatters: numbers ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: BethelType.body),
      decoration: InputDecoration(
        hintText: numbers ? 'Song number' : 'Search songs or type a number',
        hintStyle: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
        fillColor: tk.raised,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
        suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear search',
              icon: Icon(Icons.close_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
              onPressed: () {
                controller.clear();
                onChanged();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              toggled: numbers,
              label: 'Number pad',
              child: Material(
                color: numbers ? t.colorScheme.primary : tk.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: numbers ? Colors.transparent : tk.hairline)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onToggleNumbers,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(Icons.tag_rounded, size: 16, color: numbers ? t.colorScheme.onPrimary : t.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.colorScheme.primary, width: 2)),
      ),
    );
  }
}

/// One song in a list: hymn-board plaque, title (Telugu in the Telugu serif), lyricist or book.
class SongRow extends StatelessWidget {
  const SongRow({super.key, required this.song, this.showBook = false, this.lyricMatch, this.trailing});
  final Song song;
  final bool showBook;

  /// The lyric line that matched a search.
  final String? lyricMatch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final telugu = song.altTitle.isNotEmpty && _isTelugu(song.altTitle);
    final title = telugu ? song.altTitle : song.title;
    final sub = lyricMatch ??
        [
          if (telugu) song.title,
          if (song.lyricist.isNotEmpty) song.lyricist else if (song.artist.isNotEmpty) song.artist,
          if (showBook && (song.albumTitle ?? '').isNotEmpty) song.albumTitle!,
        ].join(' · ');
    return HairlineRow(
      leading: song.number > 0 ? HymnPlaque('${song.number}') : BethelImage(song.image, width: 44, height: 44, radius: 8),
      title: title,
      titleStyle: _titleStyle(context, title),
      subtitle: sub.isEmpty ? null : sub,
      trailing: trailing,
      onTap: () => openSong(context, song),
    );
  }
}

// ===================================================================== song book

/// A song book: topics (by number range), A–Z, or every song by number.
class SongBookScreen extends StatefulWidget {
  const SongBookScreen({super.key, required this.book});
  final SongBook book;

  @override
  State<SongBookScreen> createState() => _SongBookScreenState();
}

class _SongBookScreenState extends State<SongBookScreen> {
  late int _tab = widget.book.topics.isEmpty ? 1 : 0;
  bool _teluguSort = false;
  String? _letter;

  static const _icons = <String, IconData>{
    'book': Icons.menu_book_outlined,
    'worship': Icons.volunteer_activism_outlined,
    'music': Icons.music_note_outlined,
    'thanks': Icons.favorite_border_rounded,
    'calendar': Icons.calendar_today_outlined,
    'star': Icons.star_outline_rounded,
    'cross': Icons.add_rounded,
    'sun': Icons.wb_sunny_outlined,
    'cloud': Icons.cloud_outlined,
    'campaign': Icons.campaign_outlined,
    'invite': Icons.waving_hand_outlined,
    'heart': Icons.favorite_border_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final b = widget.book;
    final zion = b.album.title == 'Songs of Zion';
    final tabs = [if (b.topics.isNotEmpty) 'Topics', 'A–Z', 'By number'];
    final tab = b.topics.isEmpty ? _tab - 1 : _tab;
    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.list(children: [
            Row(children: [
              SongCover(title: zion ? 'సీయోను\nగీతములు' : b.album.title, sub: '', color: SongCover.colorFor(b.album.id), size: 72, telugu: zion),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.album.title, style: t.textTheme.headlineSmall),
                  Text('${b.songs.length} songs${b.album.language.isEmpty ? '' : ' · ${b.album.language}'}', style: t.textTheme.bodySmall),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            UnderlineTabs(labels: tabs, selected: tab.clamp(0, tabs.length - 1), onSelected: (i) => setState(() => _tab = b.topics.isEmpty ? i + 1 : i)),
          ]),
        ),
        if (b.songs.isEmpty)
          const SliverToBoxAdapter(
            child: BethelEmptyState(icon: Icons.library_music_outlined, title: 'No songs in this book yet', message: 'Songs appear here once the church adds them'),
          )
        else if (_tab == 0)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 92),
              itemCount: b.topics.length,
              itemBuilder: (_, i) {
                final tp = b.topics[i];
                return Material(
                  color: tk.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: tk.hairline)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongTopicScreen(book: b, topic: tp))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
                          child: Icon(_icons[tp.icon] ?? Icons.music_note_outlined, size: 18, color: tk.brassText),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (tp.te.isNotEmpty)
                              Text(tp.te, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: BethelFonts.telugu, fontSize: 13, height: 1.3)),
                            Text(tp.en, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                            Text(tp.range, style: t.textTheme.bodySmall?.copyWith(fontSize: 11)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          )
        else if (_tab == 1)
          ..._az(b, t)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList.builder(itemCount: b.songs.length, itemBuilder: (_, i) => SongRow(song: b.songs[i])),
          ),
      ]),
    );
  }

  List<Widget> _az(SongBook b, ThemeData t) {
    final hasTelugu = b.songs.any((s) => _isTelugu(s.altTitle));
    String key(Song s) => (_teluguSort && _isTelugu(s.altTitle) ? s.altTitle : s.title).trim();
    final sorted = [...b.songs]..sort((x, y) => key(x).toLowerCase().compareTo(key(y).toLowerCase()));
    String first(Song s) {
      final k = key(s);
      return k.isEmpty ? '#' : String.fromCharCodes(k.runes.take(1)).toUpperCase();
    }

    final letters = <String>[];
    for (final s in sorted) {
      final f = first(s);
      if (!letters.contains(f)) letters.add(f);
    }
    final shown = _letter == null ? sorted : sorted.where((s) => first(s) == _letter).toList();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Row(children: [
            Expanded(child: Text(_teluguSort ? 'Sorted by Telugu title' : 'Sorted by English spelling', style: t.textTheme.bodySmall)),
            if (hasTelugu)
              TextButton(
                onPressed: () => setState(() {
                  _teluguSort = !_teluguSort;
                  _letter = null;
                }),
                child: Text(_teluguSort ? 'Sort in English' : 'Sort in తెలుగు', style: const TextStyle(fontFamilyFallback: [BethelFonts.telugu])),
              ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 48,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), children: [
            for (final l in ['All', ...letters])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(l, style: const TextStyle(fontFamilyFallback: [BethelFonts.telugu])),
                  selected: l == 'All' ? _letter == null : _letter == l,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _letter = l == 'All' ? null : l),
                ),
              ),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        sliver: SliverList.builder(itemCount: shown.length, itemBuilder: (_, i) => SongRow(song: shown[i])),
      ),
    ];
  }
}

class SongTopicScreen extends StatelessWidget {
  const SongTopicScreen({super.key, required this.book, required this.topic});
  final SongBook book;
  final SongTopic topic;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final songs = book.inTopic(topic);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
        if (topic.te.isNotEmpty) Text(topic.te, style: TextStyle(fontFamily: BethelFonts.telugu, fontSize: 15, color: tk.brassText)),
        Text(topic.en, style: t.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('${book.album.title} · songs ${topic.range} · ${songs.length} ${songs.length == 1 ? 'song' : 'songs'}', style: t.textTheme.bodySmall),
        const SizedBox(height: 12),
        if (songs.isEmpty)
          const BethelEmptyState(icon: Icons.library_music_outlined, title: 'No songs here yet', message: 'Songs in this range appear once they’re added')
        else
          for (final s in songs) SongRow(song: s),
      ]),
    );
  }
}

// ===================================================================== albums

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key, required this.albums});
  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 16, childAspectRatio: 0.8),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final a = albums[i];
          return Pressable(
            semanticLabel: a.title,
            onTap: () => openAlbum(context, a),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (_, c) => a.image.isEmpty
                      ? SongCover(title: a.title, sub: _year(a), color: SongCover.colorFor(a.id), size: c.maxWidth)
                      : BethelImage(a.image, radius: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
              Text(a.dates.isNotEmpty ? a.dates : a.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
            ]),
          );
        },
      ),
    );
  }
}

/// An album: cover, dates, Present all, Save offline, then the songs in the order they'll be sung.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: 'Share album',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => SharePlus.instance.share(ShareParams(text: '${album.title}${album.dates.isEmpty ? '' : ' · ${album.dates}'}\nSongs in the Bethel Prayer House app')),
        ),
      ]),
      body: AsyncView<List<Song>>(
        load: () => state.repo.songsForAlbum(album.id),
        builder: (context, songs) {
          final allSaved = songs.isNotEmpty && songs.every((s) => state.downloadedSongs.contains(s.id));
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              album.image.isEmpty
                  ? SongCover(title: album.title, sub: _year(album), color: SongCover.colorFor(album.id), size: 132)
                  : BethelImage(album.image, width: 132, height: 132, radius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(album.dates.isEmpty ? 'Album' : 'Album · ${album.dates}', style: t.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(album.title, style: t.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('${songs.length} ${songs.length == 1 ? 'song' : 'songs'}', style: t.textTheme.bodySmall),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (songs.isNotEmpty)
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresentLoader(song: songs.first, queue: songs))),
                    icon: const Icon(Icons.slideshow_outlined, size: 18),
                    label: const Text('Present all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      for (final s in songs) {
                        if (allSaved == state.downloadedSongs.contains(s.id)) state.toggleDownload(s.id);
                      }
                      showBethelToast(context, allSaved ? 'Removed from this phone' : 'Saved for offline use', icon: Icons.download_done_rounded);
                    },
                    icon: Icon(allSaved ? Icons.download_done_rounded : Icons.download_rounded, size: 18),
                    label: Text(allSaved ? 'Saved offline' : 'Save offline'),
                  ),
                ),
              ]),
            const SizedBox(height: 12),
            if (songs.isEmpty)
              const BethelEmptyState(icon: Icons.album_outlined, title: 'No songs yet', message: 'Songs appear here once the church adds them')
            else
              for (var i = 0; i < songs.length; i++)
                HairlineRow(
                  leading: HymnPlaque('${i + 1}'),
                  title: _display(songs[i]),
                  titleStyle: _titleStyle(context, _display(songs[i])),
                  subtitle: [
                    if (_isTelugu(_display(songs[i]))) songs[i].title,
                    if ((songs[i].albumTitle ?? '').isNotEmpty) '${songs[i].albumTitle} ${songs[i].number > 0 ? songs[i].number : ''}'.trim(),
                  ].join(' · '),
                  onTap: () => openSong(context, songs[i]),
                ),
          ]);
        },
      ),
    );
  }
}

/// Saved songs and downloads, with a sign-in state for guests.
class SavedSongsScreen extends StatelessWidget {
  const SavedSongsScreen({super.key, required this.catalog});
  final SongCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final all = {for (final s in [...catalog.allSongs, ...state.recentSongs]) s.id: s};
    final saved = state.savedSongs.map((id) => all[id]).whereType<Song>().toList();
    final downloaded = state.downloadedSongs.map((id) => all[id]).whereType<Song>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved songs')),
      body: state.guest
          ? BethelEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Sign in to save songs',
              message: 'Your saved songs and downloads stay with your account on every device',
              action: FilledButton(onPressed: () => showSignInPrompt(context, title: 'Sign in to save songs', icon: Icons.favorite_border_rounded), child: const Text('Sign in')),
            )
          : saved.isEmpty && downloaded.isEmpty
              ? const BethelEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No saved songs yet',
                  message: 'Tap the heart on any song to keep it here. Downloads work without internet.',
                )
              : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
                  if (saved.isNotEmpty) ...[
                    const BethelSectionTitle('Saved'),
                    for (final s in saved) SongRow(song: s, showBook: true),
                  ],
                  if (downloaded.isNotEmpty) ...[
                    if (saved.isNotEmpty) const SizedBox(height: 20),
                    const BethelSectionTitle('On this phone'),
                    for (final s in downloaded)
                      SongRow(song: s, showBook: true, trailing: Icon(Icons.download_done_rounded, size: 18, color: t.colorScheme.onSurfaceVariant)),
                  ],
                ]),
    );
  }
}

// ===================================================================== song page

/// Song page: lyrics on the page like an open hymnal. Actions in the bar: text size, save, share, present.
class SongScreen extends StatefulWidget {
  const SongScreen({super.key, required this.song});
  final Song song;

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late final Future<Song> _detail = AppScope.read(context).repo.songDetail(widget.song);
  String? _lang;

  void _toggleSave(Song song) {
    final state = AppScope.read(context);
    if (state.guest) {
      _signInPrompt();
      return;
    }
    final saving = !state.savedSongs.contains(song.id);
    state.toggleSavedSong(song.id);
    showBethelToast(context, saving ? 'Saved to your songs' : 'Removed from your songs',
        icon: saving ? Icons.favorite_rounded : Icons.favorite_border_rounded);
  }

  void _signInPrompt() => showSignInPrompt(context, title: 'Sign in to save songs', icon: Icons.favorite_border_rounded);

  void _textSize(Song song) {
    showBethelSheet<void>(context, builder: (ctx) => _TextSizeSheet(song: song));
  }

  Future<void> _share(Song song) async {
    final box = context.findRenderObject() as RenderBox?;
    final book = (song.albumTitle ?? '').isEmpty ? '' : ' · ${song.albumTitle}';
    await SharePlus.instance.share(ShareParams(
      text: '${song.label}$book\nBethel Prayer House',
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return FutureBuilder<Song>(
      future: _detail,
      builder: (context, snap) {
        final song = snap.data ?? widget.song;
        final langs = song.lyrics.keys.toList();
        final lang = _lang != null && langs.contains(_lang) ? _lang! : (langs.isEmpty ? null : langs.first);
        final lyrics = lang == null ? null : song.lyrics[lang];
        final saved = state.savedSongs.contains(song.id);
        final telugu = song.altTitle.isNotEmpty && _isTelugu(song.altTitle);
        final title = telugu ? song.altTitle : song.title;
        final meta = [
          if (telugu) song.title,
          if (song.lyricist.isNotEmpty) song.lyricist,
          if ((song.albumTitle ?? '').isNotEmpty) song.albumTitle!,
        ].join(' · ');
        return Scaffold(
          appBar: AppBar(actions: [
            IconButton(tooltip: 'Text size', onPressed: () => _textSize(song), icon: const Icon(Icons.format_size_rounded)),
            IconButton(
              tooltip: saved ? 'Saved' : 'Save',
              onPressed: () => _toggleSave(song),
              icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? BethelColors.brass : null),
            ),
            IconButton(tooltip: 'Share', onPressed: () => _share(song), icon: const Icon(Icons.ios_share_rounded)),
            IconButton(
              tooltip: 'Present',
              onPressed: lyrics == null
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresentScreen(song: song, language: lang!))),
              icon: const Icon(Icons.slideshow_outlined),
            ),
            const SizedBox(width: 8),
          ]),
          body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 48), children: [
            Container(
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
              child: Row(children: [
                song.number > 0 ? HymnPlaque('${song.number}', large: true) : BethelImage(song.image, width: 64, height: 64, radius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title,
                        style: telugu
                            ? t.textTheme.headlineSmall?.copyWith(fontFamily: BethelFonts.telugu, fontSize: 22, height: 1.4)
                            : t.textTheme.headlineSmall),
                    if (meta.isNotEmpty) ...[const SizedBox(height: 4), Text(meta, style: t.textTheme.bodySmall)],
                    if (song.reference.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(song.reference, style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
                    ],
                  ]),
                ),
              ]),
            ),
            if (langs.length > 1) ...[
              const SizedBox(height: 16),
              UnderlineTabs(
                labels: [for (final l in langs) l == 'Telugu' ? 'తెలుగు' : l],
                selected: langs.indexOf(lang!),
                onSelected: (i) => setState(() => _lang = langs[i]),
              ),
            ],
            const SizedBox(height: 24),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (lyrics == null)
              BethelEmptyState(
                icon: Icons.music_note_outlined,
                title: 'Lyrics haven’t been added yet',
                message: (song.audioUrl ?? '').isEmpty
                    ? 'The church team is typing up this song. No recording has been uploaded either.'
                    : 'The church team is typing up this song. You can listen to the recording.',
                action: (song.audioUrl ?? '').isEmpty
                    ? null
                    : OutlinedButton.icon(
                        onPressed: () => openLink(context, song.audioUrl!),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play recording'),
                      ),
              )
            else
              _Lyrics(text: lyrics, scale: state.lyricsScale, telugu: lang == 'Telugu'),
          ]),
        );
      },
    );
  }
}

class _TextSizeSheet extends StatelessWidget {
  const _TextSizeSheet({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final downloaded = state.downloadedSongs.contains(song.id);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Text size', style: t.textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        const Text('A', style: TextStyle(fontFamily: BethelFonts.display, fontSize: 15)),
        Expanded(
          child: Slider(
            value: state.lyricsScale,
            min: 0.8,
            max: 1.8,
            divisions: 10,
            label: '${(state.lyricsScale * 100).round()}%',
            onChanged: state.setLyricsScale,
          ),
        ),
        const Text('A', style: TextStyle(fontFamily: BethelFonts.display, fontSize: 26)),
      ]),
      const Divider(height: 24),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: downloaded,
        onChanged: (_) => state.toggleDownload(song.id),
        title: const Text('Available offline'),
        subtitle: const Text('Keep these lyrics on this phone'),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
    ]);
  }
}

/// Lyrics on the page, one block per stanza, in the reading serif.
///
/// Song books like Songs of Zion write their own verse numbers ("1.") and refrain labels
/// ("Pallavi :", "పల్లవి :"), so labels are only added to songs that have none: "Verse 1", "Verse 2".
/// Refrains get a short brass rule so they are easy to find while singing.
class _Lyrics extends StatelessWidget {
  const _Lyrics({required this.text, required this.scale, required this.telugu});
  final String text;
  final double scale;
  final bool telugu;

  static final _numbered = RegExp(r'^\s*\d+\s*[.)]');
  static final _refrain = RegExp(
      r'^\s*(pallavi|anupallavi|a\.?\s*p\.?|chorus|refrain|పల్లవి|అనుపల్లవి|అ\.?\s*ప\.?)\s*:',
      caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final stanzas = text.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final labelled = stanzas.any((s) => _numbered.hasMatch(s) || _refrain.hasMatch(s));
    final style = TextStyle(
      fontFamily: telugu ? BethelFonts.telugu : BethelFonts.display,
      fontSize: (telugu ? 18 : BethelType.title) * scale,
      height: telugu ? 1.8 : 1.6,
      color: t.colorScheme.onSurface,
    );
    final label = t.textTheme.bodySmall;
    var verse = 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final s in stanzas)
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_refrain.hasMatch(s))
              const Padding(padding: EdgeInsets.only(bottom: 8, top: 8), child: BrassRule(width: 24))
            else if (!labelled)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Verse ${++verse}', style: label)),
            Text(s, style: style),
          ]),
        ),
    ]);
  }
}

/// Loads full lyrics, then opens present mode.
class PresentLoader extends StatelessWidget {
  const PresentLoader({super.key, required this.song, this.queue});
  final Song song;

  /// Songs to present one after another (an album's Present all).
  final List<Song>? queue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0C),
      body: queue != null
          ? AsyncView<List<Song>>(
              load: () => Future.wait([for (final s in queue!) AppScope.read(context).repo.songDetail(s)]),
              builder: (context, full) {
                final withLyrics = full.where((s) => s.lyrics.isNotEmpty).toList();
                if (withLyrics.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('None of these songs have lyrics yet',
                          textAlign: TextAlign.center, style: TextStyle(color: BethelColors.ivory, fontSize: BethelType.lead)),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
                    ]),
                  );
                }
                return PresentScreen(song: withLyrics.first, language: withLyrics.first.lyrics.keys.first, queue: withLyrics);
              },
            )
          : AsyncView<Song>(
        load: () => AppScope.read(context).repo.songDetail(song),
        builder: (context, full) => full.lyrics.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Lyrics for this song haven’t been added yet',
                        textAlign: TextAlign.center, style: TextStyle(color: BethelColors.ivory, fontSize: BethelType.lead)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
                  ]),
                ),
              )
            : PresentScreen(song: full, language: full.lyrics.keys.first),
      ),
    );
  }
}

/// Full-screen lyrics for projecting during worship: one stanza per page, swipe or use the arrows.
class PresentScreen extends StatefulWidget {
  const PresentScreen({super.key, required this.song, required this.language, this.queue});
  final Song song;
  final String language;

  /// Several songs in a row; each uses [language] when it has it, otherwise its first language.
  final List<Song>? queue;

  @override
  State<PresentScreen> createState() => _PresentScreenState();
}

class _PresentScreenState extends State<PresentScreen> {
  final _pages = PageController();
  int _page = 0;

  /// Every stanza to show, with its song, language, and place within the song.
  late final List<({Song song, String text, bool telugu, int verse, int verses})> _slides = [
    for (final song in widget.queue ?? [widget.song])
      ...() {
        final lang = song.lyrics.containsKey(widget.language) ? widget.language : song.lyrics.keys.firstOrNull;
        final parts = (song.lyrics[lang] ?? '').split(RegExp(r'\n\s*\n')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
        return [
          for (var i = 0; i < parts.length; i++) (song: song, text: parts[i], telugu: lang == 'Telugu', verse: i + 1, verses: parts.length)
        ];
      }(),
  ];
  List<String> get _stanzas => [for (final x in _slides) x.text];

  void _go(int delta) {
    final next = (_page + delta).clamp(0, _stanzas.length - 1);
    if (reduceMotion(context)) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(next, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0D0C);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text(
                    _slides.isEmpty
                        ? widget.song.title
                        : '${(widget.queue != null ? '${widget.queue!.indexOf(_slides[_page].song) + 1}/${widget.queue!.length} · ' : '')}${_slides[_page].song.title} · Verse ${_slides[_page].verse} of ${_slides[_page].verses}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: BethelType.caption, color: BethelColors.nightMuted)),
              ),
              _RoundButton(
                icon: Icons.close_rounded,
                label: 'Exit present mode',
                onTap: () => Navigator.pop(context),
                filled: false,
              ),
            ]),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _stanzas.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Center(
                  child: SingleChildScrollView(
                    child: Text(_stanzas[i],
                        style: TextStyle(
                          fontFamily: _slides[i].telugu ? BethelFonts.telugu : BethelFonts.display,
                          fontSize: _slides[i].telugu ? 28 : BethelType.display,
                          height: _slides[i].telugu ? 1.6 : 1.35,
                          color: BethelColors.ivory,
                        )),
                  ),
                ),
              ),
            ),
            Row(children: [
              _RoundButton(icon: Icons.chevron_left_rounded, label: 'Previous verse', onTap: _page > 0 ? () => _go(-1) : null, filled: false),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 1; i <= (_slides.isEmpty ? 0 : _slides[_page].verses); i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _slides[_page].verse ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _slides[_page].verse ? BethelColors.brass : const Color(0x4DFFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ]),
              ),
              _RoundButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next verse',
                  onTap: _page < _stanzas.length - 1 ? () => _go(1) : null,
                  filled: true),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap, required this.filled});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? BethelColors.ivory : Colors.transparent,
            border: filled ? null : Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Icon(icon, size: 26, color: filled ? BethelColors.ink : BethelColors.nightMuted),
        ),
      ),
    );
  }
}
