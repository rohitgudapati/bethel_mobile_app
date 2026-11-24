import 'package:flutter/material.dart';

import 'app/app_state.dart';
import 'app/config.dart';
import 'app/theme.dart';
import 'screens/shell.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(BethelApp(state: AppState()));
}

class BethelApp extends StatelessWidget {
  const BethelApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: AppConfig.churchName,
          debugShowCheckedModeBanner: false,
          theme: BethelTheme.light(),
          darkTheme: BethelTheme.dark(),
          themeMode: state.themeMode,
          home: state.signedIn ? const AppShell() : const WelcomeScreen(),
        ),
      ),
    );
  }
}
