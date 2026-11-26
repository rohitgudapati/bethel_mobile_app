import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../plan/plan_messages.dart';
import '../plan/reading_plan.dart';
import '../plan/reminder_planner.dart';
import '../widgets/common.dart';
import 'bible_reader_screen.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
String longDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1].substring(0, 3)} ${d.day}';
String fullDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';

/// Reading plan: set one up, then read day by day with a streak.
class ReadingPlanScreen extends StatelessWidget {
  const ReadingPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.plan == null ? const _PlanSetup() : const _PlanToday();
  }
}

// ===================================================================== setup

class _PlanSetup extends StatefulWidget {
  const _PlanSetup();

  @override
  State<_PlanSetup> createState() => _PlanSetupState();
}

class _PlanSetupState extends State<_PlanSetup> {
  int _step = 0;
  PlanScope _scope = PlanScope.bible;
  PlanLength _length = PlanLength.quarter;
  DateTime _start = dateOnly(DateTime.now());
  late ReminderPrefs _prefs = AppScope.read(context).reminderPrefs;

  void _back() => _step == 0 ? Navigator.maybePop(context) : setState(() => _step--);

  Future<void> _pickDate() async {
    final now = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = dateOnly(d));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _prefs.morningHour, minute: _prefs.morningMinute));
    if (t != null) setState(() => _prefs = _prefs.copyWith(morningHour: t.hour, morningMinute: t.minute, morning: true));
  }

  Future<void> _startPlan() async {
    await AppScope.read(context).startPlan(ReadingPlan(scope: _scope, length: _length, start: _start), _prefs);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _back)),
        body: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.paddingOf(context).bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
              label: 'Step ${_step + 1} of 3',
              child: Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step ? t.colorScheme.primary : BethelTokens.of(context).hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(_step), child: [_lengthStep, _dateStep, _remindStep][_step](t)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _heading(ThemeData t, String title, [String? sub]) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: t.textTheme.headlineMedium?.copyWith(height: 1.2)),
        if (sub != null) ...[const SizedBox(height: 8), Text(sub, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))],
      ]);

  Widget _lengthStep(ThemeData t) {
    final tk = BethelTokens.of(context);
    final chapters = _scope == PlanScope.bible ? '1,189' : '260';
    return ListView(children: [
      _heading(t, 'How long would you like to take to read ${_scope == PlanScope.bible ? 'the whole Bible' : 'the New Testament'}?',
          '$chapters chapters. You can change this later.'),
      const SizedBox(height: 20),
      for (final l in PlanLength.forScope(_scope)) ...[
        Builder(builder: (_) {
          final (perDay, minutes) = ReadingPlan.pace(_scope, l);
          final selected = l == _length;
          final per = perDay >= 10 ? 'About ${perDay.round()} chapters a day' : '${perDay.floor()} or ${perDay.ceil()} chapters a day';
          final time = minutes >= 90 ? '${(minutes / 60).toStringAsFixed(minutes % 60 >= 30 ? 1 : 0)} hrs' : '$minutes min';
          return Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() {
                _length = l;
                _step = 1;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tk.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? t.colorScheme.primary : tk.hairline, width: selected ? 2 : 1),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.label, style: t.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(per, style: t.textTheme.bodySmall),
                    ]),
                  ),
                  Text('$time\na day', textAlign: TextAlign.right, style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
      TextButton(
        onPressed: () => setState(() {
          _scope = _scope == PlanScope.bible ? PlanScope.newTestament : PlanScope.bible;
          if (!PlanLength.forScope(_scope).contains(_length)) _length = PlanLength.quarter;
        }),
        child: Text(_scope == PlanScope.bible ? 'Just the New Testament' : 'The whole Bible instead'),
      ),
    ]);
  }

  Widget _dateStep(ThemeData t) {
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final monday = today.add(Duration(days: (8 - today.weekday) % 7 == 0 ? 7 : (8 - today.weekday) % 7));
    final firstOfMonth = DateTime(today.year, today.month + 1, 1);
    final plan = ReadingPlan(scope: _scope, length: _length, start: _start);
    Widget chip(String label, DateTime d) => ChoiceChip(
          label: Text(label),
          selected: _start == d,
          showCheckmark: false,
          onSelected: (_) => setState(() => _start = d),
        );
    final custom = ![today, tomorrow, monday, firstOfMonth].contains(_start);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(t, 'When do you want to start?'),
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: [
        chip('Today', today),
        chip('Tomorrow', tomorrow),
        chip('Monday, ${_months[monday.month - 1].substring(0, 3)} ${monday.day}', monday),
        if (firstOfMonth != monday) chip('${_months[firstOfMonth.month - 1].substring(0, 3)} 1', firstOfMonth),
        ActionChip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(custom ? longDate(_start) : 'Pick a date'),
          onPressed: _pickDate,
        ),
      ]),
      const Spacer(),
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Starts '),
          TextSpan(text: longDate(plan.start), style: const TextStyle(fontWeight: FontWeight.w500)),
          const TextSpan(text: '. You’ll finish on '),
          TextSpan(text: fullDate(plan.end), style: const TextStyle(fontWeight: FontWeight.w500)),
          const TextSpan(text: '.'),
        ]),
        textAlign: TextAlign.center,
        style: t.textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => setState(() => _step = 2), child: const Text('Continue')),
    ]);
  }

  Widget _remindStep(ThemeData t) {
    final tk = BethelTokens.of(context);
    final plan = ReadingPlan(scope: _scope, length: _length, start: _start);
    final (_, minutes) = ReadingPlan.pace(_scope, _length);
    final time = TimeOfDay(hour: _prefs.morningHour, minute: _prefs.morningMinute).format(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(t, 'When should we remind you?', 'Reminders only come when there’s something left to read.'),
      const SizedBox(height: 12),
      _ReminderRow(
        icon: Icons.schedule_rounded,
        title: 'Morning reminder',
        subtitle: 'If you haven’t started yet',
        value: _prefs.morning,
        onChanged: (v) => setState(() => _prefs = _prefs.copyWith(morning: v)),
        extra: TextButton(onPressed: _pickTime, child: Text(time)),
      ),
      _ReminderRow(
        icon: Icons.notifications_none_rounded,
        title: 'Nudge if I’m partway',
        subtitle: 'Early afternoon, only if part is left',
        value: _prefs.partway,
        onChanged: (v) => setState(() => _prefs = _prefs.copyWith(partway: v)),
      ),
      _ReminderRow(
        icon: Icons.local_fire_department_outlined,
        title: 'Protect my streak',
        subtitle: 'Evening, only if nothing is read',
        value: _prefs.streak,
        onChanged: (v) => setState(() => _prefs = _prefs.copyWith(streak: v)),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: tk.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: tk.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your plan', style: t.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text('${plan.scope == PlanScope.bible ? 'Whole Bible' : 'New Testament'} in ${_length.label}', style: t.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${longDate(plan.start)} to ${fullDate(plan.end)} · about $minutes minutes a day', style: t.textTheme.bodySmall),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _startPlan, child: const Text('Start my plan')),
    ]);
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged, this.extra});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: BethelTokens.of(context).hairline))),
      child: Row(children: [
        Icon(icon, size: 22, color: t.colorScheme.onSurfaceVariant),
        const SizedBox(width: 16),
        Expanded(
          child: MergeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.textTheme.titleSmall),
              Text(subtitle, style: t.textTheme.bodySmall),
            ]),
          ),
        ),
        if (extra != null && value) extra!,
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// ===================================================================== today

