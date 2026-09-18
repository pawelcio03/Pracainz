import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/subscription_repository.dart';

class FirestoreSubscriptionRepository implements SubscriptionRepository {
  const FirestoreSubscriptionRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<SubscriptionPlan>> watchSubscriptions(String userId) {
    return _subscriptions(userId).snapshots().map((snapshot) {
      final subscriptions = snapshot.docs.map(_fromDocument).toList()
        ..sort(
          (left, right) =>
              left.nextBillingDate.compareTo(right.nextBillingDate),
        );
      return subscriptions;
    });
  }

  @override
  Future<void> createSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {
    await _subscriptions(userId).add(_toDocument(subscription, isCreate: true));
  }

  @override
  Future<void> updateSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {
    await _subscriptions(
      userId,
    ).doc(subscription.id).update(_toDocument(subscription, isCreate: false));
  }

  @override
  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    await _subscriptions(userId).doc(subscriptionId).delete();
  }

  CollectionReference<Map<String, dynamic>> _subscriptions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions');
  }

  SubscriptionPlan _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return SubscriptionPlan(
      id: document.id,
      name: data['name'] as String? ?? 'Subskrypcja',
      category: data['category'] as String? ?? 'Inne',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      billingCycle: _billingCycleFromName(data['billingCycle'] as String?),
      nextBillingDate:
          (data['nextBillingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> _toDocument(
    SubscriptionPlan subscription, {
    required bool isCreate,
  }) {
    return {
      'name': subscription.name.trim(),
      'category': subscription.category.trim(),
      'amount': subscription.amount,
      'billingCycle': subscription.billingCycle.name,
      'nextBillingDate': Timestamp.fromDate(subscription.nextBillingDate),
      'isActive': subscription.isActive,
      'note': subscription.note?.trim().isEmpty ?? true
          ? null
          : subscription.note?.trim(),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SubscriptionBillingCycle _billingCycleFromName(String? value) {
    return SubscriptionBillingCycle.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => SubscriptionBillingCycle.monthly,
    );
  }
}
