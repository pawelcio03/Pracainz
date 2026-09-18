import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  const FirestoreTransactionRepository({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return _transactions(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    final document = await _transactions(
      userId,
    ).add(_toDocument(transaction, isCreate: true));
    return transaction.copyWith(id: document.id);
  }

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    await _transactions(
      userId,
    ).doc(transaction.id).update(_toDocument(transaction, isCreate: false));
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _transactions(userId).doc(transactionId).delete();
  }

  CollectionReference<Map<String, dynamic>> _transactions(String userId) {
    return firestore.collection('users').doc(userId).collection('transactions');
  }

  FinanceTransaction _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawType = data['type'] as String? ?? 'expense';

    return FinanceTransaction(
      id: document.id,
      title: data['title'] as String? ?? 'Bez nazwy',
      category: data['category'] as String? ?? 'Inne',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: switch (rawType) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      },
      goalId: data['goalId'] as String?,
      goalContributionPlanId: data['goalContributionPlanId'] as String?,
      recurringIncomeId: data['recurringIncomeId'] as String?,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> _toDocument(
    FinanceTransaction transaction, {
    required bool isCreate,
  }) {
    final note = transaction.note?.trim();

    return {
      'title': transaction.title.trim(),
      'category': transaction.category.trim(),
      'amount': transaction.amount,
      'date': Timestamp.fromDate(transaction.date),
      'type': transaction.type.name,
      'goalId': transaction.goalId?.trim().isEmpty ?? true
          ? null
          : transaction.goalId?.trim(),
      'goalContributionPlanId':
          transaction.goalContributionPlanId?.trim().isEmpty ?? true
          ? null
          : transaction.goalContributionPlanId?.trim(),
      'recurringIncomeId': transaction.recurringIncomeId?.trim().isEmpty ?? true
          ? null
          : transaction.recurringIncomeId?.trim(),
      'note': note == null || note.isEmpty ? null : note,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
