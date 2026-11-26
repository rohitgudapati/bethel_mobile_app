import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/launch.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';

/// Songs tab: one underline tab per song book (Songs of Zion, Hymns of Faith), then Albums and Saved.
/// Search covers every book by number, title, lyricist or a line of the lyrics.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _search = TextEditingController();

  /// Index into [_tabs]: song books first, then Albums, then Saved.
  int? _tab;
  late Future<_Library> _library;

  @override
  void initState() {
    super.initState();
    _library = _load();
  }

  Future<_Library> _load() async {
    final repo = AppScope.read(context).repo;
    final albums = await repo.albums();
    final books = albums.where((a) => a.isSongBook).toList();
    final songsByBook = <int, List<Song>>{};
    for (final b in books) {
      songsByBook[b.id] = await repo.songsForAlbum(b.id);
    }
    final trending = await repo.trendingSongs();
    return _Library(albums: albums, books: books, songsByBook: songsByBook, trending: trending);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _initialTab(_Library lib) {
    final wanted = LaunchOptions.book;
    if (wanted == null) return 0;
    final i = lib.books.indexWhere((b) => b.title.toLowerCase().contains(wanted));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_Library>(
        future: _library,
        builder: (context, snap) {
          final lib = snap.data;
          final query = _search.text.trim();
          final tabs = lib == null ? const <String>[] : [for (final b in lib.books) b.title, 'Albums', 'Saved'];
          final tab = lib == null ? 0 : (_tab ?? _initialTab(lib)).clamp(0, tabs.length - 1);
          final book = lib != null && tab < lib.books.length ? lib.books[tab] : null;
          return CustomScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(children: [
                ScreenTitle(
                  'Songs',
                  trailing: TextButton(
                    onPressed: lib == null ? null : () => _goToNumber(lib, book ?? lib.books.firstOrNull),
                    child: const Text('Go to number'),
                  ),
                ),
                const SizedBox(height: 16),
                _SearchField(controller: _search, onChanged: () => setState(() {})),
                if (query.isEmpty && tabs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  UnderlineTabs(labels: tabs, selected: tab, gap: 16, onSelected: (i) => setState(() { _tab = i); }),
                ],
              ]),
            ),
            if (lib == null)
              SliverToBoxAdapter(
                child: snap.hasError
                    ? BethelEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Couldn’t load songs',
                        message: 'Check your connection and try again',
                        action: OutlinedButton(
                            onPressed: () => setState(() { _library = _load(); }), child: const Text('Try again')),
                      )
                    : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              )
            else if (query.isNotEmpty)
              ..._searchResults(lib, query)
            else if (book != null)
              ..._bookView(lib, book)
            else if (tab == lib.books.length)
              ..._albumsView(lib)
            else
              ..._savedView(lib),
            SliverToBoxAdapter(child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom)),
          ]);
        },
      ),
    );
  }

  // ------------------------------------------------------------------ views

  static bool _matches(Song s, String q) =>
      s.title.toLowerCase().contains(q) ||
      s.altTitle.toLowerCase().contains(q) ||
      s.lyricist.toLowerCase().contains(q) ||
      s.artist.toLowerCase().contains(q);

  List<Widget> _searchResults(_Library lib, String query) {
    final q = query.toLowerCase();
    final n = int.tryParse(q);
    final all = lib.allSongs;
    final titles = all.where((s) => n != null ? s.number == n : _matches(s, q)).toList();
    final inLyrics =
        n != null ? <Song>[] : all.where((s) => !titles.contains(s) && s.lyrics.values.any((l) => l.toLowerCase().contains(q))).toList();
    if (titles.isEmpty && inLyrics.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: BethelEmptyState(
            icon: Icons.search_rounded,
            title: 'No songs match “$query”',
            message: 'Try a song number, a shorter word or another spelling',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        sliver: SliverList.list(children: [
          if (titles.isNotEmpty) ...[
            BethelSectionTitle(n != null ? 'Number $n' : 'Titles'),
            for (final s in titles) SongRow(song: s, showBook: true),
          ],
          if (inLyrics.isNotEmpty) ...[
            if (titles.isNotEmpty) const SizedBox(height: 20),
            const BethelSectionTitle('In lyrics'),
            for (final s in inLyrics) SongRow(song: s, showBook: true, lyricMatch: _lyricLine(s, q)),
          ],
        ]),
      ),
    ];
  }

  /// The first lyric line containing the search, shown under the title.
  static String? _lyricLine(Song s, String q) {
    for (final l in s.lyrics.values) {
      for (final line in l.split('\n')) {
        if (line.toLowerCase().contains(q)) return '“${line.trim()}”';
      }
    }
    return null;
  }

  List<Widget> _bookView(_Library lib, Album book) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final songs = lib.songsByBook[book.id] ?? const <Song>[];
    final recent = state.recentSongs.take(6).toList();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            Text('${songs.length} songs', style: t.textTheme.bodySmall),
            if (book.language.isNotEmpty) Text(' · ${book.language}', style: t.textTheme.bodySmall),
          ]),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 20),
            const BethelSectionTitle('Recently viewed'),
            const SizedBox(height: 16),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) => _RecentSong(song: recent[i]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ]),
      ),
      if (songs.isEmpty)
        const SliverToBoxAdapter(
          child: BethelEmptyState(
            icon: Icons.library_music_outlined,
            title: 'No songs in this book yet',
            message: 'Songs appear here once the church adds them',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(itemCount: songs.length, itemBuilder: (_, i) => SongRow(song: songs[i])),
        ),
    ];
  }

  Future<void> _goToNumber(_Library lib, Album? book) async {
    if (book == null) return;
    final songs = lib.songsByBook[book.id] ?? const <Song>[];
    final song = await showDialog<Song>(context: context, builder: (_) => _GoToNumberDialog(book: book, songs: songs));
    if (song != null && mounted) openSong(context, song);
  }

  List<Widget> _albumsView(_Library lib) {
    final albums = lib.albums.where((a) => !a.isSongBook).toList();
    if (albums.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: BethelEmptyState(icon: Icons.album_outlined, title: 'No albums yet', message: 'Church recordings appear here'),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 16, childAspectRatio: 0.78),
          itemCount: albums.length,
          itemBuilder: (_, i) => _AlbumTile(album: albums[i]),
        ),
      ),
    ];
  }

  List<Widget> _savedView(_Library lib) {
    final state = AppScope.of(context);
    if (state.guest) {
      return [
        SliverToBoxAdapter(
          child: BethelEmptyState(
            icon: Icons.person_outline_rounded,
            title: 'Sign in to save songs',
            message: 'Your saved songs and downloads stay with your account on every device',
            action: FilledButton(onPressed: state.signOut, child: const Text('Sign in')),
          ),
        ),
      ];
    }
    final all = {
      for (final s in [...lib.allSongs, ...lib.trending, ...state.recentSongs]) s.id: s
    };
    final saved = state.savedSongs.map((id) => all[id]).whereType<Song>().toList();
    final downloaded = state.downloadedSongs.map((id) => all[id]).whereType<Song>().toList();
    if (saved.isEmpty && downloaded.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: BethelEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No saved songs yet',
            message: 'Tap the heart on any song to keep it here. Downloads work without internet.',
            action: OutlinedButton(onPressed: () => setState(() { _tab = 0), child: const Text('Browse songs'); }),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        sliver: SliverList.list(children: [
          if (saved.isNotEmpty) ...[
            const BethelSectionTitle('Saved songs'),
            for (final s in saved) SongRow(song: s, showBook: true),
          ],
          if (downloaded.isNotEmpty) ...[
            if (saved.isNotEmpty) const SizedBox(height: 20),
            const BethelSectionTitle('Downloads'),
            for (final s in downloaded)
              SongRow(
                song: s,
                showBook: true,
                trailing: Icon(Icons.download_done_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ]),
      ),
    ];
  }
}

class _Library {
  _Library({required this.albums, required this.books, required this.songsByBook, required this.trending});
  final List<Album> albums;
  final List<Album> books;
  final Map<int, List<Song>> songsByBook;
  final List<Song> trending;
  List<Song> get allSongs => [for (final b in books) ...?songsByBook[b.id]];
}

void openSong(BuildContext context, Song song) {
  AppScope.read(context).openedSong(song);
  Navigator.push(context, MaterialPageRoute(builder: (_) => SongScreen(song: song)));
}

/// True when the text is mostly Telugu script, so it gets the Telugu serif.
bool _isTelugu(String s) => s.runes.any((r) => r >= 0x0C00 && r <= 0x0C7F);

TextStyle? _titleStyle(BuildContext context, String title, {double? size}) {
  final base = Theme.of(context).textTheme.titleSmall;
  if (!_isTelugu(title)) return size == null ? base : base?.copyWith(fontSize: size);
  return base?.copyWith(fontFamily: BethelFonts.telugu, fontWeight: FontWeight.w400, fontSize: size ?? BethelType.lead, height: 1.4);
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: BethelType.body),
      decoration: InputDecoration(
        hintText: 'Search songs',
        hintStyle: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
        fillColor: tk.raised,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: Icon(Icons.close_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.colorScheme.primary, width: 2)),
      ),
    );
  }
}

