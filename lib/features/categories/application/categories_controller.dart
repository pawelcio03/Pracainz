import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/category_mutation_exception.dart';
import '../domain/category_presets.dart';
import '../domain/category_repository.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController({required this.repository, required this.userId}) {
    _subscribe();
    unawaited(_ensureDefaults());
  }

  final CategoryRepository repository;
  final String userId;

  late final StreamSubscription<List<FinanceCategory>> _subscription;
  bool _isLoading = true;
  Object? _error;
  List<FinanceCategory> _categories = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<FinanceCategory> get categories => _categories;

  List<FinanceCategory> categoriesForType(TransactionType type) {
    return categoriesForTypeOrFallback(_categories, type);
  }

  Future<void> save(FinanceCategory category) async {
    final normalizedCategory = FinanceInputSanitizer.sanitizeCategory(category);
    _ensureUniqueName(normalizedCategory);

    if (normalizedCategory.isPersisted) {
      final currentCategory = _findCategoryById(normalizedCategory.id);
      if (currentCategory != null &&
          currentCategory.type != normalizedCategory.type) {
        final usage = await repository.readCategoryUsage(
          userId: userId,
          category: currentCategory,
        );
        if (usage.isUsed) {
          throw const CategoryMutationException(
            'Nie mozna zmienic typu kategorii, ktora ma przypiete dane.',
          );
        }
      }

      await repository.updateCategory(
        userId: userId,
        category: normalizedCategory,
      );
      return;
    }

    await repository.createCategory(
      userId: userId,
      category: normalizedCategory,
    );
  }

  Future<void> mergeCategory({
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  }) {
    _validateMerge(
      sourceCategory: sourceCategory,
      targetCategory: targetCategory,
    );

    return repository.mergeCategory(
      userId: userId,
      sourceCategory: sourceCategory,
      targetCategory: targetCategory,
    );
  }

  Future<void> delete(FinanceCategory category) {
    return _delete(category);
  }

  Future<void> _ensureDefaults() async {
    try {
      await repository.ensureDefaultCategories(
        userId: userId,
        defaults: defaultFinanceCategories,
      );
    } catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = repository
        .watchCategories(userId)
        .listen(
          (categories) {
            _categories = categories;
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _ensureUniqueName(FinanceCategory category) {
    final normalizedName = category.name.trim().toLowerCase();
    final duplicateExists = _categories.any(
      (current) =>
          current.id != category.id &&
          current.type == category.type &&
          current.name.trim().toLowerCase() == normalizedName,
    );

    if (!duplicateExists) {
      return;
    }

    throw CategoryMutationException(
      'Kategoria "${category.name.trim()}" juz istnieje dla tego typu.',
    );
  }

  FinanceCategory? _findCategoryById(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }

  Future<void> _delete(FinanceCategory category) async {
    final usage = await repository.readCategoryUsage(
      userId: userId,
      category: category,
    );
    if (usage.isUsed) {
      throw const CategoryMutationException(
        'Nie mozna usunac kategorii, ktora ma przypiete dane. Uzyj scalania.',
      );
    }

    await repository.deleteCategory(userId: userId, categoryId: category.id);
  }

  void _validateMerge({
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  }) {
    if (!sourceCategory.isPersisted || !targetCategory.isPersisted) {
      throw const CategoryMutationException(
        'Mozna scalac tylko zapisane kategorie.',
      );
    }

    if (sourceCategory.id == targetCategory.id) {
      throw const CategoryMutationException('Wybierz inna kategorie docelowa.');
    }

    if (sourceCategory.type != targetCategory.type) {
      throw const CategoryMutationException(
        'Kategorie musza miec ten sam typ.',
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
