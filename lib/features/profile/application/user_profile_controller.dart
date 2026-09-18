import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/user_profile_repository.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController({
    required this.repository,
    required this.userId,
    required this.fallbackDisplayName,
    required this.fallbackEmail,
    this.fallbackPhotoUrl,
  }) {
    _subscription = repository
        .watchProfile(userId)
        .listen(
          (profile) {
            _profile = profile;
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );

    unawaited(_ensureProfile());
  }

  final UserProfileRepository repository;
  final String userId;
  final String fallbackDisplayName;
  final String fallbackEmail;
  final String? fallbackPhotoUrl;
  late final StreamSubscription<UserProfile?> _subscription;

  bool _isLoading = true;
  bool _isSaving = false;
  Object? _error;
  UserProfile? _profile;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  Object? get error => _error;

  UserProfile? get profile => _profile;

  String get displayName {
    final profileName = _profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }

    final fallbackName = fallbackDisplayName.trim();
    if (fallbackName.isNotEmpty) {
      return fallbackName;
    }

    if (fallbackEmail.contains('@')) {
      return fallbackEmail.split('@').first;
    }

    return 'Uzytkownik';
  }

  String get email {
    final profileEmail = _profile?.email.trim();
    if (profileEmail != null && profileEmail.isNotEmpty) {
      return profileEmail;
    }

    return fallbackEmail.trim();
  }

  String? get photoUrl {
    final customProfilePhotoUrl = _profile?.customPhotoUrl?.trim();
    if (customProfilePhotoUrl != null && customProfilePhotoUrl.isNotEmpty) {
      final updatedAt = _profile?.updatedAt;
      if (updatedAt == null) {
        return customProfilePhotoUrl;
      }

      return _appendCacheBuster(
        customProfilePhotoUrl,
        updatedAt.millisecondsSinceEpoch.toString(),
      );
    }

    final profilePhotoUrl = _profile?.photoUrl?.trim();
    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return profilePhotoUrl;
    }

    final normalizedFallbackPhotoUrl = fallbackPhotoUrl?.trim();
    if (normalizedFallbackPhotoUrl != null &&
        normalizedFallbackPhotoUrl.isNotEmpty) {
      return normalizedFallbackPhotoUrl;
    }

    return null;
  }

  String _appendCacheBuster(String url, String version) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$version';
  }

  Future<void> save(UserProfile profile) async {
    final sanitizedProfile = FinanceInputSanitizer.sanitizeUserProfile(profile);

    _isSaving = true;
    notifyListeners();

    try {
      await repository.updateProfile(userId: userId, profile: sanitizedProfile);
      _error = null;
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> syncIdentity({String? displayName, String? email}) async {
    final currentProfile = _profile;
    if (currentProfile == null) {
      return;
    }

    final nextProfile = currentProfile.copyWith(
      displayName: displayName ?? currentProfile.displayName,
      email: email ?? currentProfile.email,
    );
    await repository.updateProfile(userId: userId, profile: nextProfile);
  }

  Future<void> _ensureProfile() async {
    try {
      await repository.ensureProfile(
        userId: userId,
        displayName: fallbackDisplayName,
        email: fallbackEmail,
        photoUrl: fallbackPhotoUrl,
      );
    } catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
