import '../../../models/finance_models.dart';

abstract class BudgetRepository {
  Stream<List<CategoryBudget>> watchBudgets({
    required String userId,
    required DateTime periodStart,
  });

  Future<void> createBudget({
    required String userId,
    required CategoryBudget budget,
  });

  Future<void> updateBudget({
    required String userId,
    required CategoryBudget budget,
  });

  Future<void> deleteBudget({required String userId, required String budgetId});
}
