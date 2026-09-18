import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/core/validation/input_validation_exception.dart';
import 'package:finovo/features/budgets/application/budgets_controller.dart';
import 'package:finovo/features/budgets/domain/budget_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'budgets controller rejects duplicate category in selected period',
    () async {
      final repository = _BudgetRepositoryWithBudgets([
        CategoryBudget(
          id: 'budget-1',
          category: 'Dom',
          limit: 1200,
          spent: 0,
          periodStart: DateTime(2026, 6, 1),
        ),
      ]);
      final controller = BudgetsController(
        repository: repository,
        userId: 'user-1',
        initialPeriod: DateTime(2026, 6, 1),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      await expectLater(
        controller.save(
          CategoryBudget(
            id: '',
            category: ' dom ',
            limit: 1500,
            spent: 0,
            periodStart: DateTime(2026, 6, 1),
          ),
        ),
        throwsA(isA<InputValidationException>()),
      );

      expect(repository.createdBudgets, isEmpty);
    },
  );

  test(
    'budgets controller allows updating the current category budget',
    () async {
      final repository = _BudgetRepositoryWithBudgets([
        CategoryBudget(
          id: 'budget-1',
          category: 'Dom',
          limit: 1200,
          spent: 0,
          periodStart: DateTime(2026, 6, 1),
        ),
      ]);
      final controller = BudgetsController(
        repository: repository,
        userId: 'user-1',
        initialPeriod: DateTime(2026, 6, 1),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      await controller.save(
        CategoryBudget(
          id: 'budget-1',
          category: 'Dom',
          limit: 1600,
          spent: 300,
          periodStart: DateTime(2026, 6, 1),
        ),
      );

      expect(repository.updatedBudgets.single.limit, 1600);
      expect(repository.updatedBudgets.single.spent, 0);
    },
  );
}

class _BudgetRepositoryWithBudgets implements BudgetRepository {
  _BudgetRepositoryWithBudgets(this.seedBudgets);

  final List<CategoryBudget> seedBudgets;
  final List<CategoryBudget> createdBudgets = <CategoryBudget>[];
  final List<CategoryBudget> updatedBudgets = <CategoryBudget>[];

  @override
  Future<void> createBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {
    createdBudgets.add(budget);
  }

  @override
  Future<void> deleteBudget({
    required String userId,
    required String budgetId,
  }) async {}

  @override
  Future<void> updateBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {
    updatedBudgets.add(budget);
  }

  @override
  Stream<List<CategoryBudget>> watchBudgets({
    required String userId,
    required DateTime periodStart,
  }) {
    return Stream<List<CategoryBudget>>.value(seedBudgets);
  }
}
