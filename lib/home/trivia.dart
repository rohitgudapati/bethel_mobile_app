import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../bible/bible_text.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_prompt.dart';

/// Home's trivia card: today's five hard questions, progress and Start/Continue.
class TriviaCard extends StatelessWidget {
  const TriviaCard({super.key, required this.quiz, required this.onChanged});
  final DailyQuiz quiz;
  final ValueChanged<DailyQuiz> onChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final q = quiz;
    final title = state.guest
        ? '${q.total} hard questions every day'
        : q.done == 0
            ? 'Today’s questions are ready'
            : '${q.done} of ${q.total} done · keep going';
    final sub = state.guest
        ? 'Sign in to play and join the leaderboard'
        : q.done == 0
            ? 'Up to ${q.total * 10 + 10} points${q.players > 0 ? ' · ${q.players} played today' : ''}'
            : '+${q.points} points so far';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.emoji_events_outlined, size: 16, color: tk.brassText),
          const SizedBox(width: 8),
          Expanded(child: Text('Bible trivia · ${q.total} hard questions', style: t.textTheme.bodySmall?.copyWith(color: tk.brassText))),
        ]),
        const SizedBox(height: 8),
        Text(title, style: t.textTheme.titleLarge),
        Text(sub, style: t.textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: QuizDots(quiz: q)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
            onPressed: () async {
              if (state.guest) {
                showSignInPrompt(context, title: 'Sign in to play and join the leaderboard', icon: Icons.emoji_events_outlined);
                return;
              }
              final result = await Navigator.push<DailyQuiz>(context, MaterialPageRoute(builder: (_) => TriviaScreen(quiz: q)));
              if (result != null) onChanged(result);
            },
            child: Text(state.guest ? 'Sign in to play' : (q.done == 0 ? 'Start' : 'Continue')),
          ),
        ]),
      ]),
    );
  }
}

/// Five circles: ticks for right answers, crosses for wrong, numbers for the rest.
class QuizDots extends StatelessWidget {
  const QuizDots({super.key, required this.quiz, this.current});
  final DailyQuiz quiz;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Semantics(
      label: '${quiz.done} of ${quiz.total} answered, ${quiz.right} right',
      child: ExcludeSemantics(
        child: Wrap(spacing: 8, children: [
          for (var i = 0; i < quiz.total; i++)
            () {
              final a = quiz.answers[i];
              final right = a?.correct == true;
              return Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a == null ? null : (right ? t.colorScheme.primary : tk.brassText),
                  border: a != null ? null : Border.all(color: current == i ? t.colorScheme.primary : tk.hairline, width: 1.5),
                ),
                child: a == null
                    ? Text('${i + 1}', style: t.textTheme.labelSmall)
                    : Icon(right ? Icons.check_rounded : Icons.close_rounded, size: 15, color: Colors.white),
              );
            }(),
        ]),
      ),
    );
  }
}

