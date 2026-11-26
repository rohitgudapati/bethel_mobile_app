import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../bible/bible_text.dart';
import '../bible/books.dart';
import '../notes/note.dart';
import '../widgets/common.dart';

const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _shortDate(DateTime d) => d.year == DateTime.now().year ? '${_mon[d.month - 1]} ${d.day}' : '${_mon[d.month - 1]} ${d.day}, ${d.year}';

/// Notes from sermons and Bible reading, filterable by speaker, date and passage.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  NoteFilter _filter = const NoteFilter();
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final f = await showModalBottomSheet<NoteFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (f != null) setState(() => _filter = f.copyWith(query: _filter.query));
  }

  void _edit([Note? note]) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)));

  String _dateLabel(NoteFilter f) {
    if (f.from == null) return 'Date';
    final from = f.from!, to = f.to ?? DateTime.now();
    return '${_shortDate(from)} – ${_shortDate(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final all = [...state.notes]..sort((a, b) => b.date.compareTo(a.date) != 0 ? b.date.compareTo(a.date) : b.updated.compareTo(a.updated));
    final shown = all.where(_filter.matches).toList();
    final filtered = !_filter.isEmpty;
    final summary = [
      if (_filter.speaker != null) 'from ${_filter.speaker}',
      if (_filter.from != null) _dateLabel(_filter),
      if (_filter.book != null) 'in ${_filter.book}',
    ].join(' · ');
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search notes', filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
              )
            : const Text('Notes'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search notes',
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _search.clear();
                _filter = _filter.copyWith(query: '');
              }
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: t.filledButtonTheme.style?.backgroundColor?.resolve({}),
        foregroundColor: t.filledButtonTheme.style?.foregroundColor?.resolve({}),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New note'),
      ),
      body: Column(children: [
        if (all.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter.speaker == null && _filter.from == null && _filter.book == null,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = NoteFilter(query: _filter.query)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.person_outline_rounded, size: 16),
                label: Text(_filter.speaker ?? 'Speaker'),
                selected: _filter.speaker != null,
                showCheckmark: false,
                onSelected: (_) => _openFilters(),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(_dateLabel(_filter)),
                selected: _filter.from != null,
                showCheckmark: false,
                onSelected: (_) => _openFilters(),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.menu_book_outlined, size: 16),
                label: Text(_filter.book ?? 'Passage'),
                selected: _filter.book != null,
                showCheckmark: false,
                onSelected: (_) => _openFilters(),
              ),
            ]),
          ),
        if (filtered && summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(children: [
              Expanded(child: Text('${shown.length} ${shown.length == 1 ? 'note' : 'notes'} $summary', style: t.textTheme.bodySmall)),
              TextButton(onPressed: () => setState(() => _filter = NoteFilter(query: _filter.query)), child: const Text('Clear')),
            ]),
          ),
        Expanded(
          child: all.isEmpty
              ? const BethelEmptyState(
                  icon: Icons.edit_note_rounded,
                  title: 'No notes yet',
                  message: 'Write down what you hear on Sunday or notice while reading. Add the speaker and date to find it later.',
                )
              : shown.isEmpty
                  ? BethelEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No notes match',
                      message: 'Try another speaker, date or word',
                      action: OutlinedButton(onPressed: () => setState(() => _filter = const NoteFilter()), child: const Text('Show all notes')),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _NoteRow(note: shown[i], onTap: () => _edit(shown[i])),
                    ),
        ),
      ]),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onTap});
  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final body = note.title.trim().isEmpty ? note.body.trim().split('\n').skip(1).join(' ') : note.body.trim().replaceAll('\n', ' ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(note.speaker.isEmpty ? (note.sermonId != null ? 'Sermon' : 'My note') : note.speaker, style: t.textTheme.bodySmall)),
            Text(_shortDate(note.date), style: t.textTheme.bodySmall),
          ]),
          const SizedBox(height: 4),
          Text(note.heading, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
          if (note.passage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note.passage, style: t.textTheme.bodySmall?.copyWith(color: tk.brassText)),
          ],
        ]),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final NoteFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late NoteFilter _f = widget.initial;
  String? _range; // which quick range is on

  void _quick(String key) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      if (_range == key) {
        _range = null;
        _f = _f.copyWith(clearDates: true);
        return;
      }
      _range = key;
      final from = switch (key) {
        'month' => DateTime(now.year, now.month, 1),
        'three' => DateTime(now.year, now.month - 2, 1),
        _ => DateTime(now.year, 1, 1),
      };
      _f = _f.copyWith(from: from, to: today);
    });
  }

  Future<void> _custom() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _f.from == null ? null : DateTimeRange(start: _f.from!, end: _f.to ?? now),
    );
    if (r != null) {
      setState(() {
        _range = 'custom';
        _f = _f.copyWith(from: r.start, to: r.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final speakers = state.noteSpeakers;
    final books = {
      for (final n in state.notes)
        if (parseBibleRef(n.passage) case final r?) bibleBooks[r.book].name
    }.toList();
    final count = state.notes.where(_f.matches).length;
    Widget label(String s) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text(s, style: t.textTheme.bodySmall));
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Filter notes', style: t.textTheme.headlineSmall),
        label('Speaker'),
        if (speakers.isEmpty)
          Text('Add a speaker to a note to filter by it.', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in speakers)
              ChoiceChip(
                label: Text(s),
                selected: _f.speaker == s,
                showCheckmark: false,
                onSelected: (on) => setState(() => _f = on ? _f.copyWith(speaker: s) : _f.copyWith(clearSpeaker: true)),
              ),
          ]),
        label('Date'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (k, l) in const [('month', 'This month'), ('three', 'Last 3 months'), ('year', 'This year')])
            ChoiceChip(label: Text(l), selected: _range == k, showCheckmark: false, onSelected: (_) => _quick(k)),
          ChoiceChip(
            avatar: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(_range == 'custom' && _f.from != null ? '${_shortDate(_f.from!)} – ${_shortDate(_f.to!)}' : 'Custom range'),
            selected: _range == 'custom',
            showCheckmark: false,
            onSelected: (_) => _custom(),
          ),
        ]),
        if (books.isNotEmpty) ...[
          label('Passage'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final b in books)
              ChoiceChip(
                label: Text(b),
                selected: _f.book == b,
                showCheckmark: false,
                onSelected: (on) => setState(() => _f = on ? _f.copyWith(book: b) : _f.copyWith(clearBook: true)),
              ),
          ]),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: count == 0 ? null : () => Navigator.pop(context, _f),
          child: Text(count == 0 ? 'No notes match' : 'Show $count ${count == 1 ? 'note' : 'notes'}'),
        ),
      ]),
    );
  }
}

