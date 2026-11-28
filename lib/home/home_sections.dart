import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/clock.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../notifications/notification_service.dart';
import '../screens/church_screens.dart';
import '../screens/events_screen.dart';
import '../screens/shell.dart';
import '../widgets/common.dart';
import 'schedule.dart';

/// The next service with a known day, from the services' written schedules.
({ChurchService service, Occurrence when})? nextService(List<ChurchService> services, DateTime now) {
  ({ChurchService service, Occurrence when})? best;
  for (final s in services) {
    final o = nextOccurrence(s.schedule, now);
    if (o == null) continue;
    if (best == null || o.start.isBefore(best.when.start)) best = (service: s, when: o);
  }
  return best;
}

/// "Next up": the next service with a live countdown and Remind me.
class NextUpCard extends StatefulWidget {
  const NextUpCard({super.key, required this.service, required this.when});
  final ChurchService service;
  final Occurrence when;

  @override
  State<NextUpCard> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<NextUpCard> {
  Timer? _tick;
  bool _reminded = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _remind() async {
    final state = AppScope.read(context);
    final start = widget.when.start;
    final when = widget.when.hasTime ? start.subtract(const Duration(minutes: 30)) : DateTime(start.year, start.month, start.day, 9);
    if (!when.isAfter(appNow())) {
      // Starting within half an hour: remind at the start instead.
      await state.notifications.requestPermission();
      await state.notifications.replaceGroup('nextup', [
        if (start.isAfter(appNow()))
          PlannedNotification(id: 4100, when: start, title: '${widget.service.name} is starting', body: AppConfig.churchName, route: 'home'),
      ]);
      if (!mounted) return;
      setState(() => _reminded = true);
      showBethelToast(context, 'We’ll remind you when it starts', icon: Icons.notifications_active_outlined);
      return;
    }
    await state.notifications.requestPermission();
    await state.notifications.replaceGroup('nextup', [
      if (when.isAfter(DateTime.now()))
        PlannedNotification(
          id: 4100,
          when: when,
          title: widget.when.hasTime ? '${widget.service.name} at ${clockTime(start)}' : '${widget.service.name} today',
          body: AppConfig.churchName,
          route: 'home',
        ),
    ]);
    if (!mounted) return;
    setState(() => _reminded = true);
    showBethelToast(context, widget.when.hasTime ? 'We’ll remind you 30 minutes before' : 'We’ll remind you that morning',
        icon: Icons.notifications_active_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final now = appNow();
    final w = widget.when;
    final day = dayLabel(w.start, now, hasTime: w.hasTime);
    final happening = w.hasTime && !w.start.isAfter(now);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: BoxDecoration(color: BethelColors.forest, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: const Color(0x26F4EFE6), borderRadius: BorderRadius.circular(12)),
          child: Icon(serviceIcon(widget.service.icon), color: BethelColors.ivory),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(happening ? 'HAPPENING NOW' : (w.hasTime && w.start.difference(now).inMinutes <= 60 ? 'STARTING SOON · ${countdown(w.start, now).toUpperCase()}' : 'NEXT UP · ${day.toUpperCase()}'),
                style: const TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: BethelColors.brassSoft)),
            const SizedBox(height: 2),
            Text(widget.service.name,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, height: 1.25, fontWeight: FontWeight.w600, color: BethelColors.ivory)),
            Text(
              [
                if (w.hasTime) clockTime(w.start),
                if (w.hasTime && !happening && w.start.difference(now).inHours < 24) countdown(w.start, now),
                if (!w.hasTime) widget.service.schedule,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xCCF4EFE6)),
            ),
          ]),
        ),
        if (!happening)
          IconButton(
            tooltip: _reminded ? 'Reminder on' : 'Remind me',
            onPressed: _reminded ? null : _remind,
            icon: Icon(_reminded ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: _reminded ? BethelColors.brassSoft : BethelColors.ivory),
          )
        else
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BethelColors.ivory),
            onPressed: () => AppShell.goToTab(context, AppShell.watch),
            child: const Text('Watch', style: TextStyle(color: BethelColors.ivory)),
          ),
      ]),
    );
  }
}