class _PlanToday extends StatefulWidget {
  const _PlanToday();

  @override
  State<_PlanToday> createState() => _PlanTodayState();
}

class _PlanTodayState extends State<_PlanToday> {
  /// The plan day on screen: today, or an earlier day being caught up.
  int? _viewDay;

  Future<void> _celebrate(PlanMessage? m) async {
    if (m == null || !mounted) return;
    final state = AppScope.read(context);
    await showPlanCelebration(context, m, streak: state.planProgress.streak(DateTime.now()));
  }

  void _toggle(int day, int i, bool done) => _celebrate(AppScope.read(context).setReading(day, i, done));

  void _read(Reading r) {
    AppScope.read(context).openBible(r.book, r.from);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BibleReaderScreen()));
  }

  Future<void> _menu(String v) async {
    final state = AppScope.read(context);
    if (v == 'all') {
      final day = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const _PlanOverview()));
      if (day != null) setState(() => _viewDay = day);
    } else if (v == 'reminders') {
      showBethelSheet<void>(context, builder: (_) => const _RemindersSheet());
    } else if (v == 'end') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start over?'),
          content: const Text('This ends your current plan and clears its progress. Your streak history is cleared too.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: BethelTokens.of(ctx).error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End plan'),
            ),
          ],
        ),
      );
      if (yes == true) state.endPlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final plan = state.plan!;
    final progress = state.planProgress;
    final now = DateTime.now();
    final today = plan.dayFor(now);
    final viewing = (_viewDay ?? today).clamp(1, plan.days);
    final readings = plan.readingsFor(viewing);
    final done = progress.doneCount(plan, viewing);
    final complete = done == readings.length;
    final streak = progress.streak(now);
    final behind = progress.behind(plan, now);
    final notStarted = today < 1;
    final finished = today > plan.days && progress.completedDays(plan) == plan.days;
    final catchingUp = viewing != today && !notStarted;
    final headline = notStarted
        ? 'Starts ${longDate(plan.start)}'
        : finished
            ? 'Plan complete'
            : complete
                ? (catchingUp ? 'Day $viewing is done' : 'All done for today')
                : readings.length - done == 1
                    ? 'One reading left'
                    : done == 0
                        ? '${numberWord(readings.length)} readings today'
                        : '${numberWord(readings.length - done)} readings left';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading plan'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('Whole plan')),
              PopupMenuItem(value: 'reminders', child: Text('Reminders')),
              PopupMenuItem(value: 'end', child: Text('End plan')),
            ],
          ),
        ],
      ),
      body: ListView(padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom), children: [
        Row(children: [
          PlanRing(done: done, total: readings.length),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notStarted ? '${plan.scope.label} in ${plan.length.label}' : 'Day $viewing of ${plan.days} · ${longDate(plan.dateOfDay(viewing))}',
                  style: t.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(headline, style: t.textTheme.headlineSmall?.copyWith(height: 1.2)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.local_fire_department_outlined, size: 16, color: tk.brassText),
                const SizedBox(width: 4),
                Text(streak == 0 ? 'Start a streak today' : '$streak-day streak', style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
              ]),
            ]),
          ),
        ]),
        if (catchingUp) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _viewDay = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to today'),
            ),
          ),
        ] else if (behind.isNotEmpty && !notStarted) ...[
          const SizedBox(height: 16),
          Material(
            color: tk.raised,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _viewDay = behind.first),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Icon(Icons.history_rounded, size: 20, color: tk.brassText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      behind.length == 1 ? 'Day ${behind.first} isn’t finished yet' : '${behind.length} earlier days aren’t finished yet',
                      style: t.textTheme.bodyMedium,
                    ),
                  ),
                  Text('Catch up', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
                ]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < readings.length; i++)
          _ReadingRow(
            reading: readings[i],
            done: progress.isDone(viewing, i),
            enabled: !notStarted,
            onToggle: (v) => _toggle(viewing, i, v),
            onOpen: () => _read(readings[i]),
          ),
        const SizedBox(height: 20),
        PlanWeekStrip(progress: progress, now: now),
        const SizedBox(height: 24),
        if (!notStarted && !complete)
          FilledButton(
            onPressed: () => _celebrate(state.markDay(viewing)),
            child: Text(catchingUp ? 'Mark day $viewing as read' : 'Mark today as read'),
          ),
        const SizedBox(height: 8),
        Text(
          notStarted
              ? 'Day 1: ${plan.readingsFor(1).map((r) => r.label).join(', ')}'
              : complete && viewing < plan.days
                  ? 'Next: ${plan.readingsFor(viewing + 1).map((r) => r.label).join(', ')}'
                  : complete
                      ? 'That was the last day.'
                      : 'Or tick each reading as you finish it. Tap a reading to open it.',
          textAlign: TextAlign.center,
          style: t.textTheme.bodySmall,
        ),
      ]),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.reading, required this.done, required this.enabled, required this.onToggle, required this.onOpen});
  final Reading reading;
  final bool done;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
      child: Row(children: [
        Semantics(
          checked: done,
          label: '${reading.label}, ${done ? 'read' : 'not read'}',
          onTap: enabled ? () => onToggle(!done) : null,
          excludeSemantics: true,
          child: InkWell(
            onTap: enabled ? () => onToggle(!done) : null,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 64,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? t.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: done ? null : Border.all(color: tk.hairline, width: 1.5),
                  ),
                  child: done ? Icon(Icons.check_rounded, size: 18, color: t.colorScheme.onPrimary) : null,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(reading.label,
                        style: t.textTheme.titleMedium?.copyWith(
                          color: done ? t.colorScheme.onSurfaceVariant : null,
                          decoration: done ? TextDecoration.lineThrough : null,
                        )),
                    Text('${reading.chapters} ${reading.chapters == 1 ? 'chapter' : 'chapters'} · about ${reading.minutes} min',
                        style: t.textTheme.bodySmall),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Progress ring with "2/3" in the middle.
class PlanRing extends StatelessWidget {
  const PlanRing({super.key, required this.done, required this.total, this.size = 72});
  final int done;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final frac = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: '$done of $total read',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: frac),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(v, BethelTokens.of(context).hairline, t.colorScheme.primary),
            ),
          ),
          ExcludeSemantics(child: Text('$done/$total', style: t.textTheme.titleLarge)),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.track, this.color);
  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    if (value > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

/// This week, Monday to Sunday: ticked days, today ringed in brass.
class PlanWeekStrip extends StatelessWidget {
  const PlanWeekStrip({super.key, required this.progress, required this.now});
  final PlanProgress progress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final today = dateOnly(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final dates = progress.readDates;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (var i = 0; i < 7; i++)
        Builder(builder: (_) {
          final d = monday.add(Duration(days: i));
          final read = dates.contains(dateKey(d));
          final isToday = d == today;
          final future = d.isAfter(today);
          return Semantics(
            label: '${_weekdays[i]}${read ? ', read' : future ? '' : ', not read'}',
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: read ? t.colorScheme.primary : Colors.transparent,
                border: read ? null : Border.all(color: isToday ? BethelColors.brass : tk.hairline, width: isToday ? 1.5 : 1),
              ),
              child: read
                  ? Icon(Icons.check_rounded, size: 16, color: t.colorScheme.onPrimary)
                  : Text(letters[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: future ? t.colorScheme.onSurfaceVariant : t.colorScheme.onSurface)),
            ),
          );
        }),
    ]);
  }
}

