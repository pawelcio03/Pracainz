import '../../../models/finance_models.dart';

abstract class SubscriptionRepository {
  Stream<List<SubscriptionPlan>> watchSubscriptions(String userId);

  Future<void> createSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  });

  Future<void> updateSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  });

  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  });
}
