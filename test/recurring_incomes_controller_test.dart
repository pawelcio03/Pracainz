import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/recurring_incomes/application/recurring_incomes_controller.dart';
import 'package:finovo/features/recurring_incomes/domain/recurring_income_repository.dart';
import 'package:finovo/features/transactions/domain/transaction_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'recurring incomes controller generates missing monthly income transactions',
    () async {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1);
      final repository = _RecordingRecurringIncomeRepository([
        RecurringIncomePlan(
          id: 'income-1',
          name: 'Pensja',
          category: 'Praca',
          amount: 6800,
          payday: 1,
          startDate: startDate,
          isActive: true,
        ),
      ]);
      final transactionRepository = _RecordingTransactionRepository();
      final controller = RecurringIncomesController(
        repository: repository,
        transactionRepository: transactionRepository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      await controller.syncTransactions(const []);

      expect(transactionRepository.createdTransactions, hasLength(3));
      expect(
        transactionRepository.createdTransactions.every(
          (transaction) => transaction.recurringIncomeId == 'income-1',
        ),
        isTrue,
      );
      expect(
        repository.updatedPlans.single.lastGeneratedMonthKey,
        _monthKey(now),
      );
    },
  );

  test(
    'recurring incomes controller does not duplicate matching manual salary',
    () async {
      final now = DateTime.now();
      final manualSalaryDate = DateTime(now.year, now.month, 1);
      final repository = _RecordingRecurringIncomeRepository([
        RecurringIncomePlan(
          id: 'income-1',
          name: 'Pensja',
          category: 'Praca',
          amount: 6800,
          payday: 1,
          startDate: manualSalaryDate,
          isActive: true,
        ),
      ]);
      final transactionRepository = _RecordingTransactionRepository();
      final controller = RecurringIncomesController(
        repository: repository,
        transactionRepository: transactionRepository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);
      await controller.syncTransactions([
        FinanceTransaction(
          id: 'tx-1',
          title: 'Pensja',
          category: 'Praca',
          amount: 6800,
          date: manualSalaryDate,
          type: TransactionType.income,
        ),
      ]);

      expect(transactionRepository.createdTransactions, isEmpty);
      expect(
        repository.updatedPlans.single.lastGeneratedMonthKey,
        _monthKey(now),
      );
    },
  );
}

String _monthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

class _RecordingRecurringIncomeRepository implements RecurringIncomeRepository {
  _RecordingRecurringIncomeRepository(this.seedPlans);

  final List<RecurringIncomePlan> seedPlans;
  final List<RecurringIncomePlan> updatedPlans = <RecurringIncomePlan>[];

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
  }) async {
    updatedPlans.add(plan);
  }

  @override
  Stream<List<RecurringIncomePlan>> watchRecurringIncomes(String userId) {
    return Stream<List<RecurringIncomePlan>>.value(seedPlans);
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
