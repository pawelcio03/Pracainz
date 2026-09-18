import '../../../models/finance_models.dart';

abstract class GoalContributionPlanRepository {
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId);

  Future<void> createGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  });

  Future<void> updateGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  });

  Future<void> deleteGoalContributionPlan({
    required String userId,
    required String planId,
  });

  Future<void> deletePlansForGoal({
    required String userId,
    required String goalId,
  });
}
