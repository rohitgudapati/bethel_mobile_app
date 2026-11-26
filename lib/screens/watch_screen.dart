import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';
import '../notifications/notification_service.dart';
import 'live_banner.dart';
import 'notes_screen.dart';
import 'video_screen.dart';

/// Watch: the church's YouTube channel. Live or latest service on top, the next live
/// stream, then church messages and one shelf per YouTube playlist.
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchData {
  _WatchData(this.streams, this.latest, this.playlists, this.sermons, this.shelves, this.failed);
  final List<LiveStream> streams;
  final ChannelVideo? latest;
  final List<VideoPlaylist> playlists;
  final List<Sermon> sermons;
  final Map<String, List<ChannelVideo>> shelves;
  final bool failed;

  List<ChannelVideo> get allVideos => {
        for (final v in [if (latest != null) latest!, for (final s in shelves.values) ...s]) v.id: v
      }.values.toList();
}

class _WatchScreenState extends State<WatchScreen> {
  late Future<_WatchData> _data = _load();
  bool _reminded = false;

  Future<_WatchData> _load() async {
    final repo = AppScope.read(context).repo;
    var failures = 0;
    Future<T> safe<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        failures++;
        return fallback;
      }
    }

    final streams = safe<List<LiveStream>>(repo.liveStreams, const []);
    final latest = safe<ChannelVideo?>(repo.latestService, null);
    final sermons = safe<List<Sermon>>(repo.sermons, const []);
    final playlists = await safe<List<VideoPlaylist>>(repo.playlists, const []);
    final shelves = <String, List<ChannelVideo>>{};
    await Future.wait([
      for (final p in playlists.take(6))
        safe<List<ChannelVideo>>(() => repo.playlistVideos(p.id, limit: 10), const []).then((v) => shelves[p.id] = v),
    ]);
    return _WatchData(await streams, await latest, playlists, await sermons, shelves, failures >= 3);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() {
      _data = f;
    });
    await f;
  }

  void _play(ChannelVideo v) => playVideo(context,
      youtubeId: v.embeddable ? v.id : null,
      url: 'https://www.youtube.com/watch?v=${v.id}',
      title: v.title,
      subtitle: [if (v.preacher.isNotEmpty) v.preacher, fmtShort(v.published)].join(' · '),
      description: v.description);

  Future<void> _remind(DateTime start, String title) async {
    final state = AppScope.read(context);
    final when = start.subtract(const Duration(minutes: 10));
    await state.notifications.requestPermission();
    await state.notifications.replaceGroup('live', [
      if (when.isAfter(DateTime.now()))
        PlannedNotification(id: 4000, when: when, title: '$title starts in 10 minutes', body: 'Tap to watch live', route: 'watch'),
    ]);
    if (!mounted) return;
    setState(() => _reminded = true);
    showBethelToast(context, 'We’ll remind you 10 minutes before', icon: Icons.notifications_active_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_WatchData>(
        future: _data,
        builder: (context, snap) {
          final d = snap.data;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(padding: const EdgeInsets.fromLTRB(0, 16, 0, 32), children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ScreenTitle(
                  'Watch',
                  trailing: IconButton(
                    tooltip: 'Search videos',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: d == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => _VideoSearchScreen(data: d))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (d == null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [SkeletonBox(height: 200, radius: 16), SizedBox(height: 24), SkeletonBox(height: 120, radius: 12)]),
                )
              else if (d.failed && d.latest == null && d.playlists.isEmpty)
                BethelEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Couldn’t load videos',
                  message: 'Check your connection and try again. Everything is also on our YouTube channel.',
                  action: FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
                )
              else
                ..._content(d, t),
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _content(_WatchData d, ThemeData t) {
    final tk = BethelTokens.of(context);
    final live = d.streams.any((s) => s.isLive);
    final upcoming = d.streams.where((s) => !s.isLive && s.scheduledStart != null).firstOrNull;
    final nextStart = upcoming?.scheduledStart?.toLocal() ?? nextSundayService();
    final nextTitle = upcoming?.title ?? 'Sunday Worship Service';
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (live)
            LiveBanner(streams: d.streams)
          else if (d.latest != null) ...[
            Pressable(
              semanticLabel: 'Latest service: ${d.latest!.title}',
              onTap: () => _play(d.latest!),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  _Thumb(url: d.latest!.thumbnail, duration: d.latest!.duration, radius: 16),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: BethelColors.ivory, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Latest service', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: BethelColors.ink)),
                    ),
                  ),
                  const Positioned.fill(child: Center(child: PlayCircle())),
                ]),
                const SizedBox(height: 12),
                Text('${d.latest!.title} · ${fmtShort(d.latest!.published)}', style: t.textTheme.titleLarge),
                if (d.latest!.preacher.isNotEmpty) Text(d.latest!.preacher, style: t.textTheme.bodySmall),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (!live)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: tk.brassText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Next live: '),
                    TextSpan(text: '${fmtShort(nextStart)} · ${_time(nextStart)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ]), style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurface)),
                ),
                TextButton(
                  onPressed: _reminded ? null : () => _remind(nextStart, nextTitle),
                  child: Text(_reminded ? 'Reminder on' : 'Remind me'),
                ),
              ]),
            ),
          if (d.playlists.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistsScreen(playlists: d.playlists))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Icon(Icons.playlist_play_rounded, color: tk.brassText),
                  const SizedBox(width: 12),
                  Expanded(child: Text('All playlists', style: t.textTheme.titleSmall)),
                  Text('${d.playlists.length} from YouTube', style: t.textTheme.bodySmall),
                  Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
                ]),
              ),
            ),
          ],
        ]),
      ),
      if (d.sermons.isNotEmpty)
        _Shelf(
          title: 'Messages',
          onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _MessagesScreen())),
          children: [
            for (final s in d.sermons.take(10))
              _VideoCard(
                title: s.title,
                thumbnail: s.image,
                duration: s.duration,
                sub: [s.preacher, fmtShort(s.date)].where((x) => x.isNotEmpty).join(' · '),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SermonDetailScreen(sermon: s))),
              ),
          ],
        ),
      for (final p in d.playlists.take(6))
        if ((d.shelves[p.id] ?? const []).isNotEmpty)
          _Shelf(
            title: p.title,
            onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: p))),
            children: [
              for (final v in d.shelves[p.id]!)
                _VideoCard(title: v.title, thumbnail: v.thumbnail, duration: v.duration, sub: fmtShort(v.published), onTap: () => _play(v)),
            ],
          ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openLink(context, AppConfig.youtubeChannelUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            iconAlignment: IconAlignment.end,
            label: const Text('Open our YouTube channel'),
          ),
        ),
      ),
    ];
  }
}

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.duration = '', this.radius = 12, this.width});
  final String url;
  final String duration;
  final double radius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: BethelTokens.of(context).raised, child: BethelImage(url)),
            if (duration.isNotEmpty)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(4)),
                  child: Text(duration, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.children, this.onSeeAll});
  final String title;
  final List<Widget> children;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: BethelSectionTitle(title, action: onSeeAll == null ? null : 'See all', onAction: onSeeAll),
      ),
      SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    ]);
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.title, required this.thumbnail, required this.duration, required this.sub, required this.onTap});
  final String title;
  final String thumbnail;
  final String duration;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Pressable(
      semanticLabel: title,
      onTap: onTap,
      child: SizedBox(
        width: 200,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Thumb(url: thumbnail, duration: duration, width: 200),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.3, fontFamilyFallback: const [BethelFonts.telugu])),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
        ]),
      ),
    );
  }
}