/// The "you did it" moment. The message is written from the day itself.
Future<void> showPlanCelebration(BuildContext context, PlanMessage m, {required int streak}) {
  final t = Theme.of(context);
  final tk = BethelTokens.of(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: tk.scrim,
    transitionDuration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 320),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
    ),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: t.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: BethelColors.forest, shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department_rounded, size: 30, color: BethelColors.brassLight),
              ),
              const SizedBox(height: 12),
              if (streak > 0) Text(streak == 1 ? 'Your streak begins' : '$streak days in a row', style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
              const SizedBox(height: 8),
              Text(m.title, textAlign: TextAlign.center, style: t.textTheme.headlineSmall?.copyWith(height: 1.25)),
              const SizedBox(height: 8),
              Text(m.body, textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              if (m.verse != null) ...[
                const SizedBox(height: 8),
                Text(m.verse!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.body, color: t.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: '${m.title} ${m.body}\n\n${m.verse ?? ''}')),
                    child: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
}

class _RemindersSheet extends StatelessWidget {
  const _RemindersSheet();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final p = state.reminderPrefs;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Reminders', style: t.textTheme.headlineSmall),
      const SizedBox(height: 8),
      _ReminderRow(
        icon: Icons.schedule_rounded,
        title: 'Morning reminder',
        subtitle: TimeOfDay(hour: p.morningHour, minute: p.morningMinute).format(context),
        value: p.morning,
        onChanged: (v) => state.setReminderPrefs(p.copyWith(morning: v)),
        extra: TextButton(
          onPressed: () async {
            final tod = await showTimePicker(context: context, initialTime: TimeOfDay(hour: p.morningHour, minute: p.morningMinute));
            if (tod != null) state.setReminderPrefs(p.copyWith(morningHour: tod.hour, morningMinute: tod.minute));
          },
          child: const Text('Change'),
        ),
      ),
      _ReminderRow(
        icon: Icons.notifications_none_rounded,
        title: 'Nudge if I’m partway',
        subtitle: 'Early afternoon, only if part is left',
        value: p.partway,
        onChanged: (v) => state.setReminderPrefs(p.copyWith(partway: v)),
      ),
      _ReminderRow(
        icon: Icons.local_fire_department_outlined,
        title: 'Protect my streak',
        subtitle: 'Evening, only if nothing is read',
        value: p.streak,
        onChanged: (v) => state.setReminderPrefs(p.copyWith(streak: v)),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

/// Every day of the plan, ticked or not. Tapping a day opens it.
class _PlanOverview extends StatelessWidget {
  const _PlanOverview();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final plan = state.plan!;
    final today = plan.dayFor(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text('${plan.length.label} plan')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: plan.days,
        itemBuilder: (_, i) {
          final day = i + 1;
          final complete = state.planProgress.dayComplete(plan, day);
          final isToday = day == today;
          return HairlineRow(
            leading: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete ? t.colorScheme.primary : Colors.transparent,
                border: complete ? null : Border.all(color: isToday ? BethelColors.brass : BethelTokens.of(context).hairline, width: isToday ? 1.5 : 1),
              ),
              child: complete
                  ? Icon(Icons.check_rounded, size: 18, color: t.colorScheme.onPrimary)
                  : Text('$day', style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurface)),
            ),
            title: plan.readingsFor(day).map((r) => r.label).join(', '),
            subtitle: '${isToday ? 'Today' : longDate(plan.dateOfDay(day))} · Day $day',
            onTap: day <= math.max(today, 1) ? () => Navigator.pop(context, day) : null,
          );
        },
      ),
    );
  }
}
