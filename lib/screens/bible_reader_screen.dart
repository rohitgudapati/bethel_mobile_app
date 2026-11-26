import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../bible/bible_text.dart';
import '../bible/books.dart';
import '../widgets/common.dart';

/// The Bible: one chapter at a time, KJV or Telugu, optionally both verse by verse.
/// Tap verses to highlight, copy, share or compare them.
class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final Set<int> _selected = {};

  String _key(AppState s, int verse) => '${s.bibleBook}:${s.bibleChapter}:$verse';

  void _go(AppState s, int book, int chapter) {
    setState(_selected.clear);
    s.openBible(book, chapter);
  }

  (int, int)? _prev(AppState s) {
    if (s.bibleChapter > 1) return (s.bibleBook, s.bibleChapter - 1);
    if (s.bibleBook > 0) return (s.bibleBook - 1, bibleBooks[s.bibleBook - 1].chapters);
    return null;
  }

  (int, int)? _next(AppState s) {
    if (s.bibleChapter < bibleBooks[s.bibleBook].chapters) return (s.bibleBook, s.bibleChapter + 1);
    if (s.bibleBook < 65) return (s.bibleBook + 1, 1);
    return null;
  }

  Future<String> _selectedText(AppState s, BibleVersion v) async {
    final verses = await BibleText.chapter(v, s.bibleBook, s.bibleChapter);
    final nums = _selected.toList()..sort();
    final text = nums.map((n) => nums.length > 1 ? '$n ${verses[n - 1]}' : verses[n - 1]).join(' ');
    return '“$text”\n${bibleRef(s.bibleBook, s.bibleChapter, verses: nums, telugu: v.telugu)} · ${v.short}';
  }

  Future<void> _copy(AppState s) async {
    await Clipboard.setData(ClipboardData(text: await _selectedText(s, s.bibleVersion)));
    if (!mounted) return;
    setState(_selected.clear);
    showBethelToast(context, 'Copied', icon: Icons.check_rounded);
  }

  Future<void> _share(AppState s) async {
    final text = await _selectedText(s, s.bibleVersion);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: text,
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  Future<void> _compare(AppState s) async {
    final nums = _selected.toList()..sort();
    final texts = {for (final v in BibleVersion.values) v: await _selectedText(s, v)};
    if (!mounted) return;
    final t = Theme.of(context);
    showBethelSheet<void>(
      context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(bibleRef(s.bibleBook, s.bibleChapter, verses: nums), style: t.textTheme.headlineSmall),
        for (final v in BibleVersion.values) ...[
          const SizedBox(height: 16),
          Text(v.name, style: t.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(texts[v]!.split('\n').first,
              style: TextStyle(
                  fontFamily: v.telugu ? BethelFonts.telugu : BethelFonts.display,
                  fontSize: v.telugu ? 17 : BethelType.lead,
                  height: v.telugu ? 1.7 : 1.5,
                  color: t.colorScheme.onSurface)),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }

  void _versions(AppState s) {
    showBethelSheet<void>(context, builder: (_) => const _VersionSheet());
  }

  void _textSize() {
    showBethelSheet<void>(context, builder: (_) => const _TextSizeSheet());
  }

  Future<void> _pick(AppState s) async {
    final picked = await Navigator.push<(int, int)>(
      context,
      MaterialPageRoute(builder: (_) => BiblePickerScreen(book: s.bibleBook, chapter: s.bibleChapter)),
    );
    if (picked != null && mounted) _go(s, picked.$1, picked.$2);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final book = bibleBooks[s.bibleBook];
    final prev = _prev(s), next = _next(s);
    final telugu = s.bibleVersion.telugu;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _pick(s),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(bibleRef(s.bibleBook, s.bibleChapter, telugu: telugu),
                    overflow: TextOverflow.ellipsis,
                    style: telugu ? t.appBarTheme.titleTextStyle?.copyWith(fontFamily: BethelFonts.telugu, fontSize: 18) : null),
              ),
              Icon(Icons.expand_more_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
            ]),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: OutlinedButton(
              onPressed: () => _versions(s),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(s.bibleParallel ? 'KJV + తెలుగు' : s.bibleVersion.short, style: const TextStyle(fontSize: BethelType.caption)),
                const Icon(Icons.expand_more_rounded, size: 16),
              ]),
            ),
          ),
          IconButton(tooltip: 'Text size', onPressed: _textSize, icon: const Icon(Icons.format_size_rounded)),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Builder(builder: (context) {
            final second = telugu ? BibleVersion.kjv : BibleVersion.te;
            final main = BibleText.ready(s.bibleVersion);
            final other = s.bibleParallel ? BibleText.ready(second) : null;
            if (main == null || (s.bibleParallel && other == null)) {
              return FutureBuilder<void>(
                future: Future.wait([BibleText.load(s.bibleVersion), if (s.bibleParallel) BibleText.load(second)]).then((_) {
                  if (mounted) setState(() {});
                }),
                builder: (context, snap) => snap.hasError
                    ? BethelEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'Couldn’t open the Bible',
                        message: 'Close it and open it again',
                        action: OutlinedButton(onPressed: () => setState(() {}), child: const Text('Try again')),
                      )
                    : const Center(child: CircularProgressIndicator()),
              );
            }
            final verses = main[s.bibleBook][s.bibleChapter - 1];
            final others = other?[s.bibleBook][s.bibleChapter - 1];
            return ListView.builder(
              key: PageStorageKey('${s.bibleBook}:${s.bibleChapter}'),
              padding: EdgeInsets.fromLTRB(24, 8, 24, _selected.isEmpty ? 24 : 120),
              itemCount: verses.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(children: [
                      Text(telugu ? book.teName : book.name,
                          textAlign: TextAlign.center,
                          style: telugu ? const TextStyle(fontFamily: BethelFonts.telugu, fontSize: 24) : t.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(telugu ? 'అధ్యాయము ${s.bibleChapter}' : 'Chapter ${s.bibleChapter}', style: t.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      const BrassRule(width: 24),
                    ]),
                  );
                }
                final n = i;
                return _VerseBlock(
                  number: n,
                  text: verses[n - 1],
                  telugu: telugu,
                  second: others?[n - 1],
                  scale: s.bibleScale,
                  selected: _selected.contains(n),
                  highlighted: s.highlights.contains(_key(s, n)),
                  onTap: () => setState(() => _selected.contains(n) ? _selected.remove(n) : _selected.add(n)),
                );
              },
            );
          }),
        ),
        if (_selected.isEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 4 + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: tk.hairline))),
            child: Row(children: [
              TextButton.icon(
                onPressed: prev == null ? null : () => _go(s, prev.$1, prev.$2),
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(prev == null ? '' : bibleRef(prev.$1, prev.$2)),
              ),
              Expanded(
                child: Text('Chapter ${s.bibleChapter} of ${book.chapters}',
                    textAlign: TextAlign.center, style: t.textTheme.bodySmall),
              ),
              TextButton(
                onPressed: next == null ? null : () => _go(s, next.$1, next.$2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(next == null ? '' : bibleRef(next.$1, next.$2)),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ]),
          )
        else
          _ActionBar(
            count: _selected.length,
            onHighlight: () {
              s.toggleHighlights(_selected.map((n) => _key(s, n)));
              setState(_selected.clear);
            },
            onCopy: () => _copy(s),
            onShare: () => _share(s),
            onCompare: () => _compare(s),
            onClear: () => setState(_selected.clear),
          ),
      ]),
    );
  }
}