/// Every playlist on the channel, two to a row, with its video count.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key, required this.playlists});
  final List<VideoPlaylist> playlists;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 16, childAspectRatio: 1.15),
          itemCount: playlists.length,
          itemBuilder: (_, i) {
            final p = playlists[i];
            return Pressable(
              semanticLabel: '${p.title}, ${p.count} videos',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: p))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  _Thumb(url: p.thumbnail),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xD1152824),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.playlist_play_rounded, size: 18, color: BethelColors.ivory),
                        Text('${p.count}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: BethelColors.ivory)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
              ]),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Playlists come straight from the church’s YouTube channel. A new playlist there shows up here by itself.', style: t.textTheme.bodySmall),
      ]),
    );
  }
}

/// One playlist: newest or oldest first, or one year.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key, required this.playlist});
  final VideoPlaylist playlist;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late final Future<List<ChannelVideo>> _videos = AppScope.read(context).repo.playlistVideos(widget.playlist.id, limit: 200);
  bool _oldest = false;
  int? _year;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = widget.playlist;
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          tooltip: 'Share playlist',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => SharePlus.instance.share(ShareParams(text: '${p.title}\nhttps://www.youtube.com/playlist?list=${p.id}')),
        ),
      ]),
      body: FutureBuilder<List<ChannelVideo>>(
        future: _videos,
        builder: (context, snap) {
          final all = snap.data ?? const <ChannelVideo>[];
          final years = {for (final v in all) v.published.year}.toList()..sort((a, b) => b.compareTo(a));
          var list = _year == null ? [...all] : all.where((v) => v.published.year == _year).toList();
          list.sort((a, b) => _oldest ? a.published.compareTo(b.published) : b.published.compareTo(a.published));
          return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
            Text('Playlist · ${p.count} videos', style: t.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(p.title, style: t.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(label: const Text('Newest'), selected: !_oldest, showCheckmark: false, onSelected: (_) => setState(() => _oldest = false)),
              ChoiceChip(label: const Text('Oldest'), selected: _oldest, showCheckmark: false, onSelected: (_) => setState(() => _oldest = true)),
              if (years.length > 1)
                for (final y in years)
                  ChoiceChip(label: Text('$y'), selected: _year == y, showCheckmark: false, onSelected: (on) => setState(() => _year = on ? y : null)),
            ]),
            const SizedBox(height: 8),
            if (snap.connectionState != ConnectionState.done)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (snap.hasError)
              const BethelEmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load this playlist', message: 'Check your connection and try again')
            else if (list.isEmpty)
              const BethelEmptyState(icon: Icons.smart_display_outlined, title: 'No videos here yet', message: 'New videos appear after they’re posted on YouTube')
            else
              for (final v in list)
                InkWell(
                  onTap: () => playVideo(context,
                      youtubeId: v.embeddable ? v.id : null,
                      url: 'https://www.youtube.com/watch?v=${v.id}',
                      title: v.title,
                      subtitle: fmtShort(v.published),
                      description: v.description),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      _Thumb(url: v.thumbnail, duration: v.duration, width: 144, radius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.3, fontFamilyFallback: const [BethelFonts.telugu])),
                          const SizedBox(height: 4),
                          Text([fmtShort(v.published), if (v.preacher.isNotEmpty) v.preacher].join(' · '), style: t.textTheme.bodySmall),
                        ]),
                      ),
                    ]),
                  ),
                ),
          ]);
        },
      ),
    );
  }
}

