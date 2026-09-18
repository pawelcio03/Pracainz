import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/subscription_repository.dart';

class SubscriptionsController extends ChangeNotifier {
  SubscriptionsController({required this.repository, required this.userId}) {
    _subscription = repository
        .watchSubscriptions(userId)
        .listen(
          (subscriptions) {
            _subscriptions = subscriptions;
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
  }

  final SubscriptionRepository repository;
  final String userId;
  late final StreamSubscription<List<SubscriptionPlan>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<SubscriptionPlan> _subscriptions = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<SubscriptionPlan> get subscriptions => _subscriptions;

  List<SubscriptionPlan> get activeSubscriptions =>
      _subscriptions.where((subscription) => subscription.isActive).toList();

  double get monthlyCommitment => activeSubscriptions.fold<double>(
    0,
    (sum, subscription) => sum + subscription.monthlyCost,
  );

  Future<void> save(SubscriptionPlan subscription) async {
    final sanitizedSubscription = FinanceInputSanitizer.sanitizeSubscription(
      subscription,
    );

    if (sanitizedSubscription.isPersisted) {
      await repository.updateSubscription(
        userId: userId,
        subscription: sanitizedSubscription,
      );
      return;
    }

    await repository.createSubscription(
      userId: userId,
      subscription: sanitizedSubscription,
    );
  }

  Future<void> delete(SubscriptionPlan subscription) {
    return repository.deleteSubscription(
      userId: userId,
      subscriptionId: subscription.id,
    );
  }

  Future<int> importSubscriptions(List<SubscriptionPlan> subscriptions) async {
    for (final subscription in subscriptions) {
      final sanitizedSubscription = FinanceInputSanitizer.sanitizeSubscription(
        subscription,
      );
      await repository.createSubscription(
        userId: userId,
        subscription: sanitizedSubscription,
      );
    }

    return subscriptions.length;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