/// Small card in "Recently viewed": plaque, title, book.
class _RecentSong extends StatelessWidget {
  const _RecentSong({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final title = song.altTitle.isNotEmpty && _isTelugu(song.altTitle) ? song.altTitle : song.title;
    return Pressable(
      onTap: () => openSong(context, song),
      semanticLabel: song.label,
      child: SizedBox(
        width: 104,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          song.number > 0 ? HymnPlaque('${song.number}') : BethelImage(song.image, width: 44, height: 44, radius: 8),
          const SizedBox(height: 8),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: _titleStyle(context, title)),
          if ((song.albumTitle ?? '').isNotEmpty)
            Text(song.albumTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final sub = [if (album.songCount > 0) '${album.songCount} songs', if (album.language.isNotEmpty) album.language].join(' · ');
    return Pressable(
      semanticLabel: album.title,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumScreen(album: album))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: BethelImage(album.image, radius: 12)),
        const SizedBox(height: 8),
        Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
        Text(sub.isNotEmpty ? sub : album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
      ]),
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

class _GoToNumberDialog extends StatefulWidget {
  const _GoToNumberDialog({required this.book, required this.songs});
  final Album book;
  final List<Song> songs;

  @override
  State<_GoToNumberDialog> createState() => _GoToNumberDialogState();
}

class _GoToNumberDialogState extends State<_GoToNumberDialog> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    final n = int.tryParse(_ctrl.text.trim());
    final match = n == null ? null : widget.songs.where((s) => s.number == n).firstOrNull;
    if (match != null) {
      Navigator.pop(context, match);
      return;
    }
    final numbers = widget.songs.map((s) => s.number).where((x) => x > 0);
    // Keep the keyboard up with the wrong number selected, so typing replaces it.
    _focus.requestFocus();
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    setState(() => _error = numbers.isEmpty
        ? 'This book has no numbered songs'
        : '${widget.book.title} has songs ${numbers.reduce((a, b) => a < b ? a : b)} to ${numbers.reduce((a, b) => a > b ? a : b)}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to song number'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.book.title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        TileField(
          controller: _ctrl,
          label: 'Song number',
          hint: 'Number',
          keyboardType: TextInputType.number,
          autofocus: true,
          focusNode: _focus,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() { _error = null; });
          },
          onSubmitted: (_) => _open(),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _open, child: const Text('Open')),
      ],
    );
  }
}

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<List<Song>>(
        load: () => state.repo.songsForAlbum(album.id),
        builder: (context, songs) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            BethelImage(album.image, width: 132, height: 132, radius: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Album', style: t.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(album.title, style: t.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text([
                  '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                  if (album.language.isNotEmpty) album.language,
                ].join(' · '), style: t.textTheme.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          if (songs.isEmpty)
            const BethelEmptyState(icon: Icons.album_outlined, title: 'No songs yet', message: 'This album has no songs yet')
          else
            for (final s in songs) SongRow(song: s),
        ]),
      ),
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
                onSelected: (i) => setState(() { _lang = langs[i]),
              ),
            ],
            const SizedBox(height: 24),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(); }))
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
  const PresentLoader({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D0C),
      body: AsyncView<Song>(
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
  const PresentScreen({super.key, required this.song, required this.language});
  final Song song;
  final String language;

  @override
  State<PresentScreen> createState() => _PresentScreenState();
}

class _PresentScreenState extends State<PresentScreen> {
  final _pages = PageController();
  int _page = 0;

  late final List<String> _stanzas = (widget.song.lyrics[widget.language] ?? '')
      .split(RegExp(r'\n\s*\n'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

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
    final telugu = widget.language == 'Telugu';
    const bg = Color(0xFF0B0D0C);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text('${widget.song.title} · Verse ${_page + 1} of ${_stanzas.length}',
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
                onPageChanged: (i) => setState(() { _page = i),
                itemBuilder: (_, i) => Center(
                  child: SingleChildScrollView(
                    child: Text(_stanzas[i],
                        style: TextStyle(
                          fontFamily: telugu ? BethelFonts.telugu : BethelFonts.display,
                          fontSize: telugu ? 28 : BethelType.display,
                          height: telugu ? 1.6 : 1.35,
                          color: BethelColors.ivory,
                        ); }),
                  ),
                ),
              ),
            ),
            Row(children: [
              _RoundButton(icon: Icons.chevron_left_rounded, label: 'Previous verse', onTap: _page > 0 ? () => _go(-1) : null, filled: false),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < _stanzas.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _page ? BethelColors.brass : const Color(0x4DFFFFFF),
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
