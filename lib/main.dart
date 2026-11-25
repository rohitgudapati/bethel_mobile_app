import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_state.dart';
import 'app/config.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'screens/shell.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (AppConfig.useFirebaseEmulator) {
      FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.emulatorHost, 8080);
      await FirebaseAuth.instance.useAuthEmulator(AppConfig.emulatorHost, 9099);
    }
  }
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
