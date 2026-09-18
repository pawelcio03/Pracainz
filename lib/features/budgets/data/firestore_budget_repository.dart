import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/budget_repository.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  const FirestoreBudgetRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<CategoryBudget>> watchBudgets({
    required String userId,
    required DateTime periodStart,
  }) {
    return _budgets(userId)
        .where('periodKey', isEqualTo: _periodKey(periodStart))
        .snapshots()
        .map((snapshot) {
          final budgets = snapshot.docs.map(_fromDocument).toList()
            ..sort((left, right) => left.category.compareTo(right.category));
          return budgets;
        });
  }

  @override
  Future<void> createBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {
    await _budgets(userId).add(_toDocument(budget, isCreate: true));
  }

  @override
  Future<void> updateBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {
    await _budgets(
      userId,
    ).doc(budget.id).update(_toDocument(budget, isCreate: false));
  }

  @override
  Future<void> deleteBudget({
    required String userId,
    required String budgetId,
  }) async {
    await _budgets(userId).doc(budgetId).delete();
  }

  CollectionReference<Map<String, dynamic>> _budgets(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  CategoryBudget _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final periodStart =
        (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now();

    return CategoryBudget(
      id: document.id,
      category: data['category'] as String? ?? 'Inne',
      limit: (data['limit'] as num?)?.toDouble() ?? 0,
      spent: 0,
      periodStart: DateTime(periodStart.year, periodStart.month),
    );
  }

  Map<String, dynamic> _toDocument(
    CategoryBudget budget, {
    required bool isCreate,
  }) {
    final periodStart = DateTime(
      budget.periodStart.year,
      budget.periodStart.month,
    );

    return {
      'category': budget.category.trim(),
      'limit': budget.limit,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodKey': _periodKey(periodStart),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _periodKey(DateTime periodStart) {
    final month = periodStart.month.toString().padLeft(2, '0');
    return '${periodStart.year}-$month';
  }
}
