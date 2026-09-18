import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/goal_contribution_plans/application/goal_contribution_plans_controller.dart';
import 'package:finovo/features/goal_contribution_plans/domain/goal_contribution_plan_repository.dart';
import 'package:finovo/features/transactions/domain/transaction_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'goal contribution plans controller generates missing monthly transfers',
    () async {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final repository = _RecordingGoalContributionPlanRepository([
        GoalContributionPlan(
          id: 'plan-1',
          goalId: 'goal-1',
          name: 'Wplata do celu',
          amount: 500,
          interval: GoalContributionInterval.monthly,
          dayOfMonth: 1,
          startDate: startDate,
          isActive: true,
        ),
      ]);
      final transactionRepository = _RecordingTransactionRepository();
      final controller = GoalContributionPlansController(
        repository: repository,
        transactionRepository: transactionRepository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      await controller.syncTransactions(
        transactions: const [],
        goals: [
          SavingsGoal(
            id: 'goal-1',
            name: 'Poduszka',
            targetAmount: 5000,
            savedAmount: 1000,
            deadline: DateTime(2026, 12, 31),
          ),
        ],
      );

      expect(transactionRepository.createdTransactions, hasLength(3));
      expect(
        transactionRepository.createdTransactions.every(
          (transaction) => transaction.goalContributionPlanId == 'plan-1',
        ),
        isTrue,
      );
      expect(
        repository.updatedPlans.single.lastGeneratedPeriodKey,
        _monthKey(now),
      );
    },
  );

  test(
    'goal contribution plans controller generates quarterly transfers on due months only',
    () async {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 6, 1);
      final repository = _RecordingGoalContributionPlanRepository([
        GoalContributionPlan(
          id: 'plan-1',
          goalId: 'goal-1',
          name: 'Kwartalna wplata',
          amount: 900,
          interval: GoalContributionInterval.quarterly,
          dayOfMonth: 1,
          startDate: startDate,
          isActive: true,
        ),
      ]);
      final transactionRepository = _RecordingTransactionRepository();
      final controller = GoalContributionPlansController(
        repository: repository,
        transactionRepository: transactionRepository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      await controller.syncTransactions(
        transactions: const [],
        goals: [
          SavingsGoal(
            id: 'goal-1',
            name: 'Poduszka',
            targetAmount: 5000,
            savedAmount: 1000,
            deadline: DateTime(2026, 12, 31),
          ),
        ],
      );

      expect(transactionRepository.createdTransactions, hasLength(3));
      expect(
        transactionRepository.createdTransactions.map((tx) => tx.date.month),
        orderedEquals(<int>[
          startDate.month,
          DateTime(startDate.year, startDate.month + 3, 1).month,
          DateTime(startDate.year, startDate.month + 6, 1).month,
        ]),
      );
    },
  );

  test(
    'goal contribution plans controller does not duplicate matching manual contribution',
    () async {
      final now = DateTime.now();
      final manualContributionDate = DateTime(now.year, now.month, 1);
      final repository = _RecordingGoalContributionPlanRepository([
        GoalContributionPlan(
          id: 'plan-1',
          goalId: 'goal-1',
          name: 'Wplata do celu',
          amount: 500,
          interval: GoalContributionInterval.monthly,
          dayOfMonth: 1,
          startDate: manualContributionDate,
          isActive: true,
        ),
      ]);
      final transactionRepository = _RecordingTransactionRepository();
      final controller = GoalContributionPlansController(
        repository: repository,
        transactionRepository: transactionRepository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      await controller.syncTransactions(
        transactions: [
          FinanceTransaction(
            id: 'tx-1',
            title: 'Wplata do celu',
            category: 'Oszczednosci',
            amount: 500,
            date: manualContributionDate,
            type: TransactionType.transfer,
            goalId: 'goal-1',
          ),
        ],
        goals: [
          SavingsGoal(
            id: 'goal-1',
            name: 'Poduszka',
            targetAmount: 5000,
            savedAmount: 1000,
            deadline: DateTime(2026, 12, 31),
          ),
        ],
      );

      expect(transactionRepository.createdTransactions, isEmpty);
      expect(
        repository.updatedPlans.single.lastGeneratedPeriodKey,
        _monthKey(now),
      );
    },
  );
}

String _monthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

class _RecordingGoalContributionPlanRepository
    implements GoalContributionPlanRepository {
  _RecordingGoalContributionPlanRepository(this.seedPlans);

  final List<GoalContributionPlan> seedPlans;
  final List<GoalContributionPlan> updatedPlans = <GoalContributionPlan>[];

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
  }) async {
    updatedPlans.add(plan);
  }

  @override
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId) {
    return Stream<List<GoalContributionPlan>>.value(seedPlans);
  }
}

class _RecordingTransactionRepository implements TransactionRepository {
  final List<FinanceTransaction> createdTransactions = <FinanceTransaction>[];

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    createdTransactions.add(transaction);
    return transaction.copyWith(id: 'created-${createdTransactions.length}');
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {}

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return const Stream<List<FinanceTransaction>>.empty();
  }
}