class _VerseBlock extends StatelessWidget {
  const _VerseBlock({
    required this.number,
    required this.text,
    required this.telugu,
    required this.second,
    required this.scale,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });
  final int number;
  final String text;
  final bool telugu;
  final String? second;
  final double scale;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  TextStyle _style(BuildContext context, bool te, {bool muted = false}) {
    final t = Theme.of(context);
    return TextStyle(
      fontFamily: te ? BethelFonts.telugu : BethelFonts.display,
      fontSize: (te ? 17 : BethelType.title) * scale,
      height: te ? 1.75 : 1.6,
      color: muted ? t.colorScheme.onSurfaceVariant : t.colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tk = BethelTokens.of(context);
    final bg = selected
        ? BethelColors.brass.withValues(alpha: 0.32)
        : highlighted
            ? BethelColors.brass.withValues(alpha: 0.16)
            : Colors.transparent;
    return Semantics(
      selected: selected,
      label: 'Verse $number',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: selected ? const Border(left: BorderSide(color: BethelColors.brass, width: 2)) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, top: 2),
                  child: Text('$number',
                      style: TextStyle(fontSize: BethelType.caption * scale.clamp(0.9, 1.3), color: tk.brassText, height: 1)),
                ),
              ),
              TextSpan(text: text, style: _style(context, telugu)),
            ])),
            if (second != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(second!, style: _style(context, !telugu, muted: true).copyWith(fontSize: (!telugu ? 17 : 15.5) * scale)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.count,
    required this.onHighlight,
    required this.onCopy,
    required this.onShare,
    required this.onCompare,
    required this.onClear,
  });
  final int count;
  final VoidCallback onHighlight, onCopy, onShare, onCompare, onClear;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 20, color: BethelColors.ivory),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11, color: BethelColors.ivory)),
              ]),
            ),
          ),
        );
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: BethelColors.ink, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          action(Icons.border_color_outlined, 'Highlight', onHighlight),
          action(Icons.copy_rounded, 'Copy', onCopy),
          action(Icons.ios_share_rounded, 'Share', onShare),
          action(Icons.compare_arrows_rounded, 'Compare', onCompare),
          action(Icons.close_rounded, count == 1 ? 'Clear' : 'Clear $count', onClear),
        ]),
      ),
    );
  }
}

