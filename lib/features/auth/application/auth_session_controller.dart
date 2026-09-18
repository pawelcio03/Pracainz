import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/auth_repository.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({required this.authRepository}) {
    _subscription = authRepository.authStateChanges().listen(
      (user) {
        _user = user;
        _error = null;
        _isReady = true;
        notifyListeners();
      },
      onError: (error) {
        _error = error;
        _isReady = true;
        notifyListeners();
      },
      onDone: () {
        if (_isReady) {
          return;
        }

        _isReady = true;
        notifyListeners();
      },
    );
  }

  final AuthRepository authRepository;
  late final StreamSubscription<User?> _subscription;

  bool _isReady = false;
  User? _user;
  Object? _error;

  bool get isLoading => !_isReady;

  User? get user => _user;

  Object? get error => _error;

  bool get isAuthenticated => _user != null;

  Future<void> signOut() => authRepository.signOut();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
