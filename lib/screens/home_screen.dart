import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'bible_screen.dart';
import 'events_screen.dart';
import '../data/church_content.dart';
import 'church_screens.dart';
import 'video_screen.dart';
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
              builder: (context, streams) {
                final live = streams.isEmpty ? null : streams.first;
                return OverlayCard(
                  image: live?.image ?? 'assets/church.jpg',
                  height: 210,
                  title: live?.title ?? 'Sunday Worship Service',
                  subtitle: live?.description ?? 'Sundays at 10:30 AM',
                  top: live?.isLive == true
                      ? const LivePill()
                      : const Pill('NEXT SERVICE', icon: Icons.schedule_rounded),
                  trailing: const PlayBadge(),
                  onTap: () => playVideo(context,
                      youtubeId: live?.youtubeId,
                      url: live?.youtubeUrl ?? AppConfig.youtubeLiveUrl,
                      title: live?.title ?? 'Sunday Worship Service',
                      subtitle: live?.description ?? '',
                      isLive: live?.isLive ?? false),
                );
              },
            ),
          ),
        ),
        // Quick actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _QuickAction(
                  icon: Icons.favorite_rounded,
                  label: 'Testimonies',
                  color: BethelColors.rose,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MediaListScreen(title: 'Testimonies', kind: 'Testimony', load: state.repo.testimonies)))),
              _QuickAction(
                  icon: Icons.volunteer_activism,
                  label: 'Pray',
                  color: BethelColors.gold,
                  onTap: () => AppShell.goToTab(context, AppShell.prayer)),
              _QuickAction(
                  icon: Icons.event_rounded,
                  label: 'Events',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
              _QuickAction(
                  icon: Icons.menu_book_rounded,
                  label: 'Bible',
                  color: const Color(0xFF4E7D6A),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BibleScreen()))),
            ]),
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
        // Meet our elders
        SliverToBoxAdapter(
          child: SectionHeader('Meet our elders',
              action: 'About',
              onAction: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EldersScreen(intro: eldersIntro)))),
        ),
        SliverToBoxAdapter(
          child: AsyncView<List<Elder>>(load: state.repo.elders, builder: (_, list) => EldersRow(elders: list)),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.colorScheme.outlineVariant),
              ),
              child: Icon(icon, color: color ?? t.colorScheme.primary, size: 27),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
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
          colors: dark ? const [Color(0xFF2A2F3A), Color(0xFF232731)] : const [Color(0xFFF7EBD3), Color(0xFFFBF3E4)],
        ),
        border: Border.all(color: dark ? const Color(0xFF3A3F4B) : const Color(0xFFEBD9B4)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.format_quote_rounded, color: BethelColors.gold, size: 30),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('VERSE OF THE DAY',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: BethelColors.gold)),
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
              style: const TextStyle(color: BethelColors.gold, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
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