class _VersionSheet extends StatelessWidget {
  const _VersionSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Version', style: t.textTheme.headlineSmall),
      const SizedBox(height: 8),
      for (final v in BibleVersion.values)
        HairlineRow(
          leading: SizedBox(
            width: 56,
            child: Text(v.short,
                style: TextStyle(
                    fontFamily: v.telugu ? BethelFonts.telugu : BethelFonts.display,
                    fontSize: v.telugu ? 15 : BethelType.lead,
                    fontWeight: FontWeight.w500,
                    color: t.colorScheme.onSurface)),
          ),
          title: v.name,
          subtitle: 'Works offline',
          showChevron: false,
          trailing: s.bibleVersion == v ? Icon(Icons.check_rounded, color: t.colorScheme.primary) : null,
          onTap: () {
            s.setBibleVersion(v);
            Navigator.pop(context);
          },
        ),
      const SizedBox(height: 4),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show both, verse by verse'),
        subtitle: const Text('English and Telugu together'),
        value: s.bibleParallel,
        onChanged: s.setBibleParallel,
      ),
      Text('More versions (NKJV, NASB) are coming later.', style: t.textTheme.bodySmall),
      const SizedBox(height: 8),
    ]);
  }
}

class _TextSizeSheet extends StatelessWidget {
  const _TextSizeSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Text size', style: t.textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        const Text('A', style: TextStyle(fontFamily: BethelFonts.display, fontSize: 15)),
        Expanded(
          child: Slider(value: s.bibleScale, min: 0.8, max: 1.6, divisions: 8, onChanged: s.setBibleScale),
        ),
        const Text('A', style: TextStyle(fontFamily: BethelFonts.display, fontSize: 26)),
      ]),
      const SizedBox(height: 8),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
    ]);
  }
}

/// Pick a book (Old or New Testament), then a chapter.
class BiblePickerScreen extends StatefulWidget {
  const BiblePickerScreen({super.key, required this.book, required this.chapter});
  final int book;
  final int chapter;

  @override
  State<BiblePickerScreen> createState() => _BiblePickerScreenState();
}

class _BiblePickerScreenState extends State<BiblePickerScreen> {
  late bool _old = bibleBooks[widget.book].oldTestament;
  late int? _open = widget.book;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final books = bibleBooks.where((b) => b.oldTestament == _old).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Go to')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: UnderlineTabs(
            labels: const ['Old Testament', 'New Testament'],
            selected: _old ? 0 : 1,
            onSelected: (i) => setState(() => _old = i == 0),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: books.length,
            itemBuilder: (_, i) {
              final b = books[i];
              final open = _open == b.index;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                HairlineRow(
                  title: b.name,
                  subtitle: b.teName,
                  showChevron: false,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${b.chapters}', style: t.textTheme.bodySmall),
                    const SizedBox(width: 4),
                    Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: t.colorScheme.onSurfaceVariant),
                  ]),
                  onTap: () => setState(() => _open = open ? null : b.index),
                ),
                if (open)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: GridView.count(
                      crossAxisCount: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        for (var c = 1; c <= b.chapters; c++)
                          Material(
                            color: b.index == widget.book && c == widget.chapter ? t.colorScheme.primary : tk.raised,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.pop(context, (b.index, c)),
                              child: Center(
                                child: Text('$c',
                                    style: TextStyle(
                                        fontSize: BethelType.body,
                                        color: b.index == widget.book && c == widget.chapter
                                            ? t.colorScheme.onPrimary
                                            : t.colorScheme.onSurface)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}
