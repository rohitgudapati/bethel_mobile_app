import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

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
                  height: 220,
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
              label: const Text('Open our YouTube channel'),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader('Sermons')),
        AsyncView<List<Sermon>>(
          sliver: true,
          load: state.repo.sermons,
          builder: (context, sermons) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: sermons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => SermonTile(sermon: sermons[i]),
            ),
          ),
        ),
      ]),
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
                Text(sermon.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5)),
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
  final List<String> _notes = [];

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
        if (s.series != null) Pill(s.series!),
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
        const SizedBox(height: 4),
        Text('Take notes while you watch.',
            style: TextStyle(fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final n in _notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Icon(Icons.circle, size: 7, color: BethelColors.gold),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(n, style: const TextStyle(height: 1.5))),
            ]),
          ),
        TextField(
          controller: _note,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write a note…',
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
      ]),
    );
  }
}
