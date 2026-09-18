import '../../../models/finance_models.dart';

abstract class GoalRepository {
  Stream<List<SavingsGoal>> watchGoals(String userId);

  Future<void> createGoal({required String userId, required SavingsGoal goal});

  Future<void> updateGoal({required String userId, required SavingsGoal goal});

  Future<void> deleteGoal({required String userId, required String goalId});
}
