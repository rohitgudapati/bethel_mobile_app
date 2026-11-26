import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'bible_screen.dart';
import 'church_screens.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'shell.dart';
import 'video_screen.dart';
import 'watch_screen.dart';

/// Everything Home shows, loaded together so the screen appears in one go.
class _HomeData {
  _HomeData({
    required this.verse,
    required this.events,
    required this.streams,
    required this.sermons,
    required this.plan,
    required this.notifications,
    required this.offline,
  });

  final DailyVerse? verse;
  final List<ChurchEvent> events;
  final List<LiveStream> streams;
  final List<Sermon> sermons;
  final List<BiblePassage> plan;
  final List<NotificationItem> notifications;

  /// Nothing could be loaded: show the offline notice.
  final bool offline;
}

/// Home: greeting, verse of the day, a live card while the service streams, what's coming up,
/// and where to pick up (reading plan, latest message).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future = _load();

  Future<_HomeData> _load() async {
    final repo = AppScope.read(context).repo;
    var failures = 0;
    Future<T> safe<T>(Future<T> Function() load, T fallback) async {
      try {
        return await load();
      } catch (_) {
        failures++;
        return fallback;
      }
    }

    final results = await Future.wait<Object?>([
      safe<DailyVerse?>(() => repo.todayVerse(), null),
      safe<List<ChurchEvent>>(() => repo.events(), const []),
      safe<List<LiveStream>>(() => repo.liveStreams(), const []),
      safe<List<Sermon>>(() => repo.sermons(), const []),
      safe<List<BiblePassage>>(() => repo.readingPlan(), const []),
      safe<List<NotificationItem>>(() => repo.notifications(), const []),
    ]);
    return _HomeData(
      verse: results[0] as DailyVerse?,
      events: results[1] as List<ChurchEvent>,
      streams: results[2] as List<LiveStream>,
      sermons: results[3] as List<Sermon>,
      plan: results[4] as List<BiblePassage>,
      notifications: results[5] as List<NotificationItem>,
      offline: failures >= 5,
    );
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  void _openNotification(String kind) {
    switch (kind) {
      case 'sermon':
        AppShell.goToTab(context, AppShell.watch);
      case 'prayer':
        AppShell.goToTab(context, AppShell.prayer);
      case 'reading':
        _push(const BibleScreen());
      default:
        _push(const EventsScreen());
    }
  }

  void _push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          final unread = data == null ? 0 : data.notifications.where((n) => !state.readNotifications.contains(n.id)).length;
          return RefreshIndicator(
            color: BethelColors.forest,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _Greeting(
                  name: state.guest ? 'friend' : state.greetingName,
                  unread: unread,
                  onBell: () => _push(NotificationsScreen(
                    items: data?.notifications ?? const [],
                    onOpen: _openNotification,
                  )),
                ),
                if (state.guest) ...[const SizedBox(height: 20), _SignInNudge(onTap: state.signOut)],
                if (data == null) ...[
                  const SizedBox(height: 20),
                  const _HomeSkeleton(),
                ] else ...[
                  if (data.offline) ...[const SizedBox(height: 20), _OfflineNotice(onRetry: _refresh)],
                  if (data.streams.any((s) => s.isLive)) ...[
                    const SizedBox(height: 20),
                    _LiveCard(stream: data.streams.firstWhere((s) => s.isLive)),
                  ],
                  if (data.verse != null) ...[const SizedBox(height: 20), VerseCard(verse: data.verse!)],
                  ..._comingUp(data.events),
                  if (!state.guest) ..._keepGoing(state, data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _comingUp(List<ChurchEvent> events) {
    final today = _dateOnly(DateTime.now());
    final next = events.where((e) => !_dateOnly(e.date).isBefore(today)).toList()..sort((a, b) => a.date.compareTo(b.date));
    if (next.isEmpty) return const [];
    return [
      const SizedBox(height: 20),
      BethelSectionTitle('Coming up', action: 'All events', onAction: () => _push(const EventsScreen())),
      for (final e in next.take(2))
        HairlineRow(
          leading: DatePlaque(e.date),
          title: e.title,
          subtitle: '${e.time} · ${_relativeDay(e.date)}',
          onTap: () => _push(EventDetailScreen(event: e)),
        ),
    ];
  }

  List<Widget> _keepGoing(AppState state, _HomeData data) {
    final rows = <Widget>[];
    if (data.plan.isNotEmpty) {
      final i = data.plan.indexWhere((p) => !state.readingDone.contains(p.reference));
      rows.add(HairlineRow(
        leading: const RowIcon(Icons.menu_book_outlined),
        title: i < 0 ? 'Reading plan complete' : 'Reading plan · Day ${i + 1}',
        subtitle: i < 0 ? '${data.plan.length} of ${data.plan.length} days' : '${data.plan[i].reference} · ${data.plan[i].title}',
        onTap: () => _push(const BibleScreen()),
      ));
    }
    if (data.sermons.isNotEmpty) {
      final s = data.sermons.first;
      rows.add(HairlineRow(
        leading: const RowIcon(Icons.play_circle_outline_rounded),
        title: s.title,
        subtitle: 'Latest message · ${s.preacher}',
        onTap: () => _push(SermonDetailScreen(sermon: s)),
      ));
    }
    if (rows.isEmpty) return const [];
    return [const SizedBox(height: 20), const BethelSectionTitle('Keep going'), ...rows];
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _relativeDay(DateTime d) {
  final days = _dateOnly(d).difference(_dateOnly(DateTime.now())).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}

const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Thursday, Nov 26" above "Good afternoon, Samuel", with the notifications bell.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.unread, required this.onBell});

  final String name;
  final int unread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final now = DateTime.now();
    final part = now.hour < 12 ? 'morning' : (now.hour < 17 ? 'afternoon' : 'evening');
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_weekdayNames[now.weekday - 1]}, ${_monthNames[now.month - 1]} ${now.day}', style: t.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Good $part, $name', style: t.textTheme.headlineMedium),
        ]),
      ),
      const SizedBox(width: 12),
      Pressable(
        onTap: onBell,
        semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
          child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.notifications_none_rounded, size: 22, color: t.colorScheme.onSurface),
            if (unread > 0)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: BethelColors.brass,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }
}