/// All church messages (with notes and comments).
class _MessagesScreen extends StatelessWidget {
  const _MessagesScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: AsyncView<List<Sermon>>(
          load: AppScope.read(context).repo.sermons,
          builder: (context, list) => list.isEmpty
              ? const BethelEmptyState(icon: Icons.smart_display_outlined, title: 'No messages yet', message: 'New messages appear here after they’re posted')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: list.length,
                  itemBuilder: (_, i) => SermonTile(sermon: list[i]),
                ),
        ),
      );
}

class _VideoSearchScreen extends StatefulWidget {
  const _VideoSearchScreen({required this.data});
  final _WatchData data;

  @override
  State<_VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<_VideoSearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final q = _q.trim().toLowerCase();
    final videos = q.isEmpty ? const <ChannelVideo>[] : widget.data.allVideos.where((v) => v.title.toLowerCase().contains(q) || v.preacher.toLowerCase().contains(q)).toList();
    final sermons = q.isEmpty ? const <Sermon>[] : widget.data.sermons.where((s) => s.title.toLowerCase().contains(q) || s.preacher.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(hintText: 'Search videos', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
        ),
      ),
      body: q.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Search by title or speaker', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            )
          : videos.isEmpty && sermons.isEmpty
              ? BethelEmptyState(icon: Icons.search_rounded, title: 'No videos match “$_q”', message: 'Try a shorter word, or look on our YouTube channel')
              : ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
                  for (final s in sermons) SermonTile(sermon: s),
                  for (final v in videos)
                    HairlineRow(
                      leading: _Thumb(url: v.thumbnail, width: 96, radius: 8),
                      title: v.title,
                      subtitle: fmtShort(v.published),
                      onTap: () => playVideo(context, youtubeId: v.embeddable ? v.id : null, url: 'https://www.youtube.com/watch?v=${v.id}', title: v.title),
                    ),
                ]),
    );
  }
}

Widget _playIcon(BuildContext context) => Icon(Icons.play_circle_outline_rounded, size: 24, color: Theme.of(context).colorScheme.primary);

