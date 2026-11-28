import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../bible/bible_text.dart';
import '../bible/books.dart';
import '../widgets/common.dart';
import '../home/home_sections.dart';
import 'reading_plan_screen.dart';
import 'church_screens.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'shell.dart';
import 'video_screen.dart';

/// Everything Home shows, loaded together so the screen appears in one go.
class _HomeData {
  _HomeData({
    required this.verse,
    required this.events,
    required this.streams,
    required this.sermons,
    required this.plan,
    required this.notifications,
    required this.services,
    required this.albums,
    required this.prayers,
    required this.info,
    required this.offline,
  });

  final DailyVerse? verse;
  final List<ChurchEvent> events;
  final List<LiveStream> streams;
  final List<Sermon> sermons;
  final List<BiblePassage> plan;
  final List<NotificationItem> notifications;
  final List<ChurchService> services;
  final List<Album> albums;
  final List<PrayerRequest> prayers;
  final ChurchInfo? info;

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
      safe<List<ChurchService>>(() => repo.services(), const []),
      safe<List<Album>>(() => repo.albums(), const []),
      safe<List<PrayerRequest>>(() => repo.prayerWall(), const []),
      safe<ChurchInfo?>(() => repo.churchInfo(), null),
    ]);
    return _HomeData(
      verse: results[0] as DailyVerse?,
      events: results[1] as List<ChurchEvent>,
      streams: results[2] as List<LiveStream>,
      sermons: results[3] as List<Sermon>,
      plan: results[4] as List<BiblePassage>,
      notifications: results[5] as List<NotificationItem>,
      services: results[6] as List<ChurchService>,
      albums: results[7] as List<Album>,
      prayers: results[8] as List<PrayerRequest>,
      info: results[9] as ChurchInfo?,
      offline: failures >= 8,
    );
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() { _future = f; });
    await f;
  }

  void _openNotification(String kind) {
    switch (kind) {
      case 'sermon':
        AppShell.goToTab(context, AppShell.watch);
      case 'prayer':
        AppShell.goToTab(context, AppShell.prayer);
      case 'reading':
        _push(const ReadingPlanScreen());
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
                  ..._sections(state, data),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Home, top to bottom: what's next, the verse, your day, this week's services, the daily
  /// question, what's new, the prayer wall, coming events, and how to find the church.
  List<Widget> _sections(AppState state, _HomeData data) {
    const gap = SizedBox(height: 24);
    final live = data.streams.where((s) => s.isLive).firstOrNull;
    final next = nextService(data.services, DateTime.now());
    final newAlbum = data.albums.where((a) => a.isNew && !a.isSongBook).firstOrNull;
    final sermon = data.sermons.firstOrNull;
    return [
      if (live != null) ...[const SizedBox(height: 20), _LiveCard(stream: live)]
      else if (next != null) ...[const SizedBox(height: 20), NextUpCard(service: next.service, when: next.when)],
      if (data.verse != null) ...[const SizedBox(height: 16), VerseCard(verse: data.verse!)],
      const SizedBox(height: 16),
      _StreakCard(onOpenPlan: () => _push(const ReadingPlanScreen())),
      if (data.services.isNotEmpty) ...[gap, ServicesRow(services: data.services)],
      gap,
      const _FactCard(),
      if (sermon != null || newAlbum != null) ...[gap, NewAndLatest(album: newAlbum, sermon: sermon)],
      if (data.prayers.isNotEmpty) ...[gap, PrayerPeek(prayers: data.prayers)],
      ..._comingUp(data.events),
      gap,
      VisitUsCard(info: data.info ?? const ChurchInfo(name: AppConfig.churchName, address: AppConfig.churchAddress, country: 'United States')),
    ];
  }

  List<Widget> _comingUp(List<ChurchEvent> events) {
    final today = _dateOnly(DateTime.now());
    final next = events.where((e) => !_dateOnly(e.date).isBefore(today)).toList()..sort((a, b) => a.date.compareTo(b.date));
    if (next.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      BethelSectionTitle('Coming up', action: 'All events', onAction: () => _push(const EventsScreen())),
      for (final e in next.take(3))
        HairlineRow(
          leading: DatePlaque(e.date),
          title: e.title,
          subtitle: '${e.time} · ${_relativeDay(e.date)}',
          onTap: () => _push(EventDetailScreen(event: e)),
        ),
    ];
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
/// Verse of the day on Forest. English first; swipe (or tap తెలుగు) for Telugu.
/// Text comes from the church's verse when it has text, otherwise from the bundled KJV and Telugu Bibles.
class VerseCard extends StatefulWidget {
  const VerseCard({super.key, required this.verse});
  final DailyVerse verse;

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> {
  bool _te = false;
  bool _forward = true;
  late Future<(String?, String?)> _texts = _load();

  @override
  void didUpdateWidget(VerseCard old) {
    super.didUpdateWidget(old);
    if (old.verse.id != widget.verse.id || old.verse.reference != widget.verse.reference) _texts = _load();
  }

  Future<(String?, String?)> _load() async {
    final v = widget.verse;
    final ref = parseBibleRef(v.reference);
    String? en = (v.text?.trim().isNotEmpty ?? false) ? v.text!.trim() : null;
    String? te;
    if (ref != null) {
      try {
        en ??= await biblePassage(BibleVersion.kjv, ref);
        te = await biblePassage(BibleVersion.te, ref);
      } catch (_) {}
    }
    return (en, te);
  }

  void _show(bool te) {
    if (te == _te) return;
    setState(() {
      _forward = te;
      _te = te;
    });
  }

  String _teRef(BibleRef r) => '${bibleBooks[r.book].teName} ${r.chapter}:${r.from}${r.to > r.from ? '–${r.to}' : ''}';

  @override
  Widget build(BuildContext context) {
    final verse = widget.verse;
    final ref = verse.reference ?? '';
    final parsed = parseBibleRef(ref);
    return FutureBuilder<(String?, String?)>(
      future: _texts,
      builder: (context, snap) {
        final en = snap.data?.$1 ?? ((verse.text?.trim().isNotEmpty ?? false) ? verse.text!.trim() : null);
        final te = snap.data?.$2;
        final hasTe = te != null;
        final showTe = _te && hasTe;
        final text = showTe ? te : en;
        Widget lang(String label, bool isTe) => Semantics(
              button: true,
              selected: showTe == isTe,
              child: InkWell(
                onTap: () => _show(isTe),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: BethelType.caption,
                        fontWeight: FontWeight.w500,
                        fontFamilyFallback: const [BethelFonts.telugu],
                        color: showTe == isTe ? BethelColors.ivory : BethelColors.ivory.withValues(alpha: 0.55),
                      )),
                ),
              ),
            );
        return Pressable(
          semanticLabel: 'Verse of the day. Opens past verses.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseArchiveScreen())),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 20),
            decoration: BoxDecoration(color: BethelColors.forest, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Text('Verse of the day', style: TextStyle(fontSize: BethelType.caption, color: BethelColors.brassLight)),
                ),
                if (hasTe) ...[lang('English', false), lang('తెలుగు', true)],
                IconButton(
                  tooltip: 'Share verse',
                  onPressed: () => shareVerse(context, verse, text: text, reference: showTe && parsed != null ? _teRef(parsed) : null),
                  icon: const Icon(Icons.ios_share_rounded, size: 20, color: BethelColors.brassLight),
                ),
              ]),
              if (text == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 16),
                  child: BethelImage(verse.image ?? '', height: 180, radius: 12),
                )
              else
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: hasTe
                      ? (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v.abs() > 150) _show(!_te);
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedSwitcher(
                      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
                      transitionBuilder: (child, a) {
                        final incoming = child.key == ValueKey(showTe);
                        final from = Offset((incoming == _forward) ? 0.15 : -0.15, 0);
                        return FadeTransition(
                          opacity: a,
                          child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(a), child: child),
                        );
                      },
                      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
                      child: Column(
                        key: ValueKey(showTe),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('“$text”',
                              style: showTe
                                  ? const TextStyle(fontFamily: BethelFonts.telugu, fontSize: 18, height: 1.75, color: BethelColors.ivory)
                                  : const TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.title, height: 1.45, color: BethelColors.ivory)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      showTe && parsed != null ? '${_teRef(parsed)} · తెలుగు' : (ref.isEmpty ? 'KJV' : '$ref · KJV'),
                      style: const TextStyle(fontSize: BethelType.caption, color: BethelColors.stone, fontFamilyFallback: [BethelFonts.telugu]),
                    ),
                  ),
                  if (hasTe)
                    ExcludeSemantics(
                      child: Row(children: [
                        for (final on in [!showTe, showTe])
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 6),
                            width: on ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: on ? BethelColors.brassLight : BethelColors.brassLight.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// Streak and today's reading, or an invitation to start a plan.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.onOpenPlan});
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final plan = state.plan;
    final now = DateTime.now();
    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
      child: Icon(Icons.local_fire_department_outlined, color: tk.brassText),
    );
    BoxDecoration card() => BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline));
    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: card(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Read the whole Bible', style: t.textTheme.titleLarge),
                Text('In 1, 3 or 6 months, or a year. We’ll keep your streak.', style: t.textTheme.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: onOpenPlan, child: const Text('Start a plan'))),
        ]),
      );
    }
    final day = plan.dayFor(now);
    final active = day >= 1 && day <= plan.days;
    final readings = plan.readingsFor(day);
    final complete = active && state.planProgress.dayComplete(plan, day);
    final streak = state.planProgress.streak(now);
    final sub = !active
        ? (day < 1 ? 'Your plan starts ${longDate(plan.start)}' : 'You finished your plan')
        : 'Day $day of ${plan.days} · ${readings.length == 1 ? readings.first.label : '${readings.first.label} and ${readings.length - 1} more'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(streak == 0 ? 'Start a streak today' : '$streak-day streak', style: t.textTheme.titleLarge),
              Text(sub, style: t.textTheme.bodySmall),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        PlanWeekStrip(progress: state.planProgress, now: now),
        const SizedBox(height: 12),
        Row(children: [
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 44)),
            onPressed: onOpenPlan,
            child: const Text('Today’s reading'),
          ),
          const Spacer(),
          if (complete)
            Row(children: [
              Icon(Icons.check_rounded, size: 18, color: t.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Read today', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
            ])
          else if (active)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 16)),
              onPressed: () {
                final m = state.markDay(day);
                if (m != null) showBethelToast(context, m.title, icon: Icons.local_fire_department_rounded);
              },
              child: const Text('Mark as read'),
            ),
        ]),
      ]),
    );
  }
}

