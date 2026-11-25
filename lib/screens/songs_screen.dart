import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// Songs tab: numbered song books (Songs of Zion, hymns), albums and saved songs.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

enum _View { book, albums, saved }

class _SongsScreenState extends State<SongsScreen> {
  final _search = TextEditingController();
  _View _view = _View.book;
  int? _bookId;
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_Library>(
        future: _library,
        builder: (context, snap) {
          final lib = snap.data;
          final query = _search.text.trim();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('Songs', style: t.textTheme.headlineMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search a song by number, title or lyricist',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
            ),
            if (lib == null)
              SliverToBoxAdapter(
                child: snap.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Couldn\'t load songs. ${snap.error}', textAlign: TextAlign.center),
                      )
                    : const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              )
            else if (query.isNotEmpty)
              ..._searchResults(lib, query)
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: SegmentedButton<_View>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _View.book, label: Text('Song book')),
                      ButtonSegment(value: _View.albums, label: Text('Albums')),
                      ButtonSegment(value: _View.saved, label: Text('Saved')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (v) => setState(() => _view = v.first),
                  ),
                ),
              ),
              ...switch (_view) {
                _View.book => _bookView(lib),
                _View.albums => _albumsView(lib),
                _View.saved => _savedView(lib),
              },
            ],
          ]);
        },
      ),
    );
  }

  // ------------------------------------------------------------------ views

  List<Widget> _searchResults(_Library lib, String query) {
    final q = query.toLowerCase();
    final n = int.tryParse(q);
    final results = lib.allSongs.where((s) {
      if (n != null) return s.number == n;
      return s.title.toLowerCase().contains(q) ||
          s.lyricist.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.lyrics.values.any((l) => l.toLowerCase().contains(q));
    }).toList();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(results.isEmpty ? 'No songs match "$query".' : '${results.length} songs',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        sliver: SliverList.builder(
          itemCount: results.length,
          itemBuilder: (_, i) => SongRow(song: results[i], showBook: true),
        ),
      ),
    ];
  }

  List<Widget> _bookView(_Library lib) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    if (lib.books.isEmpty) {
      return [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Text('No song books yet.')))];
    }
    final book = lib.books.firstWhere((b) => b.id == _bookId, orElse: () => lib.books.first);
    final songs = lib.songsByBook[book.id] ?? const <Song>[];
    return [
      // Song book picker
      SliverToBoxAdapter(
        child: SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            scrollDirection: Axis.horizontal,
            itemCount: lib.books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final b = lib.books[i];
              final selected = b.id == book.id;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _bookId = b.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 210,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? BethelColors.navy : t.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? BethelColors.navy : t.colorScheme.outlineVariant),
                  ),
                  child: Row(children: [
                    BethelImage(b.image, width: 56, height: 56, radius: 12),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : null)),
                            Text(
                                '${(lib.songsByBook[b.id] ?? const []).length} songs${b.language.isEmpty ? '' : ' · ${b.language}'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: selected ? const Color(0xCCFFFFFF) : t.colorScheme.onSurfaceVariant)),
                          ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 12, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title, style: t.textTheme.titleLarge),
            Text('${songs.length} songs', style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _HeaderAction(icon: Icons.tag_rounded, label: 'Go to number', onTap: () => _goToNumber(songs)),
              _HeaderAction(
                icon: Icons.bookmark_rounded,
                label: state.savedSongs.isEmpty ? 'Saved' : 'Saved ${state.savedSongs.length}',
                onTap: () => setState(() => _view = _View.saved),
              ),
              _HeaderAction(
                icon: Icons.download_rounded,
                label: 'Downloads',
                onTap: () => setState(() => _view = _View.saved),
              ),
              _HeaderAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => showToast(context, 'Share link to "${book.title}" copied.'),
              ),
            ]),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        sliver: SliverList.builder(itemCount: songs.length, itemBuilder: (_, i) => SongRow(song: songs[i])),
      ),
      if (state.recentSongs.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Recently viewed')),
        SliverToBoxAdapter(child: _SongStrip(songs: state.recentSongs)),
      ],
      if (lib.trending.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionHeader('Trending')),
        SliverToBoxAdapter(child: _SongStrip(songs: lib.trending)),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }

  Future<void> _goToNumber(List<Song> songs) async {
    final ctrl = TextEditingController();
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to song number'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 12'),
          onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (n == null || !mounted) return;
    final match = songs.where((s) => s.number == n);
    if (match.isEmpty) {
      showToast(context, 'There is no song number $n in this book.');
    } else {
      openSong(context, match.first);
    }
  }

  List<Widget> _albumsView(_Library lib) {
    final albums = lib.albums.where((a) => !a.isSongBook).toList();
    if (albums.isEmpty) {
      return [const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Text('No albums yet.')))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 14, childAspectRatio: 0.78),
          itemCount: albums.length,
          itemBuilder: (_, i) => _AlbumCard(album: albums[i]),
        ),
      ),
    ];
  }

  List<Widget> _savedView(_Library lib) {
    final state = AppScope.of(context);
    final all = {
      for (final s in [...lib.allSongs, ...lib.trending, ...state.recentSongs]) s.id: s
    };
    final saved = state.savedSongs.map((id) => all[id]).whereType<Song>().toList();
    final downloaded = state.downloadedSongs.map((id) => all[id]).whereType<Song>().toList();
    final t = Theme.of(context);
    Widget empty(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(text, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        );
    return [
      const SliverToBoxAdapter(child: SectionHeader('Saved songs')),
      if (saved.isEmpty)
        SliverToBoxAdapter(child: empty('Tap the bookmark on any song to keep it here.'))
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
              itemCount: saved.length, itemBuilder: (_, i) => SongRow(song: saved[i], showBook: true)),
        ),
      const SliverToBoxAdapter(child: SectionHeader('Downloads')),
      if (downloaded.isEmpty)
        SliverToBoxAdapter(child: empty('Download lyrics to read them without internet, for example during a service.'))
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList.builder(
              itemCount: downloaded.length, itemBuilder: (_, i) => SongRow(song: downloaded[i], showBook: true)),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
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

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 21, color: t.colorScheme.primary),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

