import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/recurring_income_repository.dart';

class FirestoreRecurringIncomeRepository implements RecurringIncomeRepository {
  const FirestoreRecurringIncomeRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<RecurringIncomePlan>> watchRecurringIncomes(String userId) {
    return _recurringIncomes(userId).snapshots().map((snapshot) {
      final plans = snapshot.docs.map(_fromDocument).toList()
        ..sort((left, right) {
          final activeComparison = right.isActive.toString().compareTo(
            left.isActive.toString(),
          );
          if (activeComparison != 0) {
            return activeComparison;
          }
          final paydayComparison = left.payday.compareTo(right.payday);
          if (paydayComparison != 0) {
            return paydayComparison;
          }
          return left.name.compareTo(right.name);
        });
      return plans;
    });
  }

  @override
  Future<void> createRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {
    await _recurringIncomes(userId).add(_toDocument(plan, isCreate: true));
  }

  @override
  Future<void> updateRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {
    await _recurringIncomes(
      userId,
    ).doc(plan.id).update(_toDocument(plan, isCreate: false));
  }

  @override
  Future<void> deleteRecurringIncome({
    required String userId,
    required String recurringIncomeId,
  }) async {
    await _recurringIncomes(userId).doc(recurringIncomeId).delete();
  }

  CollectionReference<Map<String, dynamic>> _recurringIncomes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurringIncomes');
  }

  RecurringIncomePlan _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return RecurringIncomePlan(
      id: document.id,
      name: data['name'] as String? ?? 'Staly dochod',
      category: data['category'] as String? ?? 'Praca',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      payday: (data['payday'] as num?)?.toInt() ?? 1,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      lastGeneratedMonthKey: data['lastGeneratedMonthKey'] as String?,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> _toDocument(
    RecurringIncomePlan plan, {
    required bool isCreate,
  }) {
    final note = plan.note?.trim();

    return {
      'name': plan.name.trim(),
      'category': plan.category.trim(),
      'amount': plan.amount,
      'payday': plan.payday,
      'startDate': Timestamp.fromDate(plan.startDate),
      'isActive': plan.isActive,
      'lastGeneratedMonthKey': plan.lastGeneratedMonthKey,
      'note': note == null || note.isEmpty ? null : note,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
