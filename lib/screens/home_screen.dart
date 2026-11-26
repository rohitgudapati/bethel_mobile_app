import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/line_art.dart';
import 'bible_screen.dart';
import 'events_screen.dart';
import 'church_screens.dart';
import 'live_banner.dart';
import 'shell.dart';
import 'watch_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

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
            child: Row(children: [
              const ClipOval(child: BethelImage('assets/church/logo.png', width: 52, height: 52)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_greeting()},', style: TextStyle(color: t.colorScheme.onSurfaceVariant, fontSize: 15)),
                  Text(state.guest ? 'Welcome, friend' : state.greetingName,
                      style: t.textTheme.headlineMedium?.copyWith(height: 1.2)),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => openLink(context, AppConfig.mapsUrl),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.place_rounded, size: 16, color: BethelColors.rose),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(AppConfig.churchAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
                      ),
                    ]),
                  ),
                ]),
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    showToast(context, 'Notifications: service reminders, new sermons and prayer updates.'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ]),
          ),
        ),
        if (AppConfig.isDemo)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.science_outlined, size: 18, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Demo mode: showing sample content until the API is connected.',
                        style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
                  ),
                ]),
              ),
            ),
          ),
        // Verse of the day (first thing on Home)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: AsyncView<DailyVerse>(load: state.repo.todayVerse, builder: (_, v) => VerseCard(verse: v)),
          ),
        ),
        // Live / next service hero
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: AsyncView<List<LiveStream>>(
              load: state.repo.liveStreams,
              builder: (context, streams) => LiveBanner(streams: streams),
            ),
          ),
        ),
        // Shortcuts: illustrated cards that show what's new in each place
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _HomeShortcuts(),
          ),
        ),
        // Upcoming events
        SliverToBoxAdapter(
          child: SectionHeader('Upcoming',
              action: 'See all',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: AsyncView<List<ChurchEvent>>(
              load: state.repo.events,
              builder: (context, events) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => EventCard(event: events[i]),
              ),
            ),
          ),
        ),
        // Services
        SliverToBoxAdapter(
          child: SectionHeader('Services',
              action: 'View all',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen()))),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 128,
            child: AsyncView<List<ChurchService>>(
              load: state.repo.services,
              builder: (context, services) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ServiceChipCard(service: services[i]),
              ),
            ),
          ),
        ),
        // Latest sermons
        SliverToBoxAdapter(
          child: SectionHeader('Latest messages',
              action: 'All sermons', onAction: () => AppShell.goToTab(context, AppShell.watch)),
        ),
        AsyncView<List<Sermon>>(
          sliver: true,
          load: state.repo.sermons,
          builder: (context, sermons) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: sermons.length.clamp(0, 3),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => SermonTile(sermon: sermons[i]),
            ),
          ),
        ),
        // Verse of the day images (archive)
        SliverToBoxAdapter(
          child: SectionHeader('Verse of the day images',
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              action: 'View more',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseArchiveScreen()))),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: AsyncView<List<DailyVerse>>(
              load: state.repo.verseArchive,
              builder: (context, verses) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: verses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseArchiveScreen())),
                  child: BethelImage(verses[i].image ?? '', width: 150, height: 150, radius: 18),
                ),
              ),
            ),
          ),
        ),
        // Church address
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: AsyncView<ChurchInfo>(load: state.repo.churchInfo, builder: (_, c) => ChurchAddressCard(info: c)),
          ),
        ),
      ]),
    );
  }
}

/// 2×2 grid of illustrated cards. Each card says something current
/// (today's reading, the next event…) so it invites a tap rather than just naming a section.
class _HomeShortcuts extends StatefulWidget {
  const _HomeShortcuts();

  @override
  State<_HomeShortcuts> createState() => _HomeShortcutsState();
}

class _HomeShortcutsState extends State<_HomeShortcuts> {
  String? _testimony, _prayer, _event, _reading;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final repo = AppScope.read(context).repo;

    void load<T>(Future<T> f, String? Function(T) describe, void Function(String?) set) {
      f.then((v) {
        if (mounted) setState(() => set(describe(v)));
      }).catchError((_) {});
    }