class _SongStrip extends StatelessWidget {
  const _SongStrip({required this.songs});
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final s = songs[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openSong(context, s),
            child: SizedBox(
              width: 112,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BethelImage(s.image, width: 112, height: 112, radius: 16),
                const SizedBox(height: 6),
                Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(s.lyricist.isNotEmpty ? s.lyricist : s.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumScreen(album: album))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: BethelImage(album.image, radius: 18)),
        const SizedBox(height: 8),
        Text(album.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

/// One song in a list: number badge, title, lyricist and quick actions.
class SongRow extends StatelessWidget {
  const SongRow({super.key, required this.song, this.showBook = false});
  final Song song;
  final bool showBook;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.savedSongs.contains(song.id);
    final downloaded = state.downloadedSongs.contains(song.id);
    final t = Theme.of(context);
    final sub = [
      if (song.lyricist.isNotEmpty) song.lyricist else if (song.artist.isNotEmpty) song.artist,
      if (showBook && song.albumTitle != null && song.albumTitle!.isNotEmpty) song.albumTitle!,
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onTap: () => openSong(context, song),
      leading: song.number > 0
          ? Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.brightness == Brightness.dark ? t.colorScheme.surfaceContainer : BethelColors.goldSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('${song.number}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: t.colorScheme.onSurface)),
            )
          : BethelImage(song.image, width: 46, height: 46, radius: 12),
      title: Text(song.title,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        if (downloaded) ...[
          Icon(Icons.download_done_rounded, size: 14, color: t.colorScheme.primary),
          const SizedBox(width: 4),
        ],
        Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: saved ? 'Saved' : 'Save',
          onPressed: () => state.toggleSavedSong(song.id),
          icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: saved ? BethelColors.gold : null),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) {
            switch (v) {
              case 'lyrics':
                openSong(context, song);
              case 'present':
                AppScope.read(context).openedSong(song);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PresentLoader(song: song)));
              case 'download':
                state.toggleDownload(song.id);
                showToast(context, downloaded ? 'Removed from downloads.' : 'Lyrics saved for offline use.');
              case 'share':
                showToast(context, 'Link to "${song.label}" copied.');
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'lyrics', child: ListTile(leading: Icon(Icons.lyrics_outlined), title: Text('Lyrics'))),
            const PopupMenuItem(
                value: 'present', child: ListTile(leading: Icon(Icons.slideshow_rounded), title: Text('Present'))),
            PopupMenuItem(
                value: 'download',
                child: ListTile(
                    leading: Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded),
                    title: Text(downloaded ? 'Downloaded' : 'Download'))),
            const PopupMenuItem(
                value: 'share', child: ListTile(leading: Icon(Icons.ios_share_rounded), title: Text('Share'))),
          ],
        ),
      ]),
    );
  }
}

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});
  final Album album;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          foregroundColor: Colors.white,
          backgroundColor: BethelColors.navyDeep,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(album.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            background: Stack(fit: StackFit.expand, children: [
              BethelImage(album.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC0F1520)],
                  ),
                ),
              ),
            ]),
          ),
        ),
        AsyncView<List<Song>>(
          sliver: true,
          load: () => state.repo.songsForAlbum(album.id),
          builder: (context, songs) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            sliver: SliverList.builder(itemCount: songs.length, itemBuilder: (_, i) => SongRow(song: songs[i])),
          ),
        ),
      ]),
    );
  }
}

