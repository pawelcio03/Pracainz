import '../../../models/finance_models.dart';

class CategoryUsageSummary {
  const CategoryUsageSummary({
    this.transactionCount = 0,
    this.budgetCount = 0,
    this.subscriptionCount = 0,
    this.recurringIncomeCount = 0,
  });

  final int transactionCount;
  final int budgetCount;
  final int subscriptionCount;
  final int recurringIncomeCount;

  bool get isUsed =>
      transactionCount > 0 ||
      budgetCount > 0 ||
      subscriptionCount > 0 ||
      recurringIncomeCount > 0;
}

abstract class CategoryRepository {
  Stream<List<FinanceCategory>> watchCategories(String userId);

  Future<void> createCategory({
    required String userId,
    required FinanceCategory category,
  });

  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  });

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  });

  Future<CategoryUsageSummary> readCategoryUsage({
    required String userId,
    required FinanceCategory category,
  });

  Future<void> mergeCategory({
    required String userId,
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  });

  Future<void> ensureDefaultCategories({
    required String userId,
    required List<FinanceCategory> defaults,
  });
}