/// The five questions, one at a time. After each answer: right or wrong, the verse, and
/// how much of the church got it right. Pops with the updated quiz.
class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key, required this.quiz});
  final DailyQuiz quiz;

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late DailyQuiz _quiz = widget.quiz;
  late int _index = widget.quiz.nextIndex ?? 0;
  int? _checking;

  Future<void> _answer(int choice) async {
    if (_quiz.answers.containsKey(_index) || _checking != null) return;
    setState(() => _checking = choice);
    try {
      final a = await AppScope.read(context).repo.answerQuiz(_quiz, _index, choice);
      if (!mounted) return;
      setState(() {
        _quiz = _quiz.withAnswer(_index, a);
        _checking = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = null);
      showBethelToast(context, 'Couldn’t send your answer. Check your connection and try again.', icon: Icons.wifi_off_rounded);
    }
  }

  void _next() {
    final n = _quiz.nextIndex;
    if (n == null) {
      setState(() => _index = _quiz.total); // summary
    } else {
      setState(() => _index = n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _quiz);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_index >= _quiz.total ? 'Today’s trivia' : 'Question ${_index + 1} of ${_quiz.total}'),
          leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context, _quiz)),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
          QuizDots(quiz: _quiz, current: _index),
          const SizedBox(height: 20),
          if (_index >= _quiz.total) ..._summary(t) else ..._question(t),
        ]),
      ),
    );
  }

  List<Widget> _question(ThemeData t) {
    final tk = BethelTokens.of(context);
    final item = _quiz.items[_index];
    final a = _quiz.answers[_index];
    return [
      Text(item.question, style: t.textTheme.headlineSmall?.copyWith(height: 1.35)),
      const SizedBox(height: 20),
      for (var i = 0; i < item.choices.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: () {
            final mine = a?.choice == i || _checking == i;
            final right = a?.answer == i;
            final wrong = a != null && mine && !right;
            final color = right ? t.colorScheme.primary : (wrong ? tk.brassText : tk.hairline);
            return Material(
              color: right ? t.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color, width: mine || right ? 1.5 : 1)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: a != null || _checking != null ? null : () => _answer(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Expanded(child: Text(item.choices[i], style: t.textTheme.bodyLarge)),
                    if (_checking == i)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else if (right)
                      Icon(Icons.check_circle_rounded, color: t.colorScheme.primary, semanticLabel: 'Right answer')
                    else if (wrong)
                      Icon(Icons.cancel_outlined, color: tk.brassText, semanticLabel: 'Your answer'),
                  ]),
                ),
              ),
            );
          }(),
        ),
      if (a != null) ...[
        const SizedBox(height: 6),
        Text(
          a.correct == null
              ? 'Checking…'
              : a.correct!
                  ? 'Right! +${a.points} points'
                  : 'Not quite. It’s ${item.choices[a.answer!]}.',
          style: t.textTheme.titleMedium?.copyWith(color: a.correct == true ? t.colorScheme.primary : tk.brassText),
        ),
        if (a.ref.isNotEmpty) _VerseQuote(reference: a.ref),
        if (a.rightPercent != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${a.rightPercent}% of the church got this right', style: t.textTheme.bodySmall),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _next,
          child: Text(_quiz.nextIndex == null ? 'See your score' : 'Next question'),
        ),
      ],
    ];
  }

  List<Widget> _summary(ThemeData t) => [
        Text('${_quiz.right} of ${_quiz.total} right', style: t.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('+${_quiz.points} points today · new questions tomorrow', style: t.textTheme.bodyMedium),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.pop(context, _quiz), child: const Text('Done')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          child: const Text('See the leaderboard'),
        ),
      ];
}

/// The verse behind an answer, from the Bible bundled in the app.
class _VerseQuote extends StatelessWidget {
  const _VerseQuote({required this.reference});
  final String reference;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return FutureBuilder<String?>(
      future: () async {
        final ref = parseBibleRef(reference);
        if (ref == null) return null;
        await BibleText.load(BibleVersion.kjv);
        return biblePassage(BibleVersion.kjv, ref);
      }(),
      builder: (context, snap) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (snap.data != null && snap.data!.isNotEmpty)
            Text('“${snap.data}”', style: t.textTheme.bodyMedium?.copyWith(fontFamily: BethelFonts.display, height: 1.5)),
          Text(reference, style: t.textTheme.labelMedium?.copyWith(color: tk.brassText)),
        ]),
      ),
    );
  }
}

class LeaderRow extends StatelessWidget {
  const LeaderRow({super.key, required this.rank, required this.entry, this.me = false});
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

/// Top three on a podium (2 · 1 · 3).
class Podium extends StatelessWidget {
  const Podium({super.key, required this.top});
  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    const colors = [Color(0xFFC9A44C), Color(0xFFA7ADB4), Color(0xFFB98B5E)];
    const heights = [66.0, 46.0, 32.0];
    Widget col(int i) {
      if (i >= top.length) return const Expanded(child: SizedBox());
      final e = top[i];
      final initials = e.name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
      return Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tk.raised, border: Border.all(color: colors[i], width: 2)),
            child: Text(initials, style: t.textTheme.labelLarge),
          ),
          const SizedBox(height: 6),
          Text(e.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: t.textTheme.labelMedium),
          Text('${e.points} pts', style: t.textTheme.bodySmall),
          const SizedBox(height: 6),
          Container(
            height: heights[i],
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: colors[i], borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ]),
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [col(1), const SizedBox(width: 10), col(0), const SizedBox(width: 10), col(2)]);
  }
}