/// "Today": a special event happening today (e.g. a Special Meetings night).
class EventTodayCard extends StatelessWidget {
  const EventTodayCard({super.key, required this.event});
  final ChurchEvent event;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3B2E18);
    return Pressable(
      semanticLabel: 'Today: ${event.title}',
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: BethelColors.brassSoft, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.event_rounded, size: 16, color: ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text('TODAY · ${event.category.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: ink)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(event.title, style: const TextStyle(fontFamily: BethelFonts.display, fontSize: 22, height: 1.25, color: ink)),
          const SizedBox(height: 4),
          Text([event.time, if (event.venue.isNotEmpty) event.venue, if (event.speakers.isNotEmpty) event.speakers.first].join(' · '),
              style: const TextStyle(fontSize: 14, color: ink)),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: BethelColors.forest, foregroundColor: BethelColors.ivory, minimumSize: const Size(0, 42)),
            onPressed: () => openLink(context, AppConfig.mapsUrl),
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
          ),
        ]),
      ),
    );
  }
}

/// "Missed it? Watch today's service": for 24 hours after a stream ends.
class ReplayCard extends StatelessWidget {
  const ReplayCard({super.key, required this.video, required this.onTap});
  final ChannelVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Pressable(
      semanticLabel: 'Watch today’s service: ${video.title}',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 120,
              height: 68,
              child: Stack(fit: StackFit.expand, children: [
                BethelImage(video.thumbnail),
                const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30)),
                if (video.duration.isNotEmpty)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xA6000000), borderRadius: BorderRadius.circular(4)),
                      child: Text(video.duration, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MISSED IT?', style: t.textTheme.labelSmall?.copyWith(color: tk.brassText, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
              Text('Watch today’s service', style: t.textTheme.titleSmall),
              Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Reading plan: earlier days not finished.
class PlanBehindCard extends StatelessWidget {
  const PlanBehindCard({super.key, required this.days, required this.onOpen});
  final int days;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.brassText, width: 1.5)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: BethelColors.brassSoft, shape: BoxShape.circle),
          child: const Icon(Icons.menu_book_outlined, color: Color(0xFF5A4626)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(days == 1 ? '1 day behind' : '$days days behind', style: t.textTheme.titleLarge),
            Text('Catch up on your reading plan', style: t.textTheme.bodySmall),
          ]),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
          onPressed: onOpen,
          child: const Text('Catch up'),
        ),
      ]),
    );
  }
}

/// One thing on this week's calendar: a service's next time, or an event.
class WeekItem {
  const WeekItem({required this.start, required this.hasTime, required this.title, required this.icon, this.isEvent = false, this.onTap});
  final DateTime start;
  final bool hasTime;
  final String title;
  final IconData icon;
  final bool isEvent;
  final VoidCallback? onTap;
}

/// Services and events in the next 7 days, in time order (services from their written
/// schedules; events not already covered by a service).
List<WeekItem> weekItems(BuildContext context, List<ChurchService> services, List<ChurchEvent> events, DateTime now) {
  final end = DateTime(now.year, now.month, now.day + 7);
  final names = services.map((s) => s.name.toLowerCase()).toSet();
  final items = <WeekItem>[
    for (final s in services)
      if (nextOccurrence(s.schedule, now) case final o? when o.start.isBefore(end))
        WeekItem(
          start: o.start,
          hasTime: o.hasTime,
          title: s.name,
          icon: serviceIcon(s.icon),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s))),
        ),
    for (final e in events)
      if (!names.contains(e.title.toLowerCase()) &&
          !DateTime(e.date.year, e.date.month, e.date.day).isBefore(DateTime(now.year, now.month, now.day)) &&
          e.date.isBefore(end))
        WeekItem(
          start: _eventStart(e),
          hasTime: _eventStart(e) != DateTime(e.date.year, e.date.month, e.date.day),
          title: e.title,
          icon: Icons.event_outlined,
          isEvent: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
        ),
  ]..sort((a, b) => a.start.compareTo(b.start));
  return items;
}

