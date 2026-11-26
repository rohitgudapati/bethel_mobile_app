import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/theme.dart';
import 'bethel_ui.dart';

/// Bottom sheet for guests who try something that needs an account (saving a song, a note, a comment).
/// "Continue" goes back to the sign-in screen; "Not now" closes the sheet.
Future<void> showSignInPrompt(BuildContext context, {required String title, IconData icon = Icons.person_outline_rounded}) {
  final t = Theme.of(context);
  final tk = BethelTokens.of(context);
  return showBethelSheet<void>(
    context,
    builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: tk.raised, shape: BoxShape.circle),
          child: Icon(icon, color: t.colorScheme.primary),
        ),
      ),
      const SizedBox(height: 16),
      Text(title, textAlign: TextAlign.center, style: t.textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Saved songs, notes and comments need an account. Phone, Apple, Google or email all work.',
          textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () {
          Navigator.pop(ctx);
          Navigator.of(context).popUntil((r) => r.isFirst);
          AppScope.read(context).signOut();
        },
        child: const Text('Continue'),
      ),
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
    ]),
  );
}
