import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/category_mutation_exception.dart';
import '../domain/category_repository.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  const FirestoreCategoryRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<FinanceCategory>> watchCategories(String userId) {
    return _categories(userId).snapshots().map((snapshot) {
      final categories = snapshot.docs.map(_fromDocument).toList()
        ..sort((left, right) {
          final typeOrder = left.type.index.compareTo(right.type.index);
          if (typeOrder != 0) {
            return typeOrder;
          }

          return left.name.compareTo(right.name);
        });
      return categories;
    });
  }

  @override
  Future<void> createCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    await _categories(userId).add(_toDocument(category, isCreate: true));
  }

  @override
  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    final categoryReference = _categories(userId).doc(category.id);
    final previousCategory = await _readCategory(categoryReference);

    if (previousCategory != null && previousCategory.type != category.type) {
      final usage = await readCategoryUsage(
        userId: userId,
        category: previousCategory,
      );
      if (usage.isUsed) {
        throw const CategoryMutationException(
          'Nie mozna zmienic typu kategorii, ktora ma przypiete dane.',
        );
      }
    }

    final updates = <_PendingCategoryUpdate>[
      _PendingCategoryUpdate(
        reference: categoryReference,
        data: _toDocument(category, isCreate: false),
      ),
    ];

    if (previousCategory != null &&
        previousCategory.type == category.type &&
        previousCategory.name.trim() != category.name.trim()) {
      updates.addAll(
        await _categoryReferenceUpdates(
          userId: userId,
          sourceCategory: previousCategory,
          targetCategoryName: category.name.trim(),
        ),
      );
    }

    await _commitChunkedUpdates(updates);
  }

  @override
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    final categoryReference = _categories(userId).doc(categoryId);
    final category = await _readCategory(categoryReference);
    if (category != null) {
      final usage = await readCategoryUsage(userId: userId, category: category);
      if (usage.isUsed) {
        throw const CategoryMutationException(
          'Nie mozna usunac kategorii, ktora ma przypiete dane. Uzyj scalania.',
        );
      }
    }

    await categoryReference.delete();
  }

  @override
  Future<CategoryUsageSummary> readCategoryUsage({
    required String userId,
    required FinanceCategory category,
  }) async {
    final sourceName = category.name.trim();
    final transactions = await _transactions(
      userId,
    ).where('category', isEqualTo: sourceName).get();
    final transactionCount = transactions.docs.where((document) {
      final rawType = document.data()['type'] as String? ?? 'expense';
      return rawType == category.type.name;
    }).length;

    if (category.type == TransactionType.expense) {
      final budgets = await _budgets(
        userId,
      ).where('category', isEqualTo: sourceName).get();
      final subscriptions = await _subscriptions(
        userId,
      ).where('category', isEqualTo: sourceName).get();

      return CategoryUsageSummary(
        transactionCount: transactionCount,
        budgetCount: budgets.docs.length,
        subscriptionCount: subscriptions.docs.length,
      );
    }

    if (category.type == TransactionType.income) {
      final recurringIncomes = await _recurringIncomes(
        userId,
      ).where('category', isEqualTo: sourceName).get();

      return CategoryUsageSummary(
        transactionCount: transactionCount,
        recurringIncomeCount: recurringIncomes.docs.length,
      );
    }

    return CategoryUsageSummary(transactionCount: transactionCount);
  }

  @override
  Future<void> mergeCategory({
    required String userId,
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  }) async {
    final targetName = targetCategory.name.trim();

    await _reassignCategoryReferences(
      userId: userId,
      sourceCategory: sourceCategory,
      targetCategoryName: targetName,
    );

    await _categories(userId).doc(sourceCategory.id).delete();
  }

  @override
  Future<void> ensureDefaultCategories({
    required String userId,
    required List<FinanceCategory> defaults,
  }) async {
    final collection = _categories(userId);
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final category in defaults) {
      final document = collection.doc();
      batch.set(document, _toDocument(category, isCreate: true));
    }

    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _categories(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  CollectionReference<Map<String, dynamic>> _transactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> _budgets(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  CollectionReference<Map<String, dynamic>> _subscriptions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions');
  }

  CollectionReference<Map<String, dynamic>> _recurringIncomes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurringIncomes');
  }

  Future<FinanceCategory?> _readCategory(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    return _fromData(snapshot.id, data);
  }

  FinanceCategory _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return _fromData(document.id, document.data());
  }

  FinanceCategory _fromData(String id, Map<String, dynamic> data) {
    final rawType = data['type'] as String? ?? 'expense';

    return FinanceCategory(
      id: id,
      name: data['name'] as String? ?? 'Inne',
      type: switch (rawType) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      },
    );
  }

  Map<String, dynamic> _toDocument(
    FinanceCategory category, {
    required bool isCreate,
  }) {
    return {
      'name': category.name.trim(),
      'type': category.type.name,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _reassignCategoryReferences({
    required String userId,
    required FinanceCategory sourceCategory,
    required String targetCategoryName,
  }) async {
    final updates = await _categoryReferenceUpdates(
      userId: userId,
      sourceCategory: sourceCategory,
      targetCategoryName: targetCategoryName,
    );
    await _commitChunkedUpdates(updates);
  }

  Future<List<_PendingCategoryUpdate>> _categoryReferenceUpdates({
    required String userId,
    required FinanceCategory sourceCategory,
    required String targetCategoryName,
  }) async {
    final updates = <_PendingCategoryUpdate>[
      ...await _transactionCategoryUpdates(
        userId: userId,
        sourceCategory: sourceCategory,
        targetCategoryName: targetCategoryName,
      ),
    ];

    if (sourceCategory.type == TransactionType.expense) {
      updates.addAll(
        await _simpleCategoryUpdates(
          query: _budgets(
            userId,
          ).where('category', isEqualTo: sourceCategory.name.trim()),
          targetCategoryName: targetCategoryName,
        ),
      );
      updates.addAll(
        await _simpleCategoryUpdates(
          query: _subscriptions(
            userId,
          ).where('category', isEqualTo: sourceCategory.name.trim()),
          targetCategoryName: targetCategoryName,
        ),
      );
    } else if (sourceCategory.type == TransactionType.income) {
      updates.addAll(
        await _simpleCategoryUpdates(
          query: _recurringIncomes(
            userId,
          ).where('category', isEqualTo: sourceCategory.name.trim()),
          targetCategoryName: targetCategoryName,
        ),
      );
    }

    return updates;
  }

  Future<List<_PendingCategoryUpdate>> _transactionCategoryUpdates({
    required String userId,
    required FinanceCategory sourceCategory,
    required String targetCategoryName,
  }) async {
    final snapshot = await _transactions(
      userId,
    ).where('category', isEqualTo: sourceCategory.name.trim()).get();

    final matchingDocs = snapshot.docs.where((document) {
      final rawType = document.data()['type'] as String? ?? 'expense';
      return rawType == sourceCategory.type.name;
    }).toList();

    return matchingDocs
        .map(
          (document) => _PendingCategoryUpdate(
            reference: document.reference,
            data: <String, dynamic>{
              'category': targetCategoryName,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        )
        .toList();
  }

  Future<List<_PendingCategoryUpdate>> _simpleCategoryUpdates({
    required Query<Map<String, dynamic>> query,
    required String targetCategoryName,
  }) async {
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (document) => _PendingCategoryUpdate(
            reference: document.reference,
            data: <String, dynamic>{
              'category': targetCategoryName,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          ),
        )
        .toList();
  }

  Future<void> _commitChunkedUpdates(
    Iterable<_PendingCategoryUpdate> updates,
  ) async {
    final pending = updates.toList();
    if (pending.isEmpty) {
      return;
    }

    const batchLimit = 450;
    for (var start = 0; start < pending.length; start += batchLimit) {
      final end = (start + batchLimit).clamp(0, pending.length);
      final batch = _firestore.batch();
      for (final update in pending.sublist(start, end)) {
        batch.update(update.reference, update.data);
      }
      await batch.commit();
    }
  }
}

class _PendingCategoryUpdate {
  const _PendingCategoryUpdate({required this.reference, required this.data});

  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> data;
}
