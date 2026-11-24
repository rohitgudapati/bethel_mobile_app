import 'package:flutter/material.dart';

import '../app/config.dart';
import '../app/theme.dart';
import '../widgets/common.dart';

class GiveScreen extends StatefulWidget {
  const GiveScreen({super.key});

  @override
  State<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends State<GiveScreen> {
  static const _amounts = [25, 50, 100, 250];
  static const _funds = ['Tithe', 'Offering', 'Missions', 'Building fund'];
  int? _amount = 50;
  final _custom = TextEditingController();
  String _fund = _funds.first;
  bool _monthly = false;

  String get _display {
    final a = _amount ?? int.tryParse(_custom.text) ?? 0;
    return a == 0 ? '\$—' : '\$$a';
  }

  void _continue() {
    if (AppConfig.givingUrl.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Secure checkout'),
          content: const Text(
            'In the live app this opens the church\'s secure Stripe checkout with the amount and fund filled in. '
            'Card details are entered on Stripe\'s page and never touch the app.\n\n'
            'Demo: no payment link has been configured yet.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    openLink(context, AppConfig.givingUrl);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Give')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [BethelColors.navy, BethelColors.navyDeep]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your generosity',
                style: TextStyle(color: BethelColors.goldSoft, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_display,
                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700, height: 1.15)),
            Text('$_fund · ${_monthly ? 'Every month' : 'One time'}',
                style: const TextStyle(color: Color(0xCCFFFFFF))),
            const SizedBox(height: 14),
            const Text('"God loveth a cheerful giver." 2 Corinthians 9:7',
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(height: 24),
        Text('Amount', style: t.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(children: [
          for (final a in _amounts) ...[
            Expanded(
              child: ChoiceChip(
                label: SizedBox(width: double.infinity, child: Text('\$$a', textAlign: TextAlign.center)),
                selected: _amount == a,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  _amount = a;
                  _custom.clear();
                }),
              ),
            ),
            if (a != _amounts.last) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _custom,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _amount = null),
          decoration: const InputDecoration(hintText: 'Other amount', prefixText: '\$ '),
        ),
        const SizedBox(height: 22),
        Text('Fund', style: t.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in _funds)
            ChoiceChip(
              label: Text(f),
              selected: _fund == f,
              showCheckmark: false,
              onSelected: (_) => setState(() => _fund = f),
            ),
        ]),
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _monthly,
          onChanged: (v) => setState(() => _monthly = v),
          title: const Text('Make this monthly', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('You can change or cancel any time.'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _continue,
          icon: const Icon(Icons.lock_rounded, size: 18),
          label: Text('Give $_display securely'),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.verified_user_outlined, size: 15, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text('Payments processed by Stripe', style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}
