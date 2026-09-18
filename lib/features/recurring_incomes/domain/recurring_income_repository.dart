import '../../../models/finance_models.dart';

abstract class RecurringIncomeRepository {
  Stream<List<RecurringIncomePlan>> watchRecurringIncomes(String userId);

  Future<void> createRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  });

  Future<void> updateRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  });

  Future<void> deleteRecurringIncome({
    required String userId,
    required String recurringIncomeId,
  });
}
