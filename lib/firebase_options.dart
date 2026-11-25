// Firebase project settings.
//
// Replace this file by running `flutterfire configure` once the Firebase
// project exists (see backend/README.md). Until then the values come from
// --dart-define flags, and the emulator build uses a demo project.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'),
        appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:000000000000:web:0000000000000000'),
        messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '000000000000'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-bethel'),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'demo-bethel.firebaseapp.com'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'demo-bethel.appspot.com'),
      );
}