TextStyle? _rowTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: BethelFonts.display, fontWeight: FontWeight.w500);

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.item, required this.kind});
  final MediaItem item;
  final String kind;

  @override
  Widget build(BuildContext context) {
    return HairlineRow(
      title: item.title,
      titleStyle: _rowTitle(context),
      subtitle: [kind, if (item.duration.isNotEmpty) item.duration].join(' · '),
      trailing: _playIcon(context),
      showChevron: false,
      onTap: () => playVideo(context,
          youtubeId: item.youtubeId,
          url: item.videoUrl ?? AppConfig.youtubeChannelUrl,
          title: item.title,
          subtitle: '$kind${item.duration.isEmpty ? '' : ' · ${item.duration}'}',
          description: item.info),
    );
  }
}

/// One sermon in a list: title in the serif, preacher and date, a play mark.
class SermonTile extends StatelessWidget {
  const SermonTile({super.key, required this.sermon});
  final Sermon sermon;

  @override
  Widget build(BuildContext context) {
    final sub = [
      sermon.preacher,
      '${_month(sermon.date)} ${sermon.date.day}',
      if (sermon.duration.isNotEmpty) sermon.duration,
    ].where((s) => s.isNotEmpty).join(' · ');
    return HairlineRow(
      title: sermon.title,
      titleStyle: _rowTitle(context),
      subtitle: sub,
      trailing: _playIcon(context),
      showChevron: false,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SermonDetailScreen(sermon: sermon))),
    );
  }
}

String _month(DateTime d) =>
    const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];

// ===================================================================== message page

class SermonDetailScreen extends StatefulWidget {
  const SermonDetailScreen({super.key, required this.sermon});
  final Sermon sermon;

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  late final _note = TextEditingController(text: AppScope.read(context).noteForSermon(widget.sermon.id)?.body ?? '');
  final _comment = TextEditingController();
  late Future<List<SermonComment>> _comments = AppScope.read(context).repo.sermonComments(widget.sermon.id);

  /// Comments posted on this visit, shown at the top straight away.
  final List<SermonComment> _posted = [];
  bool _posting = false;

  @override
  void dispose() {
    _note.dispose();
    _comment.dispose();
    super.dispose();
  }

  bool get _hasVideo => (widget.sermon.youtubeId ?? '').isNotEmpty;

