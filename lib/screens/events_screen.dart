import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: AsyncView<List<ChurchEvent>>(
        load: state.repo.events,
        builder: (context, events) {
          final cats = ['All', ...{for (final e in events) e.category}];
          final shown = _filter == 'All' ? events : events.where((e) => e.category == _filter).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(cats[i]),
                  selected: _filter == cats[i],
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = cats[i]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final e in shown) ...[EventRow(event: e), const SizedBox(height: 12)],
          ]);
        },
      ),
    );
  }
}

class DateBlock extends StatelessWidget {
  const DateBlock({super.key, required this.date, this.light = false});
  final DateTime date;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: light ? Colors.white : BethelColors.goldSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(fmtMonth(date),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: BethelColors.rose, letterSpacing: 0.6)),
          Text('${date.day}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: BethelColors.ink, height: 1.15)),
        ]),
      );
}

/// Horizontal card used on Home.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});
  final ChurchEvent event;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              BethelImage(event.image, height: 130, width: double.infinity),
              Positioned(left: 12, top: 12, child: DateBlock(date: event.date, light: true)),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded, size: 15, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('${event.time} · ${event.venue}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
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

/// List row used on the Events screen.
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event});
  final ChurchEvent event;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final going = AppScope.of(context).rsvps.contains(event.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            BethelImage(event.image, width: 84, height: 84, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmtShort(event.date).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: BethelColors.rose, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(event.title, style: t.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${event.time} · ${event.venue}',
                    style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
            if (going) const Icon(Icons.check_circle_rounded, color: Color(0xFF4E7D6A)),
          ]),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});
  final ChurchEvent event;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final going = state.rsvps.contains(event.id);
    final t = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          foregroundColor: Colors.white,
          backgroundColor: BethelColors.navyDeep,
          flexibleSpace: FlexibleSpaceBar(background: BethelImage(event.image)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Pill(event.category),
              const SizedBox(height: 10),
              Text(event.title, style: t.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.calendar_today_rounded, text: fmtShort(event.date)),
              _InfoRow(icon: Icons.schedule_rounded, text: event.time),
              _InfoRow(icon: Icons.place_outlined, text: '${event.venue} · ${AppConfig.churchName}'),
              if (event.speakers.isNotEmpty)
                _InfoRow(icon: Icons.mic_none_rounded, text: event.speakers.join(', ')),
              const SizedBox(height: 16),
              Text(event.description, style: const TextStyle(fontSize: 15, height: 1.6)),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showToast(context, 'Added to your calendar.'),
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Save date'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  state.toggleRsvp(event.id);
                  showToast(context, going ? 'RSVP removed.' : 'See you there! We saved your spot.');
                },
                icon: Icon(going ? Icons.check_rounded : Icons.how_to_reg_rounded),
                label: Text(going ? 'Going' : 'RSVP'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
      );
}