/// Song page: lyrics in each language, lyricist, chords, save/download/share, present.
class SongScreen extends StatefulWidget {
  const SongScreen({super.key, required this.song});
  final Song song;

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late final Future<Song> _detail = AppScope.read(context).repo.songDetail(widget.song);
  String? _lang;
  bool _chords = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.albumTitle ?? 'Song', style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            onPressed: () => state.setLyricsScale(state.lyricsScale - 0.1),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'Larger text',
            onPressed: () => state.setLyricsScale(state.lyricsScale + 0.1),
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Song>(
        future: _detail,
        builder: (context, snap) {
          final song = snap.data ?? widget.song;
          final langs = song.lyrics.keys.toList();
          final lang = _lang != null && langs.contains(_lang) ? _lang! : (langs.isEmpty ? null : langs.first);
          final lyrics = lang == null ? null : song.lyrics[lang];
          final saved = state.savedSongs.contains(song.id);
          final downloaded = state.downloadedSongs.contains(song.id);
          return ListView(padding: const EdgeInsets.fromLTRB(24, 4, 24, 48), children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (song.number > 0)
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: BethelColors.navy, borderRadius: BorderRadius.circular(18)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('NO.',
                        style: TextStyle(
                            color: BethelColors.goldSoft, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    Text('${song.number}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.1)),
                  ]),
                )
              else
                BethelImage(song.image, width: 64, height: 64, radius: 18),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(song.title, style: t.textTheme.titleLarge),
                  if (song.lyricist.isNotEmpty)
                    Text('Lyricist: ${song.lyricist}', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                  if (song.artist.isNotEmpty && song.artist != 'Traditional')
                    Text('Sung by: ${song.artist}', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            // Save · Download · Share · Present (original app had Saved / Downloads / Share)
            Row(children: [
              _SongAction(
                icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: saved ? 'Saved' : 'Save',
                active: saved,
                onTap: () => state.toggleSavedSong(song.id),
              ),
              _SongAction(
                icon: downloaded ? Icons.download_done_rounded : Icons.download_rounded,
                label: downloaded ? 'Downloaded' : 'Download',
                active: downloaded,
                onTap: () {
                  state.toggleDownload(song.id);
                  showToast(context, downloaded ? 'Removed from downloads.' : 'Lyrics saved for offline use.');
                },
              ),
              _SongAction(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: () => showToast(context, 'Link to "${song.label}" copied.'),
              ),
              _SongAction(
                icon: Icons.slideshow_rounded,
                label: 'Present',
                onTap: lyrics == null
                    ? null
                    : () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => PresentScreen(song: song, language: lang!))),
              ),
            ]),
            const SizedBox(height: 10),
            if (langs.length > 1 || song.chords != null)
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (langs.length > 1) ...[
                  Icon(Icons.language_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
                  for (final l in langs)
                    ChoiceChip(
                      label: Text(l),
                      selected: l == lang,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _lang = l),
                    ),
                ],
                if (song.chords != null)
                  FilterChip(
                    avatar: const Icon(Icons.piano_rounded, size: 18),
                    label: Text(song.chordKey == null ? 'Chords' : 'Chords · ${song.chordKey}'),
                    selected: _chords,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _chords = v),
                  ),
              ]),
            if (_chords && song.chords != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(song.chords!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 14, height: 1.7, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 18),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (lyrics == null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.lyrics_outlined, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lyrics for this song come from the church\'s song database. '
                      'They appear here once the app is connected to the API.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ]),
              )
            else
              _Lyrics(text: lyrics, scale: state.lyricsScale),
          ]);
        },
      ),
      bottomNavigationBar: _PlayerBar(song: widget.song),
    );
  }
}

