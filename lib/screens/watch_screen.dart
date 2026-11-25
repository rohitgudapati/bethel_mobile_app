import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

enum _Section { sermons, shorts, interviews, testimonies }

/// Watch tab (the original app's "Resources"): live stream, sermons,
/// shorts, interviews and testimonies.
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  _Section _section = _Section.sermons;

  static const _labels = {
    _Section.sermons: 'Sermons',
    _Section.shorts: 'Shorts',
    _Section.interviews: 'Interviews',
    _Section.testimonies: 'Testimonies',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Watch', style: t.textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AsyncView<List<LiveStream>>(
              load: state.repo.liveStreams,
              builder: (context, streams) {
                if (streams.isEmpty) return const SizedBox.shrink();
                final s = streams.first;
                return OverlayCard(
                  image: s.image,
                  height: 200,
                  title: s.title,
                  subtitle: s.description,
                  top: s.isLive ? const LivePill() : const Pill('UPCOMING'),
                  trailing: const PlayBadge(size: 52),
                  onTap: () => openLink(context, s.youtubeUrl),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: OutlinedButton.icon(
              onPressed: () => openLink(context, AppConfig.youtubeChannelUrl),
              icon: const Icon(Icons.smart_display_outlined),
              label: const Text('Past services on YouTube'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              scrollDirection: Axis.horizontal,
              itemCount: _Section.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _Section.values[i];
                return ChoiceChip(
                  label: Text(_labels[s]!),
                  selected: _section == s,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _section = s),
                );
              },
            ),
          ),
        ),
        ...switch (_section) {
          _Section.sermons => [
              AsyncView<List<Sermon>>(
                key: const ValueKey('sermons'),
                sliver: true,
                load: state.repo.sermons,
                builder: (context, sermons) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: sermons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => SermonTile(sermon: sermons[i]),
                  ),
                ),
              ),
            ],
          _Section.shorts => [
              AsyncView<List<MediaItem>>(
                key: const ValueKey('shorts'),
                sliver: true,
                load: state.repo.shorts,
                builder: (context, items) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 9 / 15),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ShortCard(item: items[i]),
                  ),
                ),
              ),
            ],
          _Section.interviews => [_mediaList(state.repo.interviews, 'interviews', 'Interview')],
          _Section.testimonies => [_mediaList(state.repo.testimonies, 'testimonies', 'Testimony')],
        },
      ]),
    );
  }

  Widget _mediaList(Future<List<MediaItem>> Function() load, String key, String kind) => AsyncView<List<MediaItem>>(
        key: ValueKey(key),
        sliver: true,
        load: load,
        builder: (context, items) => SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _MediaCard(item: items[i], kind: kind),
          ),
        ),
      );
}

class _ShortCard extends StatelessWidget {
  const _ShortCard({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) => OverlayCard(
        image: item.image,
        height: double.infinity,
        title: item.title,
        subtitle: item.duration.isEmpty ? null : item.duration,
        top: const Pill('SHORT', icon: Icons.bolt_rounded),
        onTap: () => openLink(context, item.videoUrl ?? AppConfig.youtubeChannelUrl),
      );
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.item, required this.kind});
  final MediaItem item;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openLink(context, item.videoUrl ?? AppConfig.youtubeChannelUrl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
              BethelImage(item.image),
              const Center(child: PlayBadge()),
              if (item.duration.isNotEmpty)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Pill(item.duration, color: const Color(0xCC000000), textColor: Colors.white),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kind.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w700, color: BethelColors.gold, letterSpacing: 0.6)),
              Text(item.title, style: t.textTheme.titleMedium),
              if (item.info.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.info, style: TextStyle(color: t.colorScheme.onSurfaceVariant, height: 1.5)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class SermonTile extends StatelessWidget {
  const SermonTile({super.key, required this.sermon});
  final Sermon sermon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SermonDetailScreen(sermon: sermon))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Stack(alignment: Alignment.center, children: [
              BethelImage(sermon.image, width: 112, height: 76, radius: 12),
              const PlayBadge(size: 30),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sermon.series != null)
                  Text(sermon.series!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w700, color: BethelColors.gold, letterSpacing: 0.5)),
                Text(sermon.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(
                  [sermon.preacher, fmtDate(sermon.date), if (sermon.duration.isNotEmpty) sermon.duration]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class SermonDetailScreen extends StatefulWidget {
  const SermonDetailScreen({super.key, required this.sermon});
  final Sermon sermon;

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  final _note = TextEditingController();
  final _comment = TextEditingController();
  final List<String> _notes = [];
  late Future<List<SermonComment>> _comments = AppScope.read(context).repo.sermonComments(widget.sermon.id);
  bool _posting = false;

  Future<void> _postComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final state = AppScope.read(context);
    if (state.user == null) {
      showToast(context, 'Sign in to leave a comment.');
      return;
    }
    setState(() => _posting = true);
    try {
      await state.repo.addSermonComment(widget.sermon.id, text);
      _comment.clear();
      setState(() => _comments = state.repo.sermonComments(widget.sermon.id));
    } catch (e) {
      if (mounted) showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sermon;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        GestureDetector(
          onTap: () => openLink(context, s.videoUrl ?? AppConfig.youtubeChannelUrl),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: BethelImage(s.image, radius: 18)),
              const PlayBadge(size: 64),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        if (s.series != null) Align(alignment: Alignment.centerLeft, child: Pill(s.series!)),
        const SizedBox(height: 8),
        Text(s.title, style: t.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('${s.preacher} · ${fmtDate(s.date)}', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showToast(context, 'Audio-only playback for listening on the go.'),
              icon: const Icon(Icons.headphones_rounded),
              label: const Text('Listen'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showToast(context, 'Share link copied.'),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share'),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text(s.description, style: const TextStyle(fontSize: 15, height: 1.6)),
        const SizedBox(height: 28),
        Text('My notes', style: t.textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final n in _notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                  padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 7, color: BethelColors.gold)),
              const SizedBox(width: 10),
              Expanded(child: Text(n, style: const TextStyle(height: 1.5))),
            ]),
          ),
        TextField(
          controller: _note,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write a note while you watch…',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                if (_note.text.trim().isEmpty) return;
                setState(() => _notes.add(_note.text.trim()));
                _note.clear();
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Comments', style: t.textTheme.titleMedium),
        const SizedBox(height: 10),
        FutureBuilder<List<SermonComment>>(
          future: _comments,
          builder: (context, snap) {
            final list = snap.data ?? const <SermonComment>[];
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
            }
            if (list.isEmpty) {
              return Text('No comments yet. Be the first to share what spoke to you.',
                  style: TextStyle(color: t.colorScheme.onSurfaceVariant));
            }
            return Column(children: [
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: t.colorScheme.surfaceContainer,
                      child: Text(c.name.isEmpty ? '?' : c.name[0],
                          style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c.name} · ${timeAgo(c.at)}',
                            style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
                        Text(c.text, style: const TextStyle(height: 1.5)),
                      ]),
                    ),
                  ]),
                ),
            ]);
          },
        ),
        TextField(
          controller: _comment,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Leave a comment',
            suffixIcon: IconButton(
              icon: _posting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              onPressed: _posting ? null : _postComment,
            ),
          ),
        ),
      ]),
    );
  }
}
