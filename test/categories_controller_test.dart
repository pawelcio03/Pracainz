import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/categories/application/categories_controller.dart';
import 'package:finovo/features/categories/domain/category_mutation_exception.dart';
import 'package:finovo/features/categories/domain/category_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'categories controller rejects duplicate category name for same type',
    () async {
      final repository = _CategoryRepositoryWithData();
      final controller = CategoriesController(
        repository: repository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(
        () => controller.save(
          const FinanceCategory(
            id: '',
            name: 'dom',
            type: TransactionType.expense,
          ),
        ),
        throwsA(isA<CategoryMutationException>()),
      );
    },
  );

  test('categories controller delegates merge to repository', () async {
    final repository = _CategoryRepositoryWithData();
    final controller = CategoriesController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    final source = repository.seedCategories[0];
    final target = repository.seedCategories[1];

    await controller.mergeCategory(
      sourceCategory: source,
      targetCategory: target,
    );

    expect(repository.lastMergedSourceId, source.id);
    expect(repository.lastMergedTargetId, target.id);
  });

  test(
    'categories controller rejects type change when category is used',
    () async {
      final repository = _CategoryRepositoryWithData(
        usageByCategoryId: const {
          'category-1': CategoryUsageSummary(transactionCount: 1),
        },
      );
      final controller = CategoriesController(
        repository: repository,
        userId: 'user-1',
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(
        () => controller.save(
          const FinanceCategory(
            id: 'category-1',
            name: 'Dom',
            type: TransactionType.income,
          ),
        ),
        throwsA(isA<CategoryMutationException>()),
      );
      expect(repository.lastUpdatedCategory, isNull);
    },
  );

  test('categories controller rejects deleting used category', () async {
    final repository = _CategoryRepositoryWithData(
      usageByCategoryId: const {
        'category-1': CategoryUsageSummary(budgetCount: 1),
      },
    );
    final controller = CategoriesController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(
      () => controller.delete(repository.seedCategories.first),
      throwsA(isA<CategoryMutationException>()),
    );
    expect(repository.lastDeletedCategoryId, isNull);
  });
}

class _CategoryRepositoryWithData implements CategoryRepository {
  _CategoryRepositoryWithData({
    this.usageByCategoryId = const <String, CategoryUsageSummary>{},
  });

  final Map<String, CategoryUsageSummary> usageByCategoryId;
  final List<FinanceCategory> seedCategories = const [
    FinanceCategory(
      id: 'category-1',
      name: 'Dom',
      type: TransactionType.expense,
    ),
    FinanceCategory(
      id: 'category-2',
      name: 'Jedzenie',
      type: TransactionType.expense,
    ),
  ];

  String? lastMergedSourceId;
  String? lastMergedTargetId;
  FinanceCategory? lastUpdatedCategory;
  String? lastDeletedCategoryId;

  @override
  Future<void> createCategory({
    required String userId,
    required FinanceCategory category,
  }) async {}

  @override
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    lastDeletedCategoryId = categoryId;
  }

  @override
  Future<void> ensureDefaultCategories({
    required String userId,
    required List<FinanceCategory> defaults,
  }) async {}

  @override
  Future<void> mergeCategory({
    required String userId,
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  }) async {
    lastMergedSourceId = sourceCategory.id;
    lastMergedTargetId = targetCategory.id;
  }

  @override
  Future<CategoryUsageSummary> readCategoryUsage({
    required String userId,
    required FinanceCategory category,
  }) async {
    return usageByCategoryId[category.id] ?? const CategoryUsageSummary();
  }

  @override
  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    lastUpdatedCategory = category;
  }

  @override
  Stream<List<FinanceCategory>> watchCategories(String userId) {
    return Stream<List<FinanceCategory>>.value(seedCategories);
  }
}
