import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

/// Daily verse + a simple 5-day reading plan with progress.
class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final Set<String> _done = {};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        AsyncView<DailyVerse>(load: state.repo.todayVerse, builder: (_, v) => VerseCard(verse: v)),
        const SizedBox(height: 24),
        AsyncView<List<BiblePassage>>(
          load: state.repo.readingPlan,
          builder: (context, plan) {
            final progress = plan.isEmpty ? 0.0 : _done.length / plan.length;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reading plan · Peace & Strength', style: t.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${_done.length} of ${plan.length} days complete',
                  style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: BethelColors.gold,
                  backgroundColor: t.colorScheme.surfaceContainer,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < plan.length; i++) ...[
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor:
                          _done.contains(plan[i].reference) ? const Color(0xFF4E7D6A) : t.colorScheme.surfaceContainer,
                      foregroundColor: _done.contains(plan[i].reference) ? Colors.white : t.colorScheme.primary,
                      child: _done.contains(plan[i].reference)
                          ? const Icon(Icons.check_rounded)
                          : Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    title: Text(plan[i].reference, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(plan[i].title),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final finished = await Navigator.push<bool>(
                          context, MaterialPageRoute(builder: (_) => PassageScreen(passage: plan[i])));
                      if (finished == true) setState(() => _done.add(plan[i].reference));
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ]);
          },
        ),
      ]),
    );
  }
}

class PassageScreen extends StatelessWidget {
  const PassageScreen({super.key, required this.passage});
  final BiblePassage passage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(passage.reference)),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
        Text(passage.title, style: t.textTheme.headlineSmall),
        Text('King James Version', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(children: [
            for (var i = 0; i < passage.verses.length; i++) ...[
              TextSpan(
                text: '${i + 1} ',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: BethelColors.gold),
              ),
              TextSpan(text: '${passage.verses[i]}  '),
            ],
          ]),
          style: const TextStyle(fontSize: 18, height: 1.8),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Mark as read'),
        ),
      ]),
    );
  }
}
