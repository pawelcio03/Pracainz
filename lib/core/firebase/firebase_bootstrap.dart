import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult._({required this.isConfigured, this.message});

  const FirebaseBootstrapResult.ready() : this._(isConfigured: true);

  const FirebaseBootstrapResult.notConfigured([String? message])
    : this._(isConfigured: false, message: message);

  final bool isConfigured;
  final String? message;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      return const FirebaseBootstrapResult.ready();
    } on FirebaseException catch (error) {
      return FirebaseBootstrapResult.notConfigured(
        _firebaseErrorMessage(error),
      );
    } catch (error) {
      return FirebaseBootstrapResult.notConfigured(error.toString());
    }
  }

  static String _firebaseErrorMessage(FirebaseException error) {
    final code = error.code.toLowerCase();

    if (kIsWeb) {
      return 'Brakuje konfiguracji Firebase dla web. Dodaj opcje projektu przez flutterfire configure albo recznie z Firebase Console.';
    }

    if (code.contains('no-app') ||
        code.contains('options') ||
        code.contains('core')) {
      return 'Firebase nie jest jeszcze skonfigurowany dla tej platformy. Dodaj plik konfiguracyjny projektu i uruchom aplikacje ponownie.';
    }

    return error.message ?? 'Nie udalo sie zainicjalizowac Firebase.';
  }
}
