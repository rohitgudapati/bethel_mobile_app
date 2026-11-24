import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Songs & lyrics', style: t.textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search songs, lyrics or artists',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (q) => showToast(context, 'Search uses the API\'s FuzzySearch endpoint.'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Albums')),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 196,
            child: AsyncView<List<Album>>(
              load: state.repo.albums,
              builder: (context, albums) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: albums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => _AlbumCard(album: albums[i]),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Trending this week')),
        AsyncView<List<Song>>(
          sliver: true,
          load: state.repo.trendingSongs,
          builder: (context, songs) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            sliver: SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (_, i) => SongRow(song: songs[i], rank: i + 1),
            ),
          ),
        ),
      ]),
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
      child: SizedBox(
        width: 140,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BethelImage(album.image, width: 140, height: 140, radius: 18),
          const SizedBox(height: 8),
          Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class SongRow extends StatelessWidget {
  const SongRow({super.key, required this.song, this.rank});
  final Song song;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.savedSongs.contains(song.id);
    final t = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SongScreen(song: song))),
      leading: Row(mainAxisSize: MainAxisSize.min, children: [
        if (rank != null)
          SizedBox(
            width: 24,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: t.colorScheme.onSurfaceVariant)),
          ),
        const SizedBox(width: 6),
        BethelImage(song.image, width: 50, height: 50, radius: 12),
      ]),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        onPressed: () => state.toggleSavedSong(song.id),
        icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? BethelColors.gold : null),
      ),
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

class SongScreen extends StatefulWidget {
  const SongScreen({super.key, required this.song});
  final Song song;

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  double _scale = 1;
  late String _lang = widget.song.lyrics.keys.isEmpty ? '' : widget.song.lyrics.keys.first;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final state = AppScope.of(context);
    final saved = state.savedSongs.contains(song.id);
    final t = Theme.of(context);
    final lyrics = song.lyrics[_lang] ?? 'Lyrics coming soon.';
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.8, 1.6)),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            tooltip: 'Larger text',
            onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.8, 1.6)),
            icon: const Icon(Icons.text_increase_rounded),
          ),
          IconButton(
            onPressed: () => state.toggleSavedSong(song.id),
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? BethelColors.gold : null),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 40), children: [
        Row(children: [
          BethelImage(song.image, width: 84, height: 84, radius: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song.title, style: t.textTheme.titleLarge),
              Text(song.artist, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
              if (song.chordKey != null) ...[
                const SizedBox(height: 6),
                Pill('Key of ${song.chordKey}', icon: Icons.piano_rounded),
              ],
            ]),
          ),
        ]),
        if (song.lyrics.length > 1) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            for (final l in song.lyrics.keys)
              ChoiceChip(
                label: Text(l),
                selected: _lang == l,
                showCheckmark: false,
                onSelected: (_) => setState(() => _lang = l),
              ),
          ]),
        ],
        const SizedBox(height: 24),
        Text(lyrics, style: TextStyle(fontSize: 18 * _scale, height: 1.75)),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => showToast(context, 'Keyboard chords come from GetKeyBoardChordsBySongId.'),
          icon: const Icon(Icons.piano_rounded),
          label: const Text('Show chords'),
        ),
      ]),
    );
  }
}
