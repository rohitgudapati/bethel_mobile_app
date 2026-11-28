import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';

/// Home's daily Bible question with this week's top three. Shows [fallback] (the offline
/// "Did you know?" card) until the church's server has published a question.
class DailyQuestionCard extends StatefulWidget {
  const DailyQuestionCard({super.key, required this.fallback});
  final Widget fallback;

  @override
  State<DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends State<DailyQuestionCard> {
  DailyQuestion? _q;
  Leaderboard? _board;
  bool _loaded = false;
  bool _loading = true;
  int? _checking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    _loaded = true;
    final repo = AppScope.read(context).repo;
    DailyQuestion? q;
    Leaderboard? board;
    try {
      q = await repo.dailyQuestion();
    } catch (_) {}
    try {
      board = await repo.leaderboard(limit: 3);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _q = q;
        _board = board;
        _loading = false;
      });
    }
  }

  Future<void> _answer(int choice) async {
    final state = AppScope.read(context);
    final q = _q;
    if (q == null || q.answered || _checking != null) return;
    if (state.guest) {
      showSignInPrompt(context, title: 'Sign in to play and join the leaderboard', icon: Icons.emoji_events_outlined);
      return;
    }
    setState(() => _checking = choice);
    try {
      final checked = await state.repo.answerDailyQuestion(q, choice);
      Leaderboard? board;
      try {
        board = await state.repo.leaderboard(limit: 3);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _q = checked;
        _board = board ?? _board;
        _checking = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = null);
      showBethelToast(context, 'Couldn’t send your answer. Check your connection and try again.', icon: Icons.wifi_off_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonBox(height: 220, radius: 16);
    final q = _q;
    if (q == null) return widget.fallback;
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final board = _board;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.emoji_events_outlined, size: 16, color: tk.brassText),
          const SizedBox(width: 8),
          Expanded(child: Text('Daily question', style: t.textTheme.bodySmall?.copyWith(color: tk.brassText))),
          if (board?.me != null) Text('You: ${board!.me!.points} pts', style: t.textTheme.bodySmall),
        ]),
        const SizedBox(height: 8),
        Text(q.question, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.45)),
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++) _choice(q, i),
        if (q.answered) ...[
          const SizedBox(height: 4),
          Text(
            !q.checked
                ? 'Checking your answer…'
                : q.correct!
                    ? 'Right! +${q.points ?? 0} points${q.streak > 1 ? ' · ${q.streak}-day streak' : ''}'
                    : 'Not quite. It’s ${q.choices[q.answer!]}${q.ref.isEmpty ? '' : ' (${q.ref})'}.',
            style: t.textTheme.labelLarge?.copyWith(color: q.correct == true ? t.colorScheme.primary : tk.brassText),
          ),
          Text('A new question tomorrow', style: t.textTheme.bodySmall),
        ],
        if (board != null && board.top.isNotEmpty) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: tk.hairline),
          const SizedBox(height: 10),
          Text('This week', style: t.textTheme.labelLarge),
          const SizedBox(height: 4),
          for (var i = 0; i < board.top.length && i < 3; i++) _LeaderRow(rank: i + 1, entry: board.top[i], me: board.top[i].uid == board.me?.uid),
          if (board.me != null && (board.myRank ?? 99) > 3) _LeaderRow(rank: board.myRank!, entry: board.me!, me: true),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            child: const Text('See the leaderboard'),
          ),
        ),
      ]),
    );
  }

  Widget _choice(DailyQuestion q, int i) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final mine = q.myChoice == i || _checking == i;
    final right = q.checked && q.answer == i;
    final wrong = q.checked && mine && !right;
    final color = right ? t.colorScheme.primary : (wrong ? tk.brassText : tk.hairline);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: right ? t.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: mine || right ? color : tk.hairline, width: mine || right ? 1.5 : 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: q.answered || _checking != null ? null : () => _answer(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Expanded(child: Text(q.choices[i], style: t.textTheme.bodyMedium?.copyWith(fontFamilyFallback: const [BethelFonts.telugu]))),
              if (_checking == i)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else if (right)
                Icon(Icons.check_circle_rounded, size: 18, color: t.colorScheme.primary, semanticLabel: 'Right answer')
              else if (wrong)
                Icon(Icons.cancel_outlined, size: 18, color: tk.brassText, semanticLabel: 'Your answer'),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.entry, this.me = false});
  final int rank;
  final LeaderboardEntry entry;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    const medals = [Color(0xFFC9A44C), Color(0xFFA7ADB4), Color(0xFFB98B5E)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: rank <= 3 ? medals[rank - 1] : tk.raised),
          child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rank <= 3 ? Colors.white : t.colorScheme.onSurface)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(me ? '${entry.name} (you)' : entry.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium?.copyWith(fontWeight: me ? FontWeight.w600 : FontWeight.w400)),
        ),
        if (entry.streak > 1) ...[
          Icon(Icons.local_fire_department_rounded, size: 14, color: tk.brassText),
          Text('${entry.streak}', style: t.textTheme.bodySmall),
          const SizedBox(width: 10),
        ],
        Text('${entry.points} pts', style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// This week's full leaderboard. It starts over every Monday.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: AsyncView<Leaderboard>(
        load: () => AppScope.read(context).repo.leaderboard(limit: 50),
        builder: (context, b) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
          Text('This week', style: t.textTheme.headlineSmall),
          Text('Starts over every Monday', style: t.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (b.top.isEmpty)
            const BethelEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No scores yet this week',
              message: 'Answer today’s question on Home to be the first on the board',
            )
          else ...[
            for (var i = 0; i < b.top.length; i++) _LeaderRow(rank: i + 1, entry: b.top[i], me: b.top[i].uid == b.me?.uid),
            if (b.me != null && (b.myRank ?? 0) > b.top.length) ...[
              const SizedBox(height: 4),
              Divider(color: tk.hairline),
              _LeaderRow(rank: b.myRank!, entry: b.me!, me: true),
            ],
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'How points work: 10 for a right answer, plus 2 for every day in a row you’ve played (up to 10 extra). One question a day, for everyone.',
              style: t.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ]),
      ),
    );
  }
}
