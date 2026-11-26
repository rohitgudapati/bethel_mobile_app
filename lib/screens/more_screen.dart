import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/church_content.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import '../bible/bible_text.dart';
import 'bible_reader_screen.dart';
import 'bible_screen.dart';
import 'church_screens.dart';
import 'events_screen.dart';

/// More tab: who's signed in, the elders, then everything else as a plain list.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // If the elders don't load, the rest of More still works; the elders row just hides.
  late final Future<List<Elder>> _elders =
      AppScope.read(context).repo.elders().catchError((Object _) => const <Elder>[]);

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _directions(BuildContext context) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open in Maps?'),
        content: const Text('${AppConfig.churchName}, ${AppConfig.churchAddress}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open')),
        ],
      ),
    );
    if (open == true && context.mounted) openLink(context, AppConfig.mapsUrl);
  }

  Future<void> _contact(BuildContext context, List<Elder> elders) {
    final t = Theme.of(context);
    return showBethelSheet<void>(
      context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Contact ${AppConfig.churchName}', style: t.textTheme.titleLarge),
        const SizedBox(height: 8),
        HairlineRow(
          leading: const RowIcon(Icons.mail_outline_rounded),
          title: 'Email info@bethelph.com',
          showChevron: false,
          onTap: () {
            Navigator.pop(ctx);
            openLink(context, 'mailto:info@bethelph.com');
          },
        ),
        for (final e in elders.where((e) => e.phone.isNotEmpty))
          HairlineRow(
            leading: const RowIcon(Icons.call_outlined),
            title: 'Call ${e.name}',
            subtitle: e.phone,
            showChevron: false,
            onTap: () {
              Navigator.pop(ctx);
              openLink(context, 'tel:${e.phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
            },
          ),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ]),
    );
  }

  Future<void> _appearance(BuildContext context) {
    final state = AppScope.read(context);
    final t = Theme.of(context);
    const options = [(ThemeMode.system, 'Match iPhone setting'), (ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')];
    return showBethelSheet<void>(
      context,
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Appearance', style: t.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final (mode, label) in options)
          HairlineRow(
            title: label,
            showChevron: false,
            trailing: state.themeMode == mode ? Icon(Icons.check_rounded, color: t.colorScheme.primary) : null,
            onTap: () {
              state.setThemeMode(mode);
              Navigator.pop(ctx);
            },
          ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your saved songs and notes stay in your account'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BethelTokens.of(ctx).error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) AppScope.read(context).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final user = state.user;
    final mode = switch (state.themeMode) { ThemeMode.light => 'Light', ThemeMode.dark => 'Dark', _ => 'Automatic' };
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<Elder>>(
        future: _elders,
        builder: (context, snap) {
          final elders = snap.data ?? const <Elder>[];
          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
          const ScreenTitle('More'),
          const SizedBox(height: 20),
          _Profile(user: user, onSignIn: state.signOut),
          if (elders.isNotEmpty) ...[
            const SizedBox(height: 32),
            BethelSectionTitle('Our elders', action: 'About', onAction: () => _push(context, const EldersScreen(intro: eldersIntro))),
            const SizedBox(height: 16),
            EldersRow(elders: elders.take(2).toList()),
          ],
          const SizedBox(height: 20),
          HairlineRow(leading: const RowIcon(Icons.groups_outlined), title: 'Ministries', onTap: () => _push(context, const MinistriesScreen())),
          HairlineRow(leading: const RowIcon(Icons.church_outlined), title: 'Services', onTap: () => _push(context, const ServicesScreen())),
          HairlineRow(leading: const RowIcon(Icons.event_outlined), title: 'Events', onTap: () => _push(context, const EventsScreen())),
          HairlineRow(
              leading: const RowIcon(Icons.menu_book_outlined),
              title: 'Bible',
              trailing: Text('${state.bibleVersion.short} · ${bibleRef(state.bibleBook, state.bibleChapter)}',
                  style: t.textTheme.bodySmall),
              onTap: () => _push(context, const BibleReaderScreen())),
          HairlineRow(
              leading: const RowIcon(Icons.event_note_outlined),
              title: 'Reading plan',
              onTap: () => _push(context, const BibleScreen())),
          HairlineRow(leading: const RowIcon(Icons.photo_library_outlined), title: 'Gallery', onTap: () => _push(context, const GalleryScreen())),
          HairlineRow(leading: const RowIcon(Icons.auto_stories_outlined), title: 'Books', onTap: () => _push(context, const BooksScreen())),
          HairlineRow(leading: const RowIcon(Icons.map_outlined), title: 'Directions', subtitle: AppConfig.churchAddress, onTap: () => _directions(context)),
          HairlineRow(leading: const RowIcon(Icons.mail_outline_rounded), title: 'Contact us', onTap: () => _contact(context, elders)),
          HairlineRow(
              leading: const RowIcon(Icons.notifications_none_rounded),
              title: 'Notifications',
              onTap: () => _push(context, const NotificationSettingsScreen())),
          HairlineRow(
            leading: const RowIcon(Icons.dark_mode_outlined),
            title: 'Appearance',
            trailing: Text(mode, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            onTap: () => _appearance(context),
          ),
          if (user != null)
            HairlineRow(
              leading: RowIcon(Icons.logout_rounded, color: tk.error),
              title: 'Sign out',
              titleStyle: t.textTheme.titleSmall?.copyWith(color: tk.error),
              showChevron: false,
              onTap: () => _signOut(context),
            ),
          const SizedBox(height: 24),
          Center(child: Text(AppConfig.isDemo ? 'Version 2.0 · Demo data' : 'Version 2.0', style: t.textTheme.bodySmall)),
        ]);
        },
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.user, required this.onSignIn});
  final UserProfile? user;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    final u = user;
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: u == null ? tk.raised : BethelColors.forest, shape: BoxShape.circle),
        child: u == null
            ? Icon(Icons.person_outline_rounded, color: t.colorScheme.onSurfaceVariant)
            : Text(u.name.trim().isEmpty ? '?' : u.name.trim().characters.first.toUpperCase(),
                style: const TextStyle(fontFamily: BethelFonts.display, fontSize: BethelType.title, color: BethelColors.ivory)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u == null ? 'Guest' : u.name, style: t.textTheme.titleSmall),
          Text(u == null ? 'Sign in to save songs, notes and comments' : u.contact, style: t.textTheme.bodySmall),
        ]),
      ),
      if (u == null) TextButton(onPressed: onSignIn, child: const Text('Sign in')),
    ]);
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const _details = {
    'Service reminders': 'An hour before Sunday worship and prayer meetings',
    'New messages': 'When a sermon or testimony is posted',
    'Prayer updates': 'When someone prays for your request',
    'Events': 'New events and changes to ones you’re going to',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        for (final e in _details.entries)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
            child: MergeSemantics(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: t.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(e.value, style: t.textTheme.bodySmall),
                  ]),
                ),
                const SizedBox(width: 16),
                Switch(value: state.notificationPrefs[e.key] ?? false, onChanged: (v) => state.setNotificationPref(e.key, v)),
              ]),
            ),
          ),
        const SizedBox(height: 16),
        Text('If these are on but nothing arrives, allow notifications for Bethel in iPhone Settings.', style: t.textTheme.bodySmall),
      ]),
    );
  }
}

