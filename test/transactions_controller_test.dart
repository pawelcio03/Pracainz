import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/core/validation/input_validation_exception.dart';
import 'package:finovo/features/transactions/application/transactions_controller.dart';
import 'package:finovo/features/transactions/domain/transaction_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('transactions controller filters transactions by goal id', () async {
    final controller = TransactionsController(
      repository: _RepositoryWithTransactions(),
      userId: 'user-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(controller.visibleTransactions, hasLength(3));

    controller.setGoalFilter('goal-1');

    expect(controller.goalFilter, 'goal-1');
    expect(controller.visibleTransactions, hasLength(1));
    expect(controller.visibleTransactions.single.title, 'Wplata na poduszke');

    controller.clearFilters();

    expect(controller.goalFilter, isNull);
    expect(controller.visibleTransactions, hasLength(3));
  });

  test('transactions controller sanitizes transaction before create', () async {
    final repository = _RecordingTransactionRepository();
    final controller = TransactionsController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    await controller.save(
      FinanceTransaction(
        id: '',
        title: '  Zakupy   domowe  ',
        category: '  Dom  ',
        amount: 89.5,
        date: DateTime(2026, 6, 4),
        type: TransactionType.expense,
        goalId: '   ',
        note: '  Mleko i pieczywo  ',
      ),
    );

    expect(repository.lastCreatedTransaction, isNotNull);
    expect(repository.lastCreatedTransaction!.title, 'Zakupy domowe');
    expect(repository.lastCreatedTransaction!.category, 'Dom');
    expect(repository.lastCreatedTransaction!.goalId, isNull);
    expect(repository.lastCreatedTransaction!.note, 'Mleko i pieczywo');
  });

  test('transactions controller rejects invalid transaction payload', () async {
    final repository = _RecordingTransactionRepository();
    final controller = TransactionsController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    await expectLater(
      controller.save(
        FinanceTransaction(
          id: '',
          title: 'Test',
          category: 'Dom',
          amount: -1,
          date: DateTime(2026, 6, 4),
          type: TransactionType.expense,
        ),
      ),
      throwsA(isA<InputValidationException>()),
    );

    expect(repository.lastCreatedTransaction, isNull);
  });

  test(
    'transactions controller deletes unique non-empty transaction ids',
    () async {
      final repository = _RecordingTransactionRepository();
      final controller = TransactionsController(
        repository: repository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      final deletedCount = await controller.deleteTransactionsByIds([
        ' tx-1 ',
        '',
        'tx-2',
        'tx-1',
        '   ',
      ]);

      expect(deletedCount, 2);
      expect(repository.deletedTransactionIds, ['tx-1', 'tx-2']);
    },
  );
}

class _RepositoryWithTransactions implements TransactionRepository {
  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    return transaction;
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
    return Stream<List<FinanceTransaction>>.value([
      FinanceTransaction(
        id: 'tx-1',
        title: 'Wplata na poduszke',
        category: 'Oszczednosci',
        amount: 300,
        date: DateTime(2026, 6, 2),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
      FinanceTransaction(
        id: 'tx-2',
        title: 'Zakupy',
        category: 'Dom',
        amount: 120,
        date: DateTime(2026, 6, 1),
        type: TransactionType.expense,
      ),
      FinanceTransaction(
        id: 'tx-3',
        title: 'Pensja',
        category: 'Praca',
        amount: 5000,
        date: DateTime(2026, 5, 31),
        type: TransactionType.income,
      ),
    ]);
  }
}

class _RecordingTransactionRepository implements TransactionRepository {
  FinanceTransaction? lastCreatedTransaction;
  final List<String> deletedTransactionIds = <String>[];

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    lastCreatedTransaction = transaction;
    return transaction.copyWith(id: 'created-tx');
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    deletedTransactionIds.add(transactionId);
  }

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
