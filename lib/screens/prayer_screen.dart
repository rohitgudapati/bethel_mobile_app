import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';

const prayerCategories = ['Healing', 'Family', 'Work', 'Church', 'Thanksgiving', 'Other'];

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Key _reload = UniqueKey();

  Future<void> _newRequest() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const PrayerRequestSheet(),
    );
    if (added == true && mounted) {
      setState(() => _reload = UniqueKey());
      showToast(context, 'Your request was sent to our prayer team. We\'re praying with you.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequest,
        backgroundColor: BethelColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Request prayer', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Prayer', style: t.textTheme.headlineMedium),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BethelColors.navy,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('"In every thing by prayer… let your requests be made known unto God."',
                          style:
                              TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic)),
                      SizedBox(height: 8),
                      Text('Philippians 4:6',
                          style: TextStyle(color: BethelColors.goldSoft, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const BethelImage('assets/pray.png', width: 76, height: 96),
                  ),
                ]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader('Prayer wall')),
          if (!AppConfig.isDemo && !AppConfig.isFirebase)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('Requests shared by the church will appear here once the API supports listing them.',
                    style: TextStyle(fontSize: 13, color: t.colorScheme.onSurfaceVariant)),
              ),
            ),
          AsyncView<List<PrayerRequest>>(
            key: _reload,
            sliver: true,
            load: state.repo.prayerWall,
            builder: (context, wall) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList.separated(
                itemCount: wall.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => PrayerCard(prayer: wall[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key, required this.prayer});
  final PrayerRequest prayer;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final prayed = state.prayedFor.contains(prayer.id);
    final count = prayer.prayedCount + (prayed ? 1 : 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: t.colorScheme.surfaceContainer,
              child: Text(prayer.name == 'Anonymous' ? '?' : prayer.name[0],
                  style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prayer.isMine ? '${prayer.name} (you)' : prayer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(timeAgo(prayer.createdAt), style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
            Pill(prayer.category),
            const SizedBox(width: 8),
          ]),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(prayer.request, style: const TextStyle(fontSize: 14.5, height: 1.55)),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: Text(count == 1 ? '1 person prayed' : '$count people prayed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
            ),
            TextButton.icon(
              onPressed: prayed ? null : () => state.prayFor(prayer.id),
              icon: Icon(prayed ? Icons.check_rounded : Icons.volunteer_activism_outlined, size: 18),
              label: Text(prayed ? 'Prayed' : 'I prayed'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class PrayerRequestSheet extends StatefulWidget {
  const PrayerRequestSheet({super.key});

  @override
  State<PrayerRequestSheet> createState() => _PrayerRequestSheetState();
}

class _PrayerRequestSheetState extends State<PrayerRequestSheet> {
  late final _name = TextEditingController(text: AppScope.read(context).user?.name ?? '');
  late final _email = TextEditingController(text: AppScope.read(context).user?.email ?? '');
  final _phone = TextEditingController();
  final _request = TextEditingController();
  String _category = prayerCategories.first;
  bool _share = true;
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    if (_request.text.trim().length < 5) {
      setState(() => _error = 'Please share a little about what we can pray for.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).repo.submitPrayer(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            request: _request.text,
            category: _category,
            shareOnWall: _share,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('How can we pray for you?', style: t.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Our prayer team reads every request.', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in prayerCategories)
            ChoiceChip(
              label: Text(c),
              selected: _category == c,
              showCheckmark: false,
              onSelected: (_) => setState(() => _category = c),
            ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _request,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Share your prayer request…', alignLabelWithHint: true),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)')),
          ),
        ]),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _share,
          onChanged: (v) => setState(() => _share = v),
          title: const Text('Share on the prayer wall', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Only your first name is shown. Turn off to keep it private with the prayer team.'),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: t.colorScheme.error)),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
              : const Text('Send request'),
        ),
      ]),
    );
  }
}
