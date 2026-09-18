import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  const FirestoreUserProfileRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _user(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data() ?? const <String, dynamic>{};
      final now = DateTime.now();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      final lastSignInAt =
          (data['lastSignInAt'] as Timestamp?)?.toDate() ?? createdAt;
      final updatedAt =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? lastSignInAt;

      return UserProfile(
        userId: userId,
        displayName: data['displayName'] as String? ?? 'Uzytkownik',
        email: data['email'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        customPhotoUrl: data['customPhotoUrl'] as String?,
        createdAt: createdAt,
        lastSignInAt: lastSignInAt,
        updatedAt: updatedAt,
      );
    });
  }

  @override
  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {
    final reference = _user(userId);
    final snapshot = await reference.get();

    final normalizedName = displayName.trim().isEmpty
        ? _nameFromEmail(email)
        : FinanceInputSanitizer.normalizeDisplayName(displayName);
    final normalizedEmail = FinanceInputSanitizer.normalizeEmail(email);
    final normalizedPhotoUrl = FinanceInputSanitizer.normalizeOptionalUrl(
      photoUrl,
      fieldLabel: 'Avatar dostawcy',
    );

    if (!snapshot.exists) {
      await reference.set({
        'displayName': normalizedName,
        'email': normalizedEmail,
        ..._photoUrlField(normalizedPhotoUrl),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final currentName = data['displayName'] as String? ?? '';
    final currentEmail = data['email'] as String? ?? '';
    final currentPhotoUrl = FinanceInputSanitizer.normalizeOptionalUrl(
      data['photoUrl'] as String?,
      fieldLabel: 'Avatar dostawcy',
    );
    final normalizedCurrentName = currentName.trim();
    final currentEmailAlias = _nameFromEmail(
      currentEmail.trim().isEmpty ? normalizedEmail : currentEmail,
    );
    final shouldRefreshName =
        normalizedName.isNotEmpty &&
        (normalizedCurrentName.isEmpty ||
            (normalizedCurrentName == currentEmailAlias &&
                normalizedName != currentEmailAlias));

    await reference.set({
      'displayName': shouldRefreshName ? normalizedName : currentName,
      'email': normalizedEmail.isNotEmpty ? normalizedEmail : currentEmail,
      ..._photoUrlField(
        normalizedPhotoUrl != null && normalizedPhotoUrl != currentPhotoUrl
            ? normalizedPhotoUrl
            : null,
      ),
      'lastSignInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    final sanitizedProfile = FinanceInputSanitizer.sanitizeUserProfile(profile);
    final normalizedPhotoUrl = FinanceInputSanitizer.normalizeOptionalUrl(
      sanitizedProfile.customPhotoUrl,
      fieldLabel: 'Wlasny avatar',
    );

    await _user(userId).set({
      'displayName': sanitizedProfile.displayName.trim(),
      'email': sanitizedProfile.email.trim(),
      ..._customPhotoUrlField(normalizedPhotoUrl),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _user(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  String _nameFromEmail(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.contains('@')) {
      return normalizedEmail.split('@').first;
    }

    return 'Uzytkownik';
  }

  Map<String, dynamic> _photoUrlField(String? photoUrl) {
    if (photoUrl == null) {
      return const <String, dynamic>{};
    }

    return <String, dynamic>{'photoUrl': photoUrl};
  }

  Map<String, dynamic> _customPhotoUrlField(String? photoUrl) {
    if (photoUrl == null) {
      return <String, dynamic>{'customPhotoUrl': FieldValue.delete()};
    }

    return <String, dynamic>{'customPhotoUrl': photoUrl};
  }
}