    load<List<MediaItem>>(repo.testimonies(), (l) => l.isEmpty ? null : 'New: ${l.first.title}', (s) => _testimony = s);
    load<List<PrayerRequest>>(
        repo.prayerWall(),
        (l) => l.isEmpty ? null : '${l.length} ${l.length == 1 ? 'request' : 'requests'} to lift up',
        (s) => _prayer = s);
    load<List<ChurchEvent>>(repo.events(), (l) {
      final today = DateUtils.dateOnly(DateTime.now());
      final next = l.where((e) => !e.date.isBefore(today)).toList()..sort((a, b) => a.date.compareTo(b.date));
      return next.isEmpty ? null : '${fmtShort(next.first.date).split(',').first} · ${next.first.title}';
    }, (s) => _event = s);
    load<List<BiblePassage>>(
        repo.readingPlan(), (l) => l.isEmpty ? null : 'Today: ${l.first.reference}', (s) => _reading = s);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Muted tints drawn from the brand palette: terracotta, gold, navy, sage.
    Color tint(int light) => dark ? BethelColors.nightCard : Color(light);
    Color wash(Color c) => c.withValues(alpha: dark ? 0.22 : 0.16);

    final cards = [
      _ShortcutCard(
        title: 'Testimonies',
        subtitle: _testimony ?? 'Stories of God at work',
        art: LineArtKind.lamp,
        background: tint(0xFFF2EBE4),
        wash: wash(BethelColors.rose),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    MediaListScreen(title: 'Testimonies', kind: 'Testimony', load: state.repo.testimonies))),
      ),
      _ShortcutCard(
        title: 'Pray',
        subtitle: _prayer ?? 'Share a request',
        art: LineArtKind.prayingHands,
        background: tint(0xFFEFE8DA),
        wash: wash(BethelColors.brass),
        onTap: () => AppShell.goToTab(context, AppShell.prayer),
      ),
      _ShortcutCard(
        title: 'Events',
        subtitle: _event ?? 'What\'s on at church',
        art: LineArtKind.chapel,
        background: tint(0xFFE4EAE6),
        wash: wash(BethelColors.forest),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
      ),
      _ShortcutCard(
        title: 'Bible',
        subtitle: _reading ?? 'Reading plan',
        art: LineArtKind.openBible,
        background: tint(0xFFECEAE2),
        wash: wash(const Color(0xFF4E7D6A)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BibleScreen())),
      ),
    ];

    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ]),
        );
    return Column(children: [row(cards[0], cards[1]), const SizedBox(height: 12), row(cards[2], cards[3])]);
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.art,
    required this.background,
    required this.wash,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final LineArtKind art;
  final Color background;
  final Color wash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LineArt(art, size: 58, wash: wash),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 18, color: t.colorScheme.onSurfaceVariant),
            ]),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.2)),
            const SizedBox(height: 3),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.verse});
  final DailyVerse verse;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasText = verse.text != null && verse.text!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark ? const [Color(0xFF26302D), Color(0xFF202725)] : const [Color(0xFFEFE7D8), Color(0xFFF8F5EF)],
        ),
        border: Border.all(color: dark ? const Color(0xFF34403C) : const Color(0xFFE2D6C0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.format_quote_rounded, color: BethelColors.brass, size: 30),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('VERSE OF THE DAY',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: BethelColors.brassText)),
          ),
          Text(fmtShort(verse.date),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
        ]),
        const SizedBox(height: 6),
        if (hasText)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(verse.text!, style: const TextStyle(fontSize: 17, height: 1.55, fontWeight: FontWeight.w500)),
          )
        else if (verse.image != null)
          BethelImage(verse.image!, radius: 14, height: 220, width: double.infinity),
        if (verse.reference != null) ...[
          const SizedBox(height: 10),
          Text(verse.reference!,
              style: const TextStyle(color: BethelColors.brassText, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
        const SizedBox(height: 4),
        Row(children: [
          IconButton(
            onPressed: () => state.toggleVerseLike(verse.id),
            icon: Icon(state.isVerseLiked(verse.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: state.isVerseLiked(verse.id) ? BethelColors.rose : null),
          ),
          Text(compactCount(verse.likes + (state.isVerseLiked(verse.id) ? 1 : 0)),
              style: const TextStyle(fontSize: 13)),
          IconButton(
            onPressed: () {
              state.repo.shareVerse(verse.id).ignore();
              showToast(context, 'Share sheet opens here (copies "${verse.reference ?? 'verse'}").');
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
          Expanded(
            child: verse.views > 0
                ? Row(children: [
                    Icon(Icons.visibility_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(compactCount(verse.views),
                          maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 13)),
                    ),
                  ])
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Read in the Bible',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BibleScreen())),
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ]),
      ]),
    );
  }
}
