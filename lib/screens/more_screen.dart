import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'bible_screen.dart';
import 'church_screens.dart';
import 'events_screen.dart';
import 'shell.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    final user = state.user;
    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
        Text('More', style: t.textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: BethelColors.navy,
                child: Text(user?.initials ?? '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? 'Guest', style: t.textTheme.titleMedium),
                  Text(user?.email ?? 'Sign in to save songs, notes and RSVPs',
                      style: TextStyle(fontSize: 12.5, color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
              if (user == null)
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: state.signOut,
                  child: const Text('Sign in'),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.02,
          children: [
            _Tile(
                icon: Icons.groups_rounded, label: 'Ministries', onTap: () => _push(context, const MinistriesScreen())),
            _Tile(icon: Icons.event_rounded, label: 'Events', onTap: () => _push(context, const EventsScreen())),
            _Tile(icon: Icons.menu_book_rounded, label: 'Bible', onTap: () => _push(context, const BibleScreen())),
            _Tile(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _push(context, const GalleryScreen())),
            _Tile(icon: Icons.auto_stories_rounded, label: 'Books', onTap: () => _push(context, const BooksScreen())),
            _Tile(
                icon: Icons.directions_rounded, label: 'Directions', onTap: () => openLink(context, AppConfig.mapsUrl)),
            _Tile(icon: Icons.church_rounded, label: 'Services', onTap: () => _push(context, const ServicesScreen())),
            _Tile(
                icon: Icons.format_quote_rounded,
                label: 'Verses',
                onTap: () => _push(context, const VerseArchiveScreen())),
            _Tile(
                icon: Icons.photo_camera_back_rounded,
                label: 'Testimonies',
                onTap: () => AppShell.goToTab(context, AppShell.watch)),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: const Text('Plan a visit'),
              subtitle: const Text(AppConfig.churchAddress),
              trailing: const Icon(Icons.directions_rounded),
              onTap: () => openLink(context, AppConfig.mapsUrl),
            ),
            const Divider(indent: 16, endIndent: 16),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: state.themeMode == ThemeMode.dark,
              onChanged: (v) => state.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Notifications'),
              subtitle: const Text('Service reminders, new sermons, prayer updates'),
              onTap: () => showToast(context, 'Push notifications are set up with Firebase Cloud Messaging.'),
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(user == null ? 'Back to welcome' : 'Sign out'),
              onTap: state.signOut,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            AppConfig.isDemo ? 'Version 2.0 · Demo data' : 'Version 2.0',
            style: TextStyle(fontSize: 12, color: t.colorScheme.onSurfaceVariant),
          ),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ]),
        ),
      );
}

class MinistriesScreen extends StatelessWidget {
  const MinistriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ministries')),
      body: AsyncView<List<Ministry>>(
        load: state.repo.ministries,
        builder: (context, list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final m = list[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MinistryDetailScreen(ministry: m))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BethelImage(m.image, height: 150, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.name, style: t.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(m.info, style: TextStyle(color: t.colorScheme.onSurfaceVariant, height: 1.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        if (m.meets.isNotEmpty) Pill(m.meets, icon: Icons.schedule_rounded),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => MinistryDetailScreen(ministry: m))),
                          child: const Text('Learn more'),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            );
          },
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
        builder: (context, pics) => GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: pics.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                      backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(pics[i].caption)),
                  body: Center(child: InteractiveViewer(child: BethelImage(pics[i].image, fit: BoxFit.contain))),
                ),
              ),
            ),
            child: BethelImage(pics[i].image, radius: 16),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: AsyncView<List<Book>>(
        load: state.repo.books,
        builder: (context, books) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final b = books[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  BethelImage(b.image, width: 72, height: 96, radius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: t.textTheme.titleMedium),
                      Text(b.author, style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text(b.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showToast(context, 'Opens the book PDF from the API.'),
                          child: const Text('Read'),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
