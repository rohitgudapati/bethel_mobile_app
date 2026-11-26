import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

const prayerCategories = ['Healing', 'Family', 'Work', 'Church', 'Thanksgiving', 'Other'];

/// Prayer tab: a verse, the prayer wall, and "Request prayer".
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late Future<List<PrayerRequest>> _wall = AppScope.read(context).repo.prayerWall();

  void _reload() {
    final wall = AppScope.read(context).repo.prayerWall();
    setState(() {
      _wall = wall;
    });
  }

  Future<void> _newRequest() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const PrayerRequestSheet(),
    );
    if (sent == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    // Its own messenger, so toasts from the wall show in this Scaffold and push the
    // Request prayer button up instead of covering it.
    return ScaffoldMessenger(
      child: Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequest,
        elevation: 2,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: t.filledButtonTheme.style?.backgroundColor?.resolve({}),
        foregroundColor: t.filledButtonTheme.style?.foregroundColor?.resolve({}),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Request prayer', style: TextStyle(fontSize: BethelType.body, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _wall.catchError((Object _) => <PrayerRequest>[]);
          },
          child: CustomScrollView(slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(children: [
                const ScreenTitle('Prayer'),
                const SizedBox(height: 20),
                Text('“In every thing by prayer and supplication with thanksgiving let your requests be made known unto God.”',
                    style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400, height: 1.45)),
                const SizedBox(height: 12),
                Text('Philippians 4:6 · KJV', style: t.textTheme.bodySmall),
                const SizedBox(height: 32),
                const BethelSectionTitle('Prayer wall'),
              ]),
            ),
            FutureBuilder<List<PrayerRequest>>(
              future: _wall,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
                }
                if (snap.hasError) {
                  return SliverToBoxAdapter(
                    child: BethelEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Couldn’t load the prayer wall',
                      message: 'Check your connection and try again. You can still send a request.',
                      action: OutlinedButton(onPressed: _reload, child: const Text('Try again')),
                    ),
                  );
                }
                final wall = snap.data ?? const <PrayerRequest>[];
                if (wall.isEmpty) {
                  return SliverToBoxAdapter(
                    child: BethelEmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'The wall is quiet right now',
                      message: !AppConfig.isDemo && !AppConfig.isFirebase
                          ? 'Requests the church shares will appear here once the church server supports listing them.'
                          : 'Requests the church shares will appear here. Yours can be the first.',
                    ),
                  );
                }
                return SliverPadding(
                  // Room for the Request prayer button.
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                  sliver: SliverList.builder(itemCount: wall.length, itemBuilder: (_, i) => PrayerCard(prayer: wall[i])),
                );
              },
            ),
          ]),
        ),
      ),
    ),
    );
  }
}

