import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/goal_contribution_plan_repository.dart';

class FirestoreGoalContributionPlanRepository
    implements GoalContributionPlanRepository {
  const FirestoreGoalContributionPlanRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId) {
    return _goalContributionPlans(userId).snapshots().map((snapshot) {
      final plans = snapshot.docs.map(_fromDocument).toList()
        ..sort((left, right) {
          if (left.isActive != right.isActive) {
            return left.isActive ? -1 : 1;
          }

          final dayComparison = left.dayOfMonth.compareTo(right.dayOfMonth);
          if (dayComparison != 0) {
            return dayComparison;
          }

          return left.name.compareTo(right.name);
        });
      return plans;
    });
  }

  @override
  Future<void> createGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {
    await _goalContributionPlans(userId).add(_toDocument(plan, isCreate: true));
  }

  @override
  Future<void> updateGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {
    await _goalContributionPlans(
      userId,
    ).doc(plan.id).update(_toDocument(plan, isCreate: false));
  }

  @override
  Future<void> deleteGoalContributionPlan({
    required String userId,
    required String planId,
  }) async {
    await _goalContributionPlans(userId).doc(planId).delete();
  }

  @override
  Future<void> deletePlansForGoal({
    required String userId,
    required String goalId,
  }) async {
    final snapshot = await _goalContributionPlans(
      userId,
    ).where('goalId', isEqualTo: goalId).get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _goalContributionPlans(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goalContributionPlans');
  }

  GoalContributionPlan _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawInterval = data['interval'] as String? ?? 'monthly';

    return GoalContributionPlan(
      id: document.id,
      goalId: data['goalId'] as String? ?? '',
      name: data['name'] as String? ?? 'Wplata do celu',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      interval: switch (rawInterval) {
        'quarterly' => GoalContributionInterval.quarterly,
        'yearly' => GoalContributionInterval.yearly,
        _ => GoalContributionInterval.monthly,
      },
      dayOfMonth: (data['dayOfMonth'] as num?)?.toInt() ?? 1,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      lastGeneratedPeriodKey: data['lastGeneratedPeriodKey'] as String?,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> _toDocument(
    GoalContributionPlan plan, {
    required bool isCreate,
  }) {
    final note = plan.note?.trim();

    return {
      'goalId': plan.goalId.trim(),
      'name': plan.name.trim(),
      'amount': plan.amount,
      'interval': plan.interval.name,
      'dayOfMonth': plan.dayOfMonth,
      'startDate': Timestamp.fromDate(plan.startDate),
      'isActive': plan.isActive,
      'lastGeneratedPeriodKey': plan.lastGeneratedPeriodKey,
      'note': note == null || note.isEmpty ? null : note,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
