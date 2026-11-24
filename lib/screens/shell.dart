import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'more_screen.dart';
import 'music_screen.dart';
import 'prayer_screen.dart';
import 'watch_screen.dart';

/// Bottom navigation: Home · Watch · Prayer · Music · More.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_AppShellState>()?.select(index);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        HomeScreen(),
        WatchScreen(),
        PrayerScreen(),
        MusicScreen(),
        MoreScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_rounded), label: 'Watch'),
          NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism),
              label: 'Prayer'),
          NavigationDestination(
              icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note_rounded), label: 'Music'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'More'),
        ],
      ),
    );
  }
}