/// One request on the wall: name and category, the request, and "I prayed".
class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key, required this.prayer});
  final PrayerRequest prayer;

  void _pray(BuildContext context) {
    final state = AppScope.read(context);
    state.prayFor(prayer.id);
    final anonymous = prayer.name.trim().isEmpty || prayer.name == 'Anonymous';
    showBethelToast(context, anonymous ? 'Thank you for praying' : '${prayer.name} will see that you prayed',
        icon: Icons.favorite_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final prayed = state.prayedFor.contains(prayer.id);
    final count = prayer.prayedCount + (prayed ? 1 : 0);
    final color = prayed ? tk.brassText : t.colorScheme.primary;
    final onTap = prayed || prayer.isMine ? null : () => _pray(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text: prayer.name,
                style: TextStyle(fontSize: BethelType.body, fontWeight: FontWeight.w500, color: t.colorScheme.onSurface)),
            TextSpan(text: '  ·  ${prayer.category}'),
            if (prayer.isMine) const TextSpan(text: '  ·  Your request'),
          ]),
          style: t.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(prayer.request, style: t.textTheme.bodyMedium?.copyWith(height: 1.5)),
        const SizedBox(height: 4),
        // The label replaces the button's own semantics, so the tap action is given here too.
        Semantics(
          button: onTap != null,
          label: prayer.isMine
              ? (count == 0 ? 'Your request is on the prayer wall' : '$count praying for your request')
              : prayed
                  ? 'You prayed. $count praying'
                  : 'I prayed for ${prayer.name}. $count praying',
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(prayed ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                  prayer.isMine
                      ? (count == 0 ? 'Shared on the prayer wall' : '$count praying')
                      : '${prayed ? 'You prayed' : 'I prayed'} · $count',
                  style: TextStyle(fontSize: BethelType.caption, fontWeight: FontWeight.w500, color: color),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// "How can we pray for you?" sheet: category, request, share on the wall, then a sent state.
/// Members send under their account; guests add a name and a way to reach them.
class PrayerRequestSheet extends StatefulWidget {
  const PrayerRequestSheet({super.key});

  @override
  State<PrayerRequestSheet> createState() => _PrayerRequestSheetState();
}

class _PrayerRequestSheetState extends State<PrayerRequestSheet> {
  final _request = TextEditingController();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  String _category = prayerCategories.first;
  bool _share = true;
  bool _busy = false;
  bool _sent = false;
  String? _requestError;
  String? _nameError;
  String? _error;

  @override
  void dispose() {
    _request.dispose();
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  String _firstName(String name) => name.trim().split(RegExp(r'\s+')).first;

  Future<void> _send() async {
    final user = AppScope.read(context).user;
    setState(() {
      _requestError = _request.text.trim().length < 5 ? 'Write a few words so the team knows how to pray' : null;
      _nameError = user == null && _name.text.trim().isEmpty ? 'Add your name' : null;
      _error = null;
    });
    if (_requestError != null || _nameError != null) return;
    setState(() => _busy = true);
    try {
      final contact = _contact.text.trim();
      await AppScope.read(context).repo.submitPrayer(
            name: user?.name ?? _name.text.trim(),
            email: user?.email ?? (contact.contains('@') ? contact : ''),
            phone: user?.phone ?? (contact.contains('@') ? '' : contact),
            request: _request.text.trim(),
            category: _category,
            shareOnWall: _share,
          );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Couldn’t send your request. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final user = AppScope.of(context).user;
    return AnimatedSize(
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: _sent ? _sentView(t, user) : _form(t, user),
      ),
    );
  }

  Widget _sentView(ThemeData t, UserProfile? user) {
    final who = _firstName(user?.name ?? _name.text);
    final where = _share
        ? (who.isEmpty ? 'It’s on the prayer wall.' : 'It’s on the wall as $who.')
        : 'It stays private with the prayer team.';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: BethelColors.forest, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 28, color: BethelColors.ivory),
        ),
      ),
      const SizedBox(height: 20),
      Text('Request sent', textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Our prayer team will be praying with you this week. $where',
          textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Done')),
    ]);
  }

  Widget _form(ThemeData t, UserProfile? user) {
    final tk = BethelTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('How can we pray for you?', style: t.textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text('Our prayer team reads every request', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      Semantics(
        label: 'Category',
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in prayerCategories)
            ChoiceChip(
              label: Text(c),
              selected: _category == c,
              showCheckmark: false,
              onSelected: _busy ? null : (_) => setState(() => _category = c),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _request,
        enabled: !_busy,
        minLines: 4,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: BethelType.lead, height: 1.45),
        onChanged: (_) {
          if (_requestError != null) setState(() => _requestError = null);
        },
        decoration: InputDecoration(
          hintText: 'Your prayer request',
          errorText: _requestError,
          errorMaxLines: 2,
          enabledBorder: _requestError == null
              ? null
              : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tk.error, width: 2)),
        ),
      ),
      if (user == null) ...[
        const SizedBox(height: 12),
        TileField(
          controller: _name,
          label: 'Your name',
          hint: 'Your name',
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: 12),
        TileField(
          controller: _contact,
          label: 'Phone or email',
          hint: 'Phone or email (optional)',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Share on the prayer wall', style: t.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Only your first name is shown. Turn off to keep it private with the prayer team.', style: t.textTheme.bodySmall),
          ]),
        ),
        const SizedBox(width: 16),
        Switch(value: _share, onChanged: _busy ? null : (v) => setState(() => _share = v)),
      ]),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: tk.error)),
      ],
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy ? null : _send,
        child: _busy
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.filledButtonTheme.style?.foregroundColor?.resolve({})),
                ),
                const SizedBox(width: 12),
                const Text('Sending'),
              ])
            : const Text('Send request'),
      ),
    ]);
  }
}
