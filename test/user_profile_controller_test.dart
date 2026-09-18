import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/profile/application/user_profile_controller.dart';
import 'package:finovo/features/profile/domain/user_profile_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('user profile copyWith clears nullable avatar override', () {
    final profile = UserProfile(
      userId: 'user-1',
      displayName: 'Pawel',
      email: 'pawel@example.com',
      photoUrl: 'https://google.example/avatar.png',
      customPhotoUrl: 'https://storage.example/custom.png',
      createdAt: _createdAt,
      lastSignInAt: _updatedAt,
      updatedAt: _updatedAt,
    );

    final updated = profile.copyWith(customPhotoUrl: null);

    expect(updated.customPhotoUrl, isNull);
    expect(updated.photoUrl, 'https://google.example/avatar.png');
  });

  test('user profile controller saves sanitized profile', () async {
    final repository = _RecordingUserProfileRepository();
    final controller = UserProfileController(
      repository: repository,
      userId: 'user-1',
      fallbackDisplayName: 'Pawel',
      fallbackEmail: 'pawel@example.com',
      fallbackPhotoUrl: 'https://google.example/avatar.png',
    );

    await controller.save(
      _profile().copyWith(displayName: '  Pawel   Testowy  '),
    );

    expect(repository.lastUpdatedProfile?.displayName, 'Pawel Testowy');
    expect(controller.isSaving, isFalse);

    controller.dispose();
  });

  test(
    'user profile controller appends cache buster to custom avatar url',
    () async {
      final repository = _StreamingUserProfileRepository(
        _profile(customPhotoUrl: 'https://storage.example/custom.png'),
      );
      final controller = UserProfileController(
        repository: repository,
        userId: 'user-1',
        fallbackDisplayName: 'Pawel',
        fallbackEmail: 'pawel@example.com',
        fallbackPhotoUrl: 'https://google.example/avatar.png',
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        controller.photoUrl,
        'https://storage.example/custom.png?v=${_updatedAt.millisecondsSinceEpoch}',
      );

      controller.dispose();
    },
  );
}

final _createdAt = DateTime(2026, 1, 1);
final _updatedAt = DateTime(2026, 6, 3);

UserProfile _profile({String? customPhotoUrl}) {
  return UserProfile(
    userId: 'user-1',
    displayName: 'Pawel',
    email: 'pawel@example.com',
    photoUrl: 'https://google.example/avatar.png',
    customPhotoUrl: customPhotoUrl,
    createdAt: _createdAt,
    lastSignInAt: _updatedAt,
    updatedAt: _updatedAt,
  );
}

class _RecordingUserProfileRepository implements UserProfileRepository {
  UserProfile? lastUpdatedProfile;

  @override
  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {}

  @override
  Future<void> updateProfile({
    required String userId,
    required UserProfile profile,
  }) async {
    lastUpdatedProfile = profile;
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return const Stream<UserProfile?>.empty();
  }
}

class _StreamingUserProfileRepository implements UserProfileRepository {
  _StreamingUserProfileRepository(this.profile);

  final UserProfile profile;

  @override
  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {}

  @override
  Future<void> updateProfile({
    required String userId,
    required UserProfile profile,
  }) async {}

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return Stream<UserProfile?>.value(profile);
  }
}