DateTime _eventStart(ChurchEvent e) {
  final m = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*([ap])\.?\s*m', caseSensitive: false).firstMatch(e.time);
  if (m == null) return DateTime(e.date.year, e.date.month, e.date.day);
  final h = int.parse(m.group(1)!) % 12 + (m.group(3)!.toLowerCase() == 'p' ? 12 : 0);
  return DateTime(e.date.year, e.date.month, e.date.day, h, int.tryParse(m.group(2) ?? '0') ?? 0);
}

/// Events happening today that aren't regular services.
List<ChurchEvent> eventsToday(List<ChurchService> services, List<ChurchEvent> events, DateTime now) {
  final names = services.map((s) => s.name.toLowerCase()).toSet();
  return [
    for (final e in events)
      if (!names.contains(e.title.toLowerCase()) && e.date.year == now.year && e.date.month == now.month && e.date.day == now.day) e,
  ];
}

class ThisWeekList extends StatelessWidget {
  const ThisWeekList({super.key, required this.items});
  final List<WeekItem> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final now = appNow();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BethelSectionTitle('This week at Bethel',
          action: 'All events', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
      const SizedBox(height: 4),
      if (items.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Nothing on the calendar this week.', style: t.textTheme.bodyMedium)),
      for (final it in items.take(5))
        () {
          final today = it.start.year == now.year && it.start.month == now.month && it.start.day == now.day;
          return InkWell(
            onTap: it.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
              child: Row(children: [
                SizedBox(
                  width: 78,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dayLabel(it.start, now, hasTime: it.hasTime),
                        style: t.textTheme.labelLarge?.copyWith(color: today ? t.colorScheme.primary : null)),
                    if (it.hasTime) Text(clockTime(it.start), style: t.textTheme.bodySmall),
                  ]),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: today ? t.colorScheme.primary : tk.raised, borderRadius: BorderRadius.circular(10)),
                  child: Icon(it.icon, size: 18, color: today ? t.colorScheme.onPrimary : t.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                    Text(it.title, style: t.textTheme.titleSmall),
                    if (it.isEvent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: BethelColors.brassSoft, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Event', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5A4626))),
                      ),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
              ]),
            ),
          );
        }(),
    ]);
  }
}

/// "From our YouTube": one tile per playlist on the channel.
class PlaylistTiles extends StatelessWidget {
  const PlaylistTiles({super.key, required this.playlists, required this.onOpen, required this.onSeeAll});
  final List<VideoPlaylist> playlists;
  final ValueChanged<VideoPlaylist> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BethelSectionTitle('From our YouTube', action: 'See all', onAction: onSeeAll),
      const SizedBox(height: 10),
      SizedBox(
        height: 172,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final p = playlists[i];
            return Pressable(
              semanticLabel: '${p.title}, ${p.count} videos',
              onTap: () => onOpen(p),
              child: SizedBox(
                width: 200,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 113,
                      child: Stack(fit: StackFit.expand, children: [
                        BethelImage(p.thumbnail),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 52,
                            color: const Color(0xD1152824),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.playlist_play_rounded, size: 18, color: BethelColors.ivory),
                              Text('${p.count}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BethelColors.ivory)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(fontFamilyFallback: const [BethelFonts.telugu])),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// Everything for today finished: one small row near the bottom.
class DoneTodayRow extends StatelessWidget {
  const DoneTodayRow({super.key, required this.parts, required this.onReview});
  final List<String> parts;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: t.colorScheme.primary, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded, size: 18, color: t.colorScheme.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Done for today', style: t.textTheme.titleSmall),
            Text(parts.join(' · '), style: t.textTheme.bodySmall),
          ]),
        ),
        TextButton(onPressed: onReview, child: const Text('Review')),
      ]),
    );
  }
}
