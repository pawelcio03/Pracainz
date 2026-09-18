import '../../../models/finance_models.dart';
import '../domain/recurring_income_repository.dart';

class MemoryRecurringIncomeRepository implements RecurringIncomeRepository {
  const MemoryRecurringIncomeRepository();

  @override
  Future<void> createRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {}

  @override
  Future<void> deleteRecurringIncome({
    required String userId,
    required String recurringIncomeId,
  }) async {}

  @override
  Future<void> updateRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {}

  @override
  Stream<List<RecurringIncomePlan>> watchRecurringIncomes(String userId) {
    return Stream<List<RecurringIncomePlan>>.value(
      const <RecurringIncomePlan>[],
    );
  }
}
