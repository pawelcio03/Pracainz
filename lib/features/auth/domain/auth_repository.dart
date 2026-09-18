import 'package:firebase_auth/firebase_auth.dart';

import 'account_security_snapshot.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<AccountSecuritySnapshot> getAccountSecuritySnapshot();

  Future<void> sendEmailVerification();

  Future<void> sendPasswordResetEmailToCurrentUser();

  Future<void> updateDisplayName(String displayName);

  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();
}
