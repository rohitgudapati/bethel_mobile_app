import 'package:flutter/material.dart';

import '../app/launch.dart';
import '../app/theme.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'prayer_screen.dart';
import 'songs_screen.dart';
import 'watch_screen.dart';

/// Bottom navigation: Songs · Watch · Home (centre) · Prayer · More. Opens on Home.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const songs = 0, watch = 1, home = 2, prayer = 3, more = 4;

  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_AppShellState>()?.select(index);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = LaunchOptions.tabs.indexOf(LaunchOptions.startTab ?? 'home');

  void select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        SongsScreen(),
        WatchScreen(),
        HomeScreen(),
        PrayerScreen(),
        MoreScreen(),
      ]),
      // Flat tab bar with a hairline on top; Forest (Sage in dark mode) marks the selected tab.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: BethelTokens.of(context).hairline))),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: select,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music_rounded), label: 'Songs'),
            NavigationDestination(
                icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_rounded), label: 'Watch'),
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism),
                label: 'Prayer'),
            NavigationDestination(
                icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }
}
