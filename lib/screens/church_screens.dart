import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

IconData serviceIcon(IconDataRef ref) => switch (ref) {
      IconDataRef.prayer => Icons.volunteer_activism_rounded,
      IconDataRef.worship => Icons.church_rounded,
      IconDataRef.bible => Icons.menu_book_rounded,
      IconDataRef.family => Icons.family_restroom_rounded,
      IconDataRef.fasting => Icons.self_improvement_rounded,
    };

// ------------------------------------------------------------------ services

/// Compact card for the Home "Services" row.
class ServiceChipCard extends StatelessWidget {
  const ServiceChipCard({super.key, required this.service});
  final ChurchService service;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.brightness == Brightness.dark ? t.colorScheme.surfaceContainer : BethelColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(serviceIcon(service.icon), size: 20, color: t.colorScheme.primary),
              ),
              const Spacer(),
              Text(service.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(service.schedule,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: AsyncView<List<ChurchService>>(
        load: state.repo.services,
        builder: (context, list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final s = list[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s))),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    BethelImage(s.image, width: 76, height: 76, radius: 14),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: t.textTheme.titleMedium),
                        if (s.schedule.isNotEmpty)
                          Text(s.schedule,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600, color: BethelColors.gold)),
                        Text(s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});
  final ChurchService service;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          foregroundColor: Colors.white,
          backgroundColor: BethelColors.navyDeep,
          flexibleSpace: FlexibleSpaceBar(background: BethelImage(service.image)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.name, style: t.textTheme.headlineSmall),
              if (service.schedule.isNotEmpty) ...[
                const SizedBox(height: 6),
                Pill(service.schedule, icon: Icons.schedule_rounded),
              ],
              const SizedBox(height: 16),
              Text(service.description, style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 24),
              Text('Request this service', style: t.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('For a home visit, special prayer or a family occasion. The church office will contact you.',
                  style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              _BookServiceForm(service: service),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BookServiceForm extends StatefulWidget {
  const _BookServiceForm({required this.service});
  final ChurchService service;

  @override
  State<_BookServiceForm> createState() => _BookServiceFormState();
}

class _BookServiceFormState extends State<_BookServiceForm> {
  late final _name = TextEditingController(text: AppScope.read(context).user?.name ?? '');
  final _phone = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  Future<void> _send() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      showToast(context, 'Please add your name and phone number.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.read(context)
          .repo
          .bookService(widget.service.id, name: _name.text.trim(), phone: _phone.text.trim(), note: _note.text.trim());
      if (!mounted) return;
      _note.clear();
      showToast(context, 'Request sent. The church office will be in touch.');
    } catch (e) {
      if (mounted) showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
      const SizedBox(height: 12),
      TextField(
          controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
      const SizedBox(height: 12),
      TextField(
        controller: _note,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Preferred date or details (optional)', alignLabelWithHint: true),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _send,
        child: _busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
            : const Text('Send request'),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ verses

class VerseArchiveScreen extends StatelessWidget {
  const VerseArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verse of the day')),
      body: AsyncView<List<DailyVerse>>(
        load: state.repo.verseArchive,
        builder: (context, verses) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: verses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (_, i) => _VerseImageCard(verse: verses[i]),
        ),
      ),
    );
  }
}

class _VerseImageCard extends StatelessWidget {
  const _VerseImageCard({required this.verse});
  final DailyVerse verse;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final liked = state.isVerseLiked(verse.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: BethelImage(verse.image ?? '')),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 6),
          child: Row(children: [
            IconButton(
              onPressed: () => state.toggleVerseLike(verse.id),
              icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: liked ? BethelColors.rose : null),
            ),
            Text(compactCount(verse.likes + (liked ? 1 : 0))),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                state.repo.shareVerse(verse.id).ignore();
                showToast(context, 'Verse image ready to share.');
              },
              icon: const Icon(Icons.ios_share_rounded),
            ),
            Text(compactCount(verse.shares)),
            const SizedBox(width: 12),
            Icon(Icons.visibility_outlined, size: 20, color: t.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(compactCount(verse.views)),
            const Spacer(),
            Text(fmtShort(verse.date), style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ address

class ChurchAddressCard extends StatelessWidget {
  const ChurchAddressCard({super.key, required this.info});
  final ChurchInfo info;

  String get _mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${info.name}, ${info.address}')}';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: BethelColors.navy,
        child: InkWell(
          onTap: () => openLink(context, _mapUrl),
          child: Stack(children: [
            const Positioned.fill(child: Opacity(opacity: 0.25, child: BethelImage('assets/map.jpeg'))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.place_rounded, color: BethelColors.rose),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Visit us',
                        style: TextStyle(color: BethelColors.goldSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    Text(info.address,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
                    Text(info.country, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5)),
                  ]),
                ),
                const SizedBox(width: 8),
                const Text('View on map',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ ministries

class MinistryDetailScreen extends StatelessWidget {
  const MinistryDetailScreen({super.key, required this.ministry});
  final Ministry ministry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          foregroundColor: Colors.white,
          backgroundColor: BethelColors.navyDeep,
          flexibleSpace: FlexibleSpaceBar(background: BethelImage(ministry.image)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ministry.name, style: t.textTheme.headlineSmall),
              if (ministry.meets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Pill(ministry.meets, icon: Icons.schedule_rounded),
              ],
              const SizedBox(height: 16),
              Text(ministry.info, style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showToast(context, 'Thanks! A ministry leader will reach out.'),
                icon: const Icon(Icons.waving_hand_rounded),
                label: const Text('I\'d like to get involved'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ elders

/// Horizontal "Meet our elders" row for Home.
class EldersRow extends StatelessWidget {
  const EldersRow({super.key, required this.elders, this.padding = const EdgeInsets.symmetric(horizontal: 20)});
  final List<Elder> elders;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: elders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final e = elders[i];
          return SizedBox(
            width: 172,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ElderScreen(elder: e))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BethelImage(e.image, height: 160, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(e.role,
                          style: const TextStyle(fontSize: 12, color: BethelColors.gold, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EldersScreen extends StatelessWidget {
  const EldersScreen({super.key, this.intro = ''});
  final String intro;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Our elders')),
      body: AsyncView<List<Elder>>(
        load: state.repo.elders,
        builder: (context, list) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
          if (intro.isNotEmpty) ...[
            Text(intro, style: TextStyle(color: t.colorScheme.onSurfaceVariant, height: 1.6)),
            const SizedBox(height: 18),
          ],
          for (final e in list) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ElderScreen(elder: e))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AspectRatio(aspectRatio: 4 / 3, child: BethelImage(e.image)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name, style: t.textTheme.titleLarge),
                      Text(e.role, style: const TextStyle(color: BethelColors.gold, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(e.bio, style: const TextStyle(height: 1.6)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ]),
      ),
    );
  }
}

class ElderScreen extends StatelessWidget {
  const ElderScreen({super.key, required this.elder});
  final Elder elder;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tel = elder.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          foregroundColor: Colors.white,
          backgroundColor: BethelColors.navyDeep,
          flexibleSpace: FlexibleSpaceBar(background: BethelImage(elder.image)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill(elder.role),
              const SizedBox(height: 10),
              Text(elder.name, style: t.textTheme.headlineSmall),
              const SizedBox(height: 14),
              Text(elder.bio, style: const TextStyle(fontSize: 15, height: 1.7)),
              if (elder.phone.isNotEmpty) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => openLink(context, 'tel:$tel'),
                  icon: const Icon(Icons.call_rounded),
                  label: Text('Call ${elder.phone}'),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