/// "Did you know?": a one-tap Bible question, then the fact and the recent score.
class _FactCard extends StatelessWidget {
  const _FactCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final f = state.fact;
    final choice = state.factChoice;
    final recent = state.factHistory.length > 5 ? state.factHistory.sublist(state.factHistory.length - 5) : state.factHistory;
    final right = recent.where((r) => r).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_outlined, size: 16, color: tk.brassText),
          const SizedBox(width: 8),
          Text('Did you know?', style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
        ]),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
          child: choice == null
              ? Column(key: ValueKey('q${state.factIndex}'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.question, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.45)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < f.choices.length; i++)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        onPressed: () => state.answerFact(i),
                        child: Text(f.choices[i]),
                      ),
                  ]),
                ])
              : Column(key: ValueKey('a${state.factIndex}'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(choice == f.answer ? 'Right.' : 'Not quite. It’s ${f.choices[f.answer]}.',
                      style: t.textTheme.labelLarge?.copyWith(color: choice == f.answer ? t.colorScheme.primary : tk.brassText)),
                  const SizedBox(height: 4),
                  Text(f.fact, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.45)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Text(recent.length < 2 ? 'A new one tomorrow' : 'You got $right of the last ${recent.length}',
                          style: t.textTheme.bodySmall),
                    ),
                    TextButton(onPressed: state.nextFact, child: const Text('Next fact')),
                  ]),
                ]),
        ),
      ]),
    );
  }
}

/// Opens the system share sheet with the verse text and reference.
Future<void> shareVerse(BuildContext context, DailyVerse verse, {String? text, String? reference}) async {
  AppScope.read(context).repo.shareVerse(verse.id).ignore();
  final ref = reference ?? verse.reference ?? '';
  final body = text ?? verse.text?.trim();
  final share = (body?.isNotEmpty ?? false)
      ? '“$body”\n$ref${reference == null ? ' (KJV)' : ''}\n\nVerse of the day · Bethel Prayer House'
      : 'Verse of the day $ref · Bethel Prayer House';
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    text: share,
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
