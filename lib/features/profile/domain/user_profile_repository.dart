import '../../../models/finance_models.dart';

abstract class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);

  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  });

  Future<void> updateProfile({
    required String userId,
    required UserProfile profile,
  });
}