  Future<void> _play() async {
    final s = widget.sermon;
    if (_hasVideo) {
      playVideo(context, youtubeId: s.youtubeId, title: s.title, subtitle: s.preacher, description: s.description);
      return;
    }
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open in YouTube?'),
        content: const Text('This video plays in the YouTube app'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open')),
        ],
      ),
    );
    if (open == true && mounted) openLink(context, s.videoUrl ?? AppConfig.youtubeChannelUrl);
  }

  Future<void> _share() async {
    final s = widget.sermon;
    final box = context.findRenderObject() as RenderBox?;
    final link = (s.youtubeId ?? '').isNotEmpty ? 'https://youtu.be/${s.youtubeId}' : (s.videoUrl ?? AppConfig.youtubeChannelUrl);
    await SharePlus.instance.share(ShareParams(
      text: '${s.title} · ${s.preacher}\n$link',
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  Future<void> _postComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final state = AppScope.read(context);
    if (state.user == null) {
      showSignInPrompt(context, title: 'Sign in to comment', icon: Icons.chat_bubble_outline_rounded);
      return;
    }
    setState(() => _posting = true);
    try {
      await state.repo.addSermonComment(widget.sermon.id, text);
      _comment.clear();
      FocusScope.of(context).unfocus();
      setState(() => _posted.insert(0, SermonComment(name: state.user!.name, text: text, at: DateTime.now())));
      if (mounted) showBethelToast(context, 'Comment posted', icon: Icons.check_rounded);
    } catch (e) {
      if (mounted) showBethelToast(context, 'Couldn’t post your comment. Try again.', icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sermon;
    final t = Theme.of(context);
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: Column(children: [
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (_hasVideo)
                ClipRRect(borderRadius: BorderRadius.circular(16), child: InlineYouTube(videoId: s.youtubeId!))
              else
                Pressable(
                  onTap: _play,
                  semanticLabel: 'Play ${s.title}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(fit: StackFit.expand, children: [
                        ColoredBox(color: BethelColors.ink, child: BethelImage(s.image)),
                        const Center(child: PlayCircle()),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if ((s.series ?? '').isNotEmpty) ...[
                Text(s.series!, style: t.textTheme.bodySmall?.copyWith(color: BethelTokens.of(context).brassText)),
                const SizedBox(height: 4),
              ],
              Text(s.title, style: t.textTheme.headlineSmall?.copyWith(height: 1.2)),
              const SizedBox(height: 8),
              Text([s.preacher, fmtShort(s.date), if (s.duration.isNotEmpty) s.duration].where((x) => x.isNotEmpty).join(' · '),
                  style: t.textTheme.bodySmall),
              const SizedBox(height: 20),
              Row(children: [
                if (!_hasVideo) ...[
                  Expanded(
                    child: FilledButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Play')),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.ios_share_rounded, size: 18), label: const Text('Share')),
                ),
              ]),
              if (s.description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(s.description.trim(), style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
              ],
              const SizedBox(height: 32),
              const BethelSectionTitle('My notes'),
              const SizedBox(height: 12),
              if (state.user == null)
                HairlineRow(
                  title: 'Sign in to keep notes',
                  subtitle: 'Notes stay with your account',
                  leading: const RowIcon(Icons.edit_note_rounded),
                  onTap: () => showSignInPrompt(context, title: 'Sign in to keep notes', icon: Icons.edit_note_rounded),
                )
              else
                TileField(
                  controller: _note,
                  label: 'My notes',
                  hint: 'Your notes',
                  minLines: 2,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  onChanged: (v) => state.setSermonNote(sermonId: s.id, title: s.title, speaker: s.preacher, date: s.date, body: v),
                ),
              if (state.user != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 44)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
                    child: Text('Saved in Notes with ${s.preacher.isEmpty ? 'the date' : '${s.preacher} and the date'}'),
                  ),
                ),
              const SizedBox(height: 32),
              const BethelSectionTitle('Comments'),
              const SizedBox(height: 4),
              FutureBuilder<List<SermonComment>>(
                future: _comments,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                  }
                  if (snap.hasError && _posted.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(child: Text('Couldn’t load comments', style: t.textTheme.bodyMedium)),
                        TextButton(
                          onPressed: () => setState(() {
                            _comments = state.repo.sermonComments(s.id);
                          }),
                          child: const Text('Try again'),
                        ),
                      ]),
                    );
                  }
                  final list = [..._posted, ...?snap.data];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No comments yet. Share what spoke to you.',
                          style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    );
                  }
                  return Column(children: [for (final c in list) _CommentRow(comment: c)]);
                },
              ),
            ],
          ),
        ),
        _CommentBar(controller: _comment, posting: _posting, onPost: _postComment),
      ]),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});
  final SermonComment comment;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final name = comment.name.trim().isEmpty ? 'Member' : comment.name.trim();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
          child: Text(name.characters.first.toUpperCase(),
              style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: name, style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w500)),
                TextSpan(text: ' · ${timeAgo(comment.at)}'),
              ]),
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(comment.text, style: t.textTheme.bodyMedium?.copyWith(height: 1.45)),
          ]),
        ),
      ]),
    );
  }
}

/// Comment box pinned above the keyboard. "Post" appears once there's something to post.
class _CommentBar extends StatelessWidget {
  const _CommentBar({required this.controller, required this.posting, required this.onPost});
  final TextEditingController controller;
  final bool posting;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: t.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: tk.hairline)),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, v, _) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TileField(
              controller: controller,
              label: 'Leave a comment',
              hint: 'Leave a comment',
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
          ),
          if (v.text.trim().isNotEmpty) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: posting ? null : onPost,
                child: posting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.filledButtonTheme.style?.foregroundColor?.resolve({})))
                    : const Text('Post'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// A full-page list of testimonies, interviews or other videos (opened from More).
class MediaListScreen extends StatelessWidget {
  const MediaListScreen({super.key, required this.title, required this.kind, required this.load});
  final String title;
  final String kind;
  final Future<List<MediaItem>> Function() load;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AsyncView<List<MediaItem>>(
          load: load,
          builder: (context, items) => items.isEmpty
              ? BethelEmptyState(
                  icon: Icons.smart_display_outlined,
                  title: 'Nothing here yet',
                  message: 'New videos appear here after they’re posted',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _MediaRow(item: items[i], kind: kind),
                ),
        ),
      );
}
