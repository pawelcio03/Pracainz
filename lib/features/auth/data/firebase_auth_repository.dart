import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../domain/account_security_snapshot.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  static Future<void>? _googleInitialization;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<AccountSecuritySnapshot> getAccountSecuritySnapshot() async {
    final user = _requireCurrentUser();
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    final providerIds =
        refreshedUser.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return AccountSecuritySnapshot(
      email: refreshedUser.email?.trim() ?? '',
      emailVerified: refreshedUser.emailVerified,
      providerIds: providerIds,
      hasPasswordProvider: providerIds.contains('password'),
      hasGoogleProvider: providerIds.contains('google.com'),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = FinanceInputSanitizer.normalizeEmail(email);
    await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = FinanceInputSanitizer.normalizeEmail(email);
    final normalizedDisplayName = FinanceInputSanitizer.normalizeDisplayName(
      displayName,
    );
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    if (normalizedDisplayName.isNotEmpty) {
      await credential.user?.updateDisplayName(normalizedDisplayName);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = FinanceInputSanitizer.normalizeEmail(email);
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _requireCurrentUser();
    await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmailToCurrentUser() async {
    final snapshot = await getAccountSecuritySnapshot();
    if (!snapshot.hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'password-provider-unavailable',
        message: 'To konto nie korzysta z logowania haslem.',
      );
    }

    if (snapshot.email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Na koncie nie ma adresu e-mail do resetu hasla.',
      );
    }

    await _auth.sendPasswordResetEmail(email: snapshot.email);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _requireCurrentUser();
    final normalizedDisplayName = FinanceInputSanitizer.normalizeDisplayName(
      displayName,
    );
    await user.updateDisplayName(normalizedDisplayName);
    await user.reload();
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _requireCurrentUser();
    final snapshot = await getAccountSecuritySnapshot();
    if (!snapshot.hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'password-provider-unavailable',
        message: 'To konto nie korzysta z logowania haslem.',
      );
    }

    if (snapshot.email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Na koncie nie ma aktywnego adresu e-mail.',
      );
    }

    final normalizedNewEmail = FinanceInputSanitizer.normalizeEmail(newEmail);
    if (normalizedNewEmail == snapshot.email) {
      throw FirebaseAuthException(
        code: 'email-unchanged',
        message: 'Nowy adres e-mail jest taki sam jak obecny.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: snapshot.email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(normalizedNewEmail);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireCurrentUser();
    final snapshot = await getAccountSecuritySnapshot();
    if (!snapshot.hasPasswordProvider) {
      throw FirebaseAuthException(
        code: 'password-provider-unavailable',
        message: 'To konto nie korzysta z logowania haslem.',
      );
    }

    if (snapshot.email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Na koncie nie ma adresu e-mail do zmiany hasla.',
      );
    }

    if (newPassword.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Haslo jest zbyt slabe.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: snapshot.email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await _auth.signInWithPopup(provider);
      return;
    }

    await _initializeGoogleSignIn();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Nie udalo sie pobrac tokenu logowania Google.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      throw FirebaseAuthException(
        code: _mapGoogleExceptionCode(error),
        message: _mapGoogleExceptionMessage(error),
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    await _auth.signOut();
  }

  Future<void> _initializeGoogleSignIn() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize();
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Brak aktywnej sesji uzytkownika.',
      );
    }
    return user;
  }

  String _mapGoogleExceptionCode(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'google-sign-in-cancelled';
      case GoogleSignInExceptionCode.interrupted:
        return 'google-sign-in-interrupted';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'google-sign-in-misconfigured';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'google-sign-in-unavailable';
      case GoogleSignInExceptionCode.userMismatch:
        return 'google-sign-in-user-mismatch';
      case GoogleSignInExceptionCode.unknownError:
        return 'google-sign-in-failed';
    }
  }

  String _mapGoogleExceptionMessage(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Logowanie Google zostalo anulowane.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Logowanie Google zostalo przerwane. Sprobuj ponownie.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Logowanie Google nie jest jeszcze poprawnie skonfigurowane dla tej aplikacji.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Nie udalo sie otworzyc okna logowania Google.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Wybrane konto Google nie pasuje do aktywnej sesji.';
      case GoogleSignInExceptionCode.unknownError:
        return error.description ??
            'Wystapil nieznany blad podczas logowania Google.';
    }
  }
}