/// The weekly leaderboard card (Tuesday–Saturday) and, with [lastWeek], Monday's winners.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({super.key, required this.board, this.lastWeek = false});
  final Leaderboard board;
  final bool lastWeek;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final b = board;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(lastWeek ? 'Last week’s winners' : 'Leaderboard', style: t.textTheme.titleLarge)),
          Text(lastWeek ? 'Final standings' : 'This week · resets Monday', style: t.textTheme.bodySmall),
        ]),
        const SizedBox(height: 14),
        if (b.top.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(lastWeek ? 'Nobody played last week.' : 'No scores yet this week. Play today’s trivia to be first.', style: t.textTheme.bodyMedium),
          )
        else
          Podium(top: b.top.take(3).toList()),
        if (b.me != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text('#${b.myRank ?? '-'}', style: t.textTheme.titleMedium),
              const SizedBox(width: 12),
              Expanded(child: Text(lastWeek ? 'You finished with ${b.me!.points} points' : 'You · ${b.me!.name}', style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              if (!lastWeek) Text('${b.me!.points} pts', style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
        if (lastWeek)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('A new week has started — everyone is back to 0.', style: t.textTheme.bodySmall),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(lastWeek: lastWeek))),
            child: const Text('See full leaderboard'),
          ),
        ),
      ]),
    );
  }
}

/// Sunday: the leaderboard closes tonight. Shows your gap to the next place.
class FinalDayCard extends StatelessWidget {
  const FinalDayCard({super.key, required this.board, required this.onPlay, this.canPlay = true});
  final Leaderboard board;
  final VoidCallback onPlay;
  final bool canPlay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final b = board;
    final rank = b.myRank;
    final above = rank != null && rank > 1 && rank - 2 < b.top.length ? b.top[rank - 2] : null;
    final headline = b.me == null
        ? 'Last day to get on this week’s board'
        : rank == 1
            ? 'You’re #1 — hold on to it today'
            : above != null
                ? 'You’re #$rank — ${above.points - b.me!.points} points behind ${above.name.split(' ').first} for #${rank - 1}'
                : 'You’re #$rank this week';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.brassText, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.emoji_events_outlined, size: 16, color: tk.brassText),
          const SizedBox(width: 8),
          Expanded(
            child: Text('FINAL DAY · LEADERBOARD CLOSES TONIGHT',
                style: t.textTheme.labelSmall?.copyWith(color: tk.brassText, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(headline, style: t.textTheme.titleLarge),
        if (canPlay) Text('Today’s questions could move you up.', style: t.textTheme.bodySmall),
        const SizedBox(height: 6),
        if (above != null) LeaderRow(rank: rank! - 1, entry: above),
        if (b.me != null) LeaderRow(rank: rank ?? 0, entry: b.me!, me: true),
        if (b.me == null)
          for (var i = 0; i < b.top.length && i < 3; i++) LeaderRow(rank: i + 1, entry: b.top[i]),
        if (canPlay) ...[
          const SizedBox(height: 8),
          FilledButton(onPressed: onPlay, child: const Text('Play today’s questions')),
        ],
      ]),
    );
  }
}

/// This week's full leaderboard, or last week's final one.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, this.lastWeek = false});
  final bool lastWeek;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: AsyncView<Leaderboard>(
        load: () => AppScope.read(context).repo.leaderboard(limit: 50, lastWeek: lastWeek),
        builder: (context, b) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
          Text(lastWeek ? 'Last week' : 'This week', style: t.textTheme.headlineSmall),
          Text(lastWeek ? 'Final standings' : 'Starts over every Monday', style: t.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (b.top.isEmpty)
            const BethelEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No scores yet',
              message: 'Answer today’s trivia on Home to be the first on the board',
            )
          else ...[
            for (var i = 0; i < b.top.length; i++) LeaderRow(rank: i + 1, entry: b.top[i], me: b.top[i].uid == b.me?.uid),
            if (b.me != null && (b.myRank ?? 0) > b.top.length) ...[
              const SizedBox(height: 4),
              Divider(color: tk.hairline),
              LeaderRow(rank: b.myRank!, entry: b.me!, me: true),
            ],
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tk.raised, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'How points work: 5 hard questions a day, the same for everyone. 10 points for each right answer, plus 2 for every day in a row you’ve finished them (up to 10 extra).',
              style: t.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ]),
      ),
    );
  }
}
