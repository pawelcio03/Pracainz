import '../../../models/finance_models.dart';

abstract class TransactionRepository {
  Stream<List<FinanceTransaction>> watchTransactions(String userId);

  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  });

  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  });

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  });
}