class _SongAction extends StatelessWidget {
  const _SongAction({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = onTap == null ? t.disabledColor : (active ? BethelColors.gold : t.colorScheme.primary);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: onTap == null ? t.disabledColor : null)),
          ]),
        ),
      ),
    );
  }
}

class _Lyrics extends StatelessWidget {
  const _Lyrics({required this.text, required this.scale});
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final stanzas = text.split(RegExp(r'\n\s*\n'));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < stanzas.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 26,
              child: Padding(
                padding: EdgeInsets.only(top: 4 * scale),
                child: Text('${i + 1}',
                    style: const TextStyle(color: BethelColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            Expanded(child: Text(stanzas[i].trim(), style: TextStyle(fontSize: 18 * scale, height: 1.7))),
          ]),
        ),
    ]);
  }
}

/// Bottom audio bar. Plays the song's recording when the API provides one.
class _PlayerBar extends StatefulWidget {
  const _PlayerBar({required this.song});
  final Song song;

  @override
  State<_PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<_PlayerBar> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final hasAudio = widget.song.audioUrl != null && widget.song.audioUrl!.isNotEmpty;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        decoration: BoxDecoration(
          color: t.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.colorScheme.outlineVariant),
        ),
        child: Row(children: [
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: BethelColors.navy, foregroundColor: Colors.white),
            onPressed: hasAudio
                ? () => openLink(context, widget.song.audioUrl!)
                : () => showToast(context, 'No recording has been uploaded for this song yet.'),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.song.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(hasAudio ? 'Play recording' : 'Recording not available yet',
                  style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Loads full lyrics, then opens presentation mode.
class PresentLoader extends StatelessWidget {
  const PresentLoader({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BethelColors.navyDeep,
      body: AsyncView<Song>(
        load: () => AppScope.read(context).repo.songDetail(song),
        builder: (context, full) => full.lyrics.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Lyrics for this song aren\'t available yet.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
                  ]),
                ),
              )
            : PresentScreen(song: full, language: full.lyrics.keys.first),
      ),
    );
  }
}

/// Full-screen lyrics, one stanza per page, for projecting during worship.
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
  Timer? _hideTimer;
  bool _chrome = true;

  late final List<String> _stanzas =
      (widget.song.lyrics[widget.language] ?? '').split(RegExp(r'\n\s*\n')).map((s) => s.trim()).toList();

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chrome = false);
    });
  }

  void _go(int delta) {
    final next = (_page + delta).clamp(0, _stanzas.length - 1);
    _pages.animateToPage(next, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BethelColors.navyDeep,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final w = MediaQuery.sizeOf(context).width;
          setState(() => _chrome = true);
          _scheduleHide();
          if (d.localPosition.dx > w * 0.65) _go(1);
          if (d.localPosition.dx < w * 0.35) _go(-1);
        },
        child: SafeArea(
          child: Stack(children: [
            PageView.builder(
              controller: _pages,
              itemCount: _stanzas.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 56),
                      child: Text(_stanzas[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28, height: 1.55, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _chrome ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(widget.song.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                ]),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < _stanzas.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? BethelColors.gold : const Color(0x55FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