class MinistriesScreen extends StatelessWidget {
  const MinistriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ministries')),
      body: AsyncView<List<Ministry>>(
        load: state.repo.ministries,
        builder: (context, list) => list.isEmpty
            ? const BethelEmptyState(icon: Icons.groups_outlined, title: 'No ministries listed', message: 'Ministries appear here once they’re added')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: list.length,
                itemBuilder: (_, i) => HairlineRow(
                  leading: const RowIcon(Icons.groups_outlined),
                  title: list[i].name,
                  subtitle: list[i].meets.isEmpty ? null : list[i].meets,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MinistryDetailScreen(ministry: list[i]))),
                ),
              ),
      ),
    );
  }
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: AsyncView<List<GalleryPicture>>(
        load: state.repo.pictures,
        builder: (context, pics) => pics.isEmpty
            ? const BethelEmptyState(icon: Icons.photo_library_outlined, title: 'No photos yet', message: 'Photos from church life appear here')
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: pics.length,
                itemBuilder: (_, i) => Pressable(
                  semanticLabel: pics[i].caption,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(pics[i].caption)),
                        body: Center(child: InteractiveViewer(child: BethelImage(pics[i].image, fit: BoxFit.contain))),
                      ),
                    ),
                  ),
                  child: BethelImage(pics[i].image, radius: 12),
                ),
              ),
      ),
    );
  }
}

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final tk = BethelTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: AsyncView<List<Book>>(
        load: state.repo.books,
        builder: (context, books) => books.isEmpty
            ? const BethelEmptyState(icon: Icons.auto_stories_outlined, title: 'No books yet', message: 'Books from the church library appear here')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                itemCount: books.length,
                itemBuilder: (_, i) {
                  final b = books[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tk.hairline))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      BethelImage(b.image, width: 64, height: 88, radius: 8),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.title, style: t.textTheme.titleMedium),
                          Text(b.author, style: t.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Text(b.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}
