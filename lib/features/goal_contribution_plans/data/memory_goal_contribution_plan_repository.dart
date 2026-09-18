import '../../../models/finance_models.dart';
import '../domain/goal_contribution_plan_repository.dart';

class MemoryGoalContributionPlanRepository
    implements GoalContributionPlanRepository {
  const MemoryGoalContributionPlanRepository();

  @override
  Future<void> createGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Future<void> deleteGoalContributionPlan({
    required String userId,
    required String planId,
  }) async {}

  @override
  Future<void> deletePlansForGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<void> updateGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId) {
    return Stream<List<GoalContributionPlan>>.value(
      const <GoalContributionPlan>[],
    );
  }
}
