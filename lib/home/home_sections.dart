import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../notifications/notification_service.dart';
import '../screens/church_screens.dart';
import '../screens/shell.dart';
import '../screens/songs_screen.dart' show openAlbum;
import '../screens/watch_screen.dart' show SermonDetailScreen;
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';
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
    final now = DateTime.now();
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
            Text(happening ? 'HAPPENING NOW' : 'NEXT UP · ${day.toUpperCase()}',
                style: const TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: BethelColors.brassSoft)),
            const SizedBox(height: 2),
            Text(widget.service.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: BethelColors.ivory)),
            Text(
              [if (w.hasTime) clockTime(w.start), if (w.hasTime && !happening) countdown(w.start, now), if (!w.hasTime) widget.service.schedule].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xCCF4EFE6)),
            ),
          ]),
        ),
        if (!happening)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BethelColors.ivory),
            onPressed: _reminded ? null : _remind,
            child: Text(_reminded ? 'Reminder on' : 'Remind me', style: TextStyle(color: _reminded ? const Color(0x99F4EFE6) : BethelColors.ivory)),
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

/// "This week": every service as a swipeable card; today's is marked.
class ServicesRow extends StatelessWidget {
  const ServicesRow({super.key, required this.services});
  final List<ChurchService> services;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BethelSectionTitle('Services',
          action: 'View all', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen()))),
      const SizedBox(height: 10),
      SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final s = services[i];
            final o = nextOccurrence(s.schedule, now);
            final today = o != null && dayLabel(o.start, now, hasTime: o.hasTime).startsWith(RegExp('To(day|night)'));
            return Pressable(
              semanticLabel: '${s.name}, ${s.schedule}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s))),
              child: Container(
                width: 168,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tk.raised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: today ? tk.brassText : t.dividerColor.withValues(alpha: 0.4), width: today ? 1.5 : 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.brightness == Brightness.dark ? t.colorScheme.surfaceContainer : BethelColors.brassSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(serviceIcon(s.icon), size: 20, color: t.colorScheme.primary),
                    ),
                    const Spacer(),
                    if (today)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: BethelColors.forest, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BethelColors.ivory)),
                      ),
                  ]),
                  const Spacer(),
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
                  Text(s.schedule, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// "New and latest": a new album (special meetings) and the latest message.
class NewAndLatest extends StatelessWidget {
  const NewAndLatest({super.key, required this.album, required this.sermon});
  final Album? album;
  final Sermon? sermon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget card({required String label, required String title, required String sub, required String image, required IconData icon, required VoidCallback onTap}) =>
        Expanded(
          child: Pressable(
            semanticLabel: '$label: $title',
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(fit: StackFit.expand, children: [
                    BethelImage(image),
                    const DecoratedBox(
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x99000000)])),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: BethelColors.ivory, borderRadius: BorderRadius.circular(6)),
                        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BethelColors.ink)),
                      ),
                    ),
                    Positioned(right: 10, bottom: 10, child: Icon(icon, color: Colors.white, size: 26)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(fontFamilyFallback: const [BethelFonts.telugu])),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
            ]),
          ),
        );
    final a = album, s = sermon;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const BethelSectionTitle('New and latest'),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (s != null)
          card(
            label: 'Latest message',
            title: s.title,
            sub: s.preacher,
            image: s.image,
            icon: Icons.play_circle_fill_rounded,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SermonDetailScreen(sermon: s))),
          ),
        if (s != null && a != null) const SizedBox(width: 12),
        if (a != null)
          card(
            label: 'New album',
            title: a.title,
            sub: [if (a.dates.isNotEmpty) a.dates, '${a.songCount} songs'].join(' · '),
            image: a.image,
            icon: Icons.library_music_rounded,
            onTap: () => openAlbum(context, a),
          ),
      ]),
    ]);
  }
}

/// The two newest prayer requests, with "I prayed".
class PrayerPeek extends StatelessWidget {
  const PrayerPeek({super.key, required this.prayers});
  final List<PrayerRequest> prayers;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final state = AppScope.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BethelSectionTitle('Prayer wall', action: 'See all', onAction: () => AppShell.goToTab(context, AppShell.prayer)),
      const SizedBox(height: 6),
      for (final p in prayers.take(2))
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.request, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium?.copyWith(height: 1.35, fontFamilyFallback: const [BethelFonts.telugu])),
                const SizedBox(height: 4),
                Text(
                  [p.name.trim().isEmpty ? 'Anonymous' : p.name, '${p.prayedCount + (state.prayedFor.contains(p.id) ? 1 : 0)} prayed'].join(' · '),
                  style: t.textTheme.bodySmall,
                ),
              ]),
            ),
            state.prayedFor.contains(p.id)
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.favorite_rounded, color: tk.brassText, semanticLabel: 'You prayed'),
                  )
                : TextButton(
                    onPressed: () {
                      if (state.guest) {
                        showSignInPrompt(context, title: 'Sign in to pray with others', icon: Icons.favorite_border_rounded);
                        return;
                      }
                      state.prayFor(p.id);
                      showBethelToast(context, 'Thank you for praying', icon: Icons.favorite_rounded);
                    },
                    child: const Text('I prayed'),
                  ),
          ]),
        ),
    ]);
  }
}

/// "Visit us": a Google map of the church (when a Maps key is set), address, Directions and Call.
class VisitUsCard extends StatelessWidget {
  const VisitUsCard({super.key, required this.info});
  final ChurchInfo info;

  String get _address => info.address.isEmpty ? AppConfig.churchAddress : info.address;

  String _mapImage(bool dark) {
    final where = Uri.encodeComponent('${AppConfig.churchName}, $_address');
    final style = dark
        ? '&style=element:geometry%7Ccolor:0x1d2c2a&style=element:labels.text.fill%7Ccolor:0xc9c2b4&style=element:labels.text.stroke%7Ccolor:0x1d2c2a'
            '&style=feature:road%7Celement:geometry%7Ccolor:0x2f403d&style=feature:water%7Ccolor:0x0f1a19&style=feature:poi%7Cvisibility:off'
        : '&style=feature:poi%7Cvisibility:off';
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$where&zoom=14&size=640x300&scale=2'
        '&markers=color:0x1F4D3F%7C$where$style&key=${AppConfig.mapsApiKey}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final dark = t.brightness == Brightness.dark;
    final phone = info.phone.split(RegExp(r'[·,/]')).first.trim();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          label: 'Open the church in Google Maps',
          child: GestureDetector(
            onTap: () => openLink(context, AppConfig.mapsUrl),
            child: AspectRatio(
              aspectRatio: 640 / 300,
              child: AppConfig.mapsApiKey.isEmpty
                  ? const BethelImage('assets/church.jpg')
                  : Image.network(
                      _mapImage(dark),
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      errorBuilder: (_, __, ___) => const BethelImage('assets/church.jpg'),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Visit us', style: t.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(_address, style: t.textTheme.bodySmall),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(children: [
            TextButton.icon(
              onPressed: () => openLink(context, AppConfig.mapsUrl),
              icon: const Icon(Icons.directions_rounded, size: 18),
              label: const Text('Directions'),
            ),
            if (phone.isNotEmpty)
              TextButton.icon(
                onPressed: () => openLink(context, 'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}'),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('Call'),
              ),
          ]),
        ),
      ]),
    );
  }
}
