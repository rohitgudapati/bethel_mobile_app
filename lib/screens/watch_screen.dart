import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';
import 'live_banner.dart';
import 'video_screen.dart';

/// Watch tab (the original app's "Resources"): the live or next stream, then sermons,
/// shorts, interviews and testimonies under underline tabs.
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  static const _tabs = ['Sermons', 'Shorts', 'Interviews', 'Testimonies'];
  int _tab = 0;

  late Future<List<LiveStream>> _streams;
  final _loads = <int, Future<List<Object>>>{};

  @override
  void initState() {
    super.initState();
    _streams = AppScope.read(context).repo.liveStreams();
  }

  Future<List<Object>> _load(int tab) {
    final repo = AppScope.read(context).repo;
    return _loads[tab] ??= switch (tab) {
      0 => repo.sermons(),
      1 => repo.shorts(),
      2 => repo.interviews(),
      _ => repo.testimonies(),
    };
  }

  Future<void> _refresh() async {
    final repo = AppScope.read(context).repo;
    setState(() {
      _streams = repo.liveStreams();
      _loads.clear();
    });
    await Future.wait<Object>([_streams, _load(_tab)]).catchError((Object _) => <Object>[]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(children: [
              const ScreenTitle('Watch'),
              const SizedBox(height: 16),
              FutureBuilder<List<LiveStream>>(
                future: _streams,
                // Without stream data the hero still shows the next Sunday service.
                builder: (context, snap) => snap.connectionState == ConnectionState.done
                    ? LiveBanner(streams: snap.data ?? const [])
                    : const SkeletonBox(height: 208, radius: 20),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), minimumSize: const Size(0, 44)),
                  onPressed: () => openLink(context, AppConfig.youtubeChannelUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Past services on YouTube'),
                ),
              ),
              const SizedBox(height: 4),
              UnderlineTabs(labels: _tabs, selected: _tab, onSelected: (i) => setState(() => _tab = i)),
            ]),
          ),
          FutureBuilder<List<Object>>(
            key: ValueKey(_tab),
            future: _load(_tab),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
              }
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: BethelEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Couldn’t load ${_tab == 0 ? 'messages' : _tabs[_tab].toLowerCase()}',
                    message: 'Check your connection and try again. Past services are also on YouTube.',
                    action: FilledButton.icon(
                      onPressed: () => setState(() => _loads.remove(_tab)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                );
              }
              final items = snap.data ?? const <Object>[];
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: BethelEmptyState(
                    icon: Icons.smart_display_outlined,
                    title: _tab == 0 ? 'No messages yet' : 'No ${_tabs[_tab].toLowerCase()} yet',
                    message: 'New videos appear here after they’re posted',
                  ),
                );
              }
              if (_tab == 1) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 9 / 14),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ShortCard(item: items[i] as MediaItem),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => switch (items[i]) {
                    final Sermon s => SermonTile(sermon: s),
                    final MediaItem m => _MediaRow(item: m, kind: _tab == 2 ? 'Interview' : 'Testimony'),
                    _ => const SizedBox.shrink(),
                  },
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

Widget _playIcon(BuildContext context) => Icon(Icons.play_circle_outline_rounded, size: 24, color: Theme.of(context).colorScheme.primary);

TextStyle? _rowTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: BethelFonts.display, fontWeight: FontWeight.w500);

class _ShortCard extends StatelessWidget {
  const _ShortCard({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Short: ${item.title}',
      onTap: () => playVideo(context,
          youtubeId: item.youtubeId, url: item.videoUrl ?? AppConfig.youtubeChannelUrl, title: item.title, vertical: true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(fit: StackFit.expand, children: [
          BethelImage(item.image),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1],
                colors: [Color(0x00000000), Color(0xBF000000)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: BethelColors.ivory, fontSize: BethelType.body, fontWeight: FontWeight.w500, height: 1.3)),
              if (item.duration.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(item.duration, style: const TextStyle(color: BethelColors.stone, fontSize: BethelType.caption)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

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
  late final _note = TextEditingController(text: AppScope.read(context).sermonNotes[widget.sermon.id] ?? '');
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
                  onChanged: (v) => state.setSermonNote(s.id, v),
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
                          onPressed: () => setState(() => _comments = state.repo.sermonComments(s.id)),
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