class _SignInNudge extends StatelessWidget {
  const _SignInNudge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Sign in to save songs and notes',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const RowIcon(Icons.person_outline_rounded),
          const SizedBox(width: 12),
          const Expanded(child: Text('Sign in to save songs and notes')),
          Text('Sign in', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
        ]),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(border: Border.all(color: tk.hairline), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const RowIcon(Icons.wifi_off_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('You’re offline', style: t.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('Couldn’t reach the church. Downloaded songs still work.', style: t.textTheme.bodySmall),
          ]),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

/// Shown while the service streams: photo, "Live now", Watch live.
class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.stream});
  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Watch ${stream.title} live',
      onTap: () => playVideo(context,
          youtubeId: stream.youtubeId, url: stream.youtubeUrl, title: stream.title, subtitle: stream.description, isLive: true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 196,
          child: Stack(fit: StackFit.expand, children: [
            BethelImage(stream.image.isEmpty ? 'assets/church/worship.jpg' : stream.image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33152824), Color(0xD9152824)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Live now', style: TextStyle(fontSize: BethelType.caption, fontWeight: FontWeight.w500, color: BethelColors.ivory)),
                ]),
                const Spacer(),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(stream.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.title, color: BethelColors.ivory)),
                      if (stream.description.isNotEmpty)
                        Text(stream.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: BethelType.caption, color: BethelColors.stone)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: BethelColors.ivory, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Watch live', style: TextStyle(fontWeight: FontWeight.w500, color: BethelColors.ink)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Verse of the day on Forest. Tap for past verses; the share icon opens the share sheet.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.verse});
  final DailyVerse verse;

  @override
  Widget build(BuildContext context) {
    final hasText = verse.text != null && verse.text!.trim().isNotEmpty;
    final ref = verse.reference ?? '';
    return Pressable(
      semanticLabel: 'Verse of the day. Opens past verses.',
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseArchiveScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 12, 24),
        decoration: BoxDecoration(color: BethelColors.forest, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const BrassRule(),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Verse of the day', style: TextStyle(fontSize: BethelType.caption, color: BethelColors.brassLight)),
            ),
            IconButton(
              tooltip: 'Share verse',
              onPressed: () => shareVerse(context, verse),
              icon: const Icon(Icons.ios_share_rounded, size: 20, color: BethelColors.brassLight),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: hasText
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Text(verse.text!,
                        style: const TextStyle(
                            fontFamily: BethelFonts.display, fontSize: BethelType.title, height: 1.45, color: BethelColors.ivory)),
                    const SizedBox(height: 12),
                    Text(ref.isEmpty ? 'KJV' : '$ref · KJV',
                        style: const TextStyle(fontSize: BethelType.caption, color: BethelColors.stone)),
                  ])
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: BethelImage(verse.image ?? '', height: 180, radius: 12),
                  ),
          ),
        ]),
      ),
    );
  }
}

/// Opens the system share sheet with the verse text and reference.
Future<void> shareVerse(BuildContext context, DailyVerse verse) async {
  AppScope.read(context).repo.shareVerse(verse.id).ignore();
  final ref = verse.reference ?? '';
  final text = (verse.text?.trim().isNotEmpty ?? false)
      ? '“${verse.text!.trim()}”\n$ref (KJV)\n\nVerse of the day · Bethel Prayer House'
      : 'Verse of the day $ref · Bethel Prayer House';
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    text: text,
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row(double lead) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            SkeletonBox(width: lead, height: lead == 24 ? 24 : 48),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FractionallySizedBox(widthFactor: 0.7, child: SkeletonBox(height: 14)),
                SizedBox(height: 8),
                FractionallySizedBox(widthFactor: 0.45, child: SkeletonBox(height: 12)),
              ]),
            ),
          ]),
        );
    return Semantics(
      label: 'Loading',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SkeletonBox(height: 188, radius: 20),
        const SizedBox(height: 24),
        const SkeletonBox(width: 140, height: 20),
        row(44),
        row(44),
        const SizedBox(height: 20),
        const SkeletonBox(width: 120, height: 20),
        row(24),
        row(24),
      ]),
    );
  }
}