/// Write or edit a note: title, then date, speaker and passage, then the text.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note, this.passage, this.speaker, this.date, this.title});
  final Note? note;

  /// Prefills for a new note, e.g. from selected Bible verses.
  final String? passage;
  final String? speaker;
  final DateTime? date;
  final String? title;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final _title = TextEditingController(text: widget.note?.title ?? widget.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  late DateTime _date = widget.note?.date ?? widget.date ?? DateTime.now();
  late String _speaker = widget.note?.speaker ?? widget.speaker ?? '';
  late String _passage = widget.note?.passage ?? widget.passage ?? '';
  late final String _id = widget.note?.id ?? AppState.newNoteId();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Note get _current => Note(
        id: _id,
        title: _title.text.trim(),
        body: _body.text,
        date: _date,
        speaker: _speaker.trim(),
        passage: _passage.trim(),
        sermonId: widget.note?.sermonId,
        updated: DateTime.now(),
      );

  bool get _changed {
    final n = widget.note;
    final c = _current;
    if (n == null) return !c.isEmpty;
    return n.title != c.title || n.body != c.body || n.speaker != c.speaker || n.passage != c.passage || n.date != c.date;
  }

  void _save() {
    final state = AppScope.read(context);
    final c = _current;
    if (c.isEmpty) {
      if (widget.note != null) state.deleteNote(_id);
      Navigator.pop(context);
      return;
    }
    state.saveNote(c);
    Navigator.pop(context);
    showBethelToast(context, widget.note == null ? 'Note saved' : 'Note updated', icon: Icons.check_rounded);
  }

  Future<bool> _confirmDiscard() async {
    if (!_changed) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('What you wrote since opening this note won’t be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BethelTokens.of(ctx).error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _delete() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('It can’t be brought back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BethelTokens.of(ctx).error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (r == true && mounted) {
      AppScope.read(context).deleteNote(_id);
      Navigator.pop(context);
      showBethelToast(context, 'Note deleted', icon: Icons.delete_outline_rounded);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(DateTime.now().year + 1));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickSpeaker() async {
    final r = await showBethelSheet<String>(context, builder: (_) => _SpeakerSheet(current: _speaker));
    if (r != null) setState(() => _speaker = r);
  }

  Future<void> _pickPassage() async {
    final r = await showBethelSheet<String>(context, builder: (_) => _PassageSheet(current: _passage));
    if (r != null) setState(() => _passage = r);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    Widget chip(IconData icon, String label, bool set, VoidCallback onTap) => ActionChip(
          avatar: Icon(icon, size: 16, color: set ? t.colorScheme.onSurface : t.colorScheme.onSurfaceVariant),
          label: Text(label, style: TextStyle(color: set ? t.colorScheme.onSurface : t.colorScheme.onSurfaceVariant)),
          onPressed: onTap,
        );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: () async {
              if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          leadingWidth: 88,
          actions: [
            if (widget.note != null) IconButton(tooltip: 'Delete note', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
            TextButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              style: t.textTheme.headlineMedium,
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: t.textTheme.headlineMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              chip(Icons.calendar_today_outlined, longDateShort(_date), true, _pickDate),
              chip(Icons.person_outline_rounded, _speaker.isEmpty ? 'Add speaker' : _speaker, _speaker.isNotEmpty, _pickSpeaker),
              chip(Icons.menu_book_outlined, _passage.isEmpty ? 'Add passage' : _passage, _passage.isNotEmpty, _pickPassage),
            ]),
            const SizedBox(height: 16),
            Divider(color: tk.hairline, height: 1),
            const SizedBox(height: 16),
            TextField(
              controller: _body,
              autofocus: widget.note == null && (widget.title?.isNotEmpty ?? false),
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.lead, height: 1.6, color: t.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Write your note',
                hintStyle: TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.lead, color: t.colorScheme.onSurfaceVariant),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String longDateShort(DateTime d) => '${_wd[d.weekday - 1]}, ${_shortDate(d)}';

class _SpeakerSheet extends StatefulWidget {
  const _SpeakerSheet({required this.current});
  final String current;

  @override
  State<_SpeakerSheet> createState() => _SpeakerSheetState();
}

class _SpeakerSheetState extends State<_SpeakerSheet> {
  late final _ctrl = TextEditingController(text: widget.current);
  late final Future<List<String>> _elders =
      AppScope.read(context).repo.elders().then((l) => l.map((e) => e.name).toList()).catchError((Object _) => <String>[]);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return FutureBuilder<List<String>>(
      future: _elders,
      builder: (context, snap) {
        final names = {...state.noteSpeakers, ...?snap.data}.toList();
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Speaker', style: t.textTheme.headlineSmall),
          const SizedBox(height: 12),
          TileField(
            controller: _ctrl,
            label: 'Speaker name',
            hint: 'Name',
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final n in names) ActionChip(label: Text(n), onPressed: () => Navigator.pop(context, n)),
            ]),
          ],
          const SizedBox(height: 16),
          Row(children: [
            if (widget.current.isNotEmpty) TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Remove')),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: const Text('Done')),
          ]),
        ]);
      },
    );
  }
}

