import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show shareVerse;

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
                  color: t.brightness == Brightness.dark ? t.colorScheme.surfaceContainer : BethelColors.brassSoft,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: AsyncView<List<ChurchService>>(
        load: state.repo.services,
        builder: (context, list) => list.isEmpty
            ? const BethelEmptyState(
                icon: Icons.church_outlined, title: 'No services listed', message: 'Service times appear here once they’re added')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return HairlineRow(
                    leading: const RowIcon(Icons.church_outlined),
                    title: s.name,
                    subtitle: s.schedule.isEmpty ? null : s.schedule,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s))),
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
      appBar: AppBar(title: Text(service.name)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (service.schedule.isNotEmpty) Text(service.schedule, style: t.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(service.description, style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 32),
          const BethelSectionTitle('Request this service'),
          const SizedBox(height: 8),
          Text('For a home visit, special prayer or a family occasion. The church office will call you.',
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          _BookServiceForm(service: service),
        ],
      ),
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
  late final _phone = TextEditingController(text: AppScope.read(context).user?.phone ?? '');
  final _note = TextEditingController();
  bool _busy = false;
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _nameError = _name.text.trim().isEmpty ? 'Add your name' : null;
      _phoneError = _phone.text.replaceAll(RegExp(r'\D'), '').length < 10 ? 'Add a phone number so the office can call you' : null;
    });
    if (_nameError != null || _phoneError != null) return;
    setState(() => _busy = true);
    try {
      await AppScope.read(context)
          .repo
          .bookService(widget.service.id, name: _name.text.trim(), phone: _phone.text.trim(), note: _note.text.trim());
      if (!mounted) return;
      _note.clear();
      FocusScope.of(context).unfocus();
      showBethelToast(context, 'Request sent. The church office will call you.', icon: Icons.check_rounded);
    } catch (e) {
      if (mounted) showBethelToast(context, 'Couldn’t send your request. Try again.', icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TileField(
        controller: _name,
        label: 'Your name',
        hint: 'Full name',
        errorText: _nameError,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
      ),
      const SizedBox(height: 12),
      TileField(
        controller: _phone,
        label: 'Phone',
        hint: 'Phone number',
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        errorText: _phoneError,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_phoneError != null) setState(() => _phoneError = null);
        },
      ),
      const SizedBox(height: 12),
      TileField(controller: _note, label: 'Details', hint: 'Preferred date or details (optional)', minLines: 2, maxLines: 4),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy ? null : _send,
        child: _busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.filledButtonTheme.style?.foregroundColor?.resolve({})))
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
        load: () => _loadVerses(state),
        builder: (context, verses) => verses.isEmpty
            ? const BethelEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No past verses yet',
                message: 'Each day’s verse is saved here after the day ends',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: verses.length,
                itemBuilder: (_, i) => _VerseRow(verse: verses[i], today: DateUtils.isSameDay(verses[i].date, DateTime.now())),
              ),
      ),
    );
  }

  /// Today's verse first (the one on Home), then past days. Either source failing still shows the other.
  static Future<List<DailyVerse>> _loadVerses(AppState state) async {
    DailyVerse? today;
    var past = <DailyVerse>[];
    try {
      today = await state.repo.todayVerse();
    } catch (_) {}
    try {
      past = await state.repo.verseArchive();
    } catch (_) {
      if (today == null) rethrow;
    }
    final hasToday = today != null && past.any((v) => DateUtils.isSameDay(v.date, today!.date));
    return [if (today != null && !hasToday) today, ...past];
  }
}

/// One past verse: its picture, the day and reference, the words, and a share button.
class _VerseRow extends StatelessWidget {
  const _VerseRow({required this.verse, required this.today});
  final DailyVerse verse;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final day = today ? 'Today' : fmtShort(verse.date);
    final ref = verse.reference ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ((verse.image ?? '').isNotEmpty)
          BethelImage(verse.image!, width: 88, height: 88, radius: 12)
        else
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: BethelColors.forest, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.format_quote_rounded, color: BethelColors.brassLight, size: 32),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ref.isEmpty ? day : '$day · $ref', style: t.textTheme.bodySmall),
            if ((verse.text ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(verse.text!.trim(), maxLines: 4, overflow: TextOverflow.ellipsis, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.4)),
            ],
          ]),
        ),
        IconButton(
          tooltip: 'Share verse',
          onPressed: () => shareVerse(context, verse),
          icon: Icon(Icons.ios_share_rounded, size: 20, color: t.colorScheme.onSurfaceVariant),
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
        color: BethelColors.forest,
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
                        style: TextStyle(color: BethelColors.brassSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
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

/// Full-bleed photo with a round back button, for a ministry or an elder.
class _PhotoPage extends StatelessWidget {
  const _PhotoPage({required this.image, required this.height, required this.children});
  final String image;
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            BethelImage(image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.3],
                  colors: [Color(0x59000000), Color(0x00000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Semantics(
                button: true,
                label: 'Back',
                child: Material(
                  color: const Color(0xD9FFFFFF),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.maybePop(context),
                    child: const SizedBox(
                        width: 44, height: 44, child: Icon(Icons.arrow_back_rounded, color: BethelColors.ink)),
                  ),
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + MediaQuery.paddingOf(context).bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ]),
    );
  }
}

class MinistryDetailScreen extends StatelessWidget {
  const MinistryDetailScreen({super.key, required this.ministry});
  final Ministry ministry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final subject = Uri.encodeComponent('Interest in ${ministry.name}');
    return _PhotoPage(image: ministry.image, height: 300, children: [
      if (ministry.meets.isNotEmpty) Text(ministry.meets, style: t.textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(ministry.name, style: t.textTheme.headlineMedium),
      const SizedBox(height: 20),
      Text(ministry.info, style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
      const SizedBox(height: 24),
      // Opens an email to the church office, so the interest actually reaches someone.
      FilledButton(
        onPressed: () => openLink(context, 'mailto:info@bethelph.com?subject=$subject'),
        child: const Text('I’d like to get involved'),
      ),
    ]);
  }
}

/// The elders in a row: photo, name, role. Tapping one opens their page.
class EldersRow extends StatelessWidget {
  const EldersRow({super.key, required this.elders, this.padding = EdgeInsets.zero});
  final List<Elder> elders;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < elders.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Pressable(
              semanticLabel: '${elders[i].name}, ${elders[i].role}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ElderScreen(elder: elders[i]))),
              child: Row(children: [
                ClipOval(child: BethelImage(elders[i].image, width: 48, height: 48)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(elders[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(height: 1.3)),
                    Text(elders[i].role, style: t.textTheme.bodySmall),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class EldersScreen extends StatelessWidget {
  const EldersScreen({super.key, required this.intro});
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
          Text(intro, style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 12),
          for (final e in list)
            HairlineRow(
              leading: ClipOval(child: BethelImage(e.image, width: 44, height: 44)),
              title: e.name,
              subtitle: e.role,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ElderScreen(elder: e))),
            ),
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
    return _PhotoPage(image: elder.image, height: 340, children: [
      Text(elder.role, style: t.textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(elder.name, style: t.textTheme.headlineMedium),
      const SizedBox(height: 20),
      Text(elder.bio, style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
      const SizedBox(height: 24),
      Row(children: [
        if (tel.isNotEmpty) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => openLink(context, 'tel:$tel'),
              icon: const Icon(Icons.call_outlined, size: 18),
              label: const Text('Call'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => openLink(context, 'mailto:info@bethelph.com?subject=${Uri.encodeComponent('For ${elder.name}')}'),
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: const Text('Email'),
          ),
        ),
      ]),
    ]);
  }
}