class _PassageSheet extends StatefulWidget {
  const _PassageSheet({required this.current});
  final String current;

  @override
  State<_PassageSheet> createState() => _PassageSheetState();
}

class _PassageSheetState extends State<_PassageSheet> {
  late final _ctrl = TextEditingController(text: widget.current);
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _done() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      Navigator.pop(context, '');
      return;
    }
    final r = parseBibleRef(v) ?? parseBibleRef('$v:1');
    if (r == null) {
      setState(() => _error = 'Try a reference like John 3:16 or Psalm 23');
      return;
    }
    final whole = parseBibleRef(v) == null; // a chapter without verses
    final b = bibleBooks[r.book].name;
    Navigator.pop(context, whole ? '$b ${r.chapter}' : '$b ${r.chapter}:${r.from}${r.to > r.from ? '–${r.to}' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Passage', style: t.textTheme.headlineSmall),
      const SizedBox(height: 12),
      TileField(
        controller: _ctrl,
        label: 'Bible reference',
        hint: 'John 3:16',
        autofocus: true,
        errorText: _error,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _done(),
      ),
      const SizedBox(height: 16),
      Row(children: [
        if (widget.current.isNotEmpty) TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Remove')),
        const Spacer(),
        FilledButton(onPressed: _done, child: const Text('Done')),
      ]),
    ]);
  }
}
