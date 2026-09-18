import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../core/validation/input_validation_exception.dart';
import '../../../models/finance_models.dart';
import '../domain/budget_repository.dart';

class BudgetsController extends ChangeNotifier {
  BudgetsController({
    required this.repository,
    required this.userId,
    DateTime? initialPeriod,
  }) : _selectedPeriod = _normalizePeriod(initialPeriod ?? DateTime.now()) {
    _subscribe();
  }

  final BudgetRepository repository;
  final String userId;

  StreamSubscription<List<CategoryBudget>>? _subscription;
  DateTime _selectedPeriod;
  bool _isLoading = true;
  Object? _error;
  List<CategoryBudget> _budgets = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  DateTime get selectedPeriod => _selectedPeriod;

  List<CategoryBudget> get budgets => _budgets;

  Future<void> previousMonth() => setSelectedPeriod(
    DateTime(_selectedPeriod.year, _selectedPeriod.month - 1),
  );

  Future<void> nextMonth() => setSelectedPeriod(
    DateTime(_selectedPeriod.year, _selectedPeriod.month + 1),
  );

  Future<void> setSelectedPeriod(DateTime value) async {
    final normalized = _normalizePeriod(value);
    if (_selectedPeriod == normalized) {
      return;
    }

    _selectedPeriod = normalized;
    _isLoading = true;
    notifyListeners();
    await _subscription?.cancel();
    _subscribe();
  }

  Future<void> save(CategoryBudget budget) async {
    final normalizedBudget = FinanceInputSanitizer.sanitizeBudget(
      budget.copyWith(periodStart: _selectedPeriod, spent: 0),
    );
    _ensureUniqueCategoryForSelectedPeriod(normalizedBudget);

    if (normalizedBudget.isPersisted) {
      await repository.updateBudget(userId: userId, budget: normalizedBudget);
      return;
    }

    await repository.createBudget(userId: userId, budget: normalizedBudget);
  }

  Future<void> delete(CategoryBudget budget) {
    return repository.deleteBudget(userId: userId, budgetId: budget.id);
  }

  void _ensureUniqueCategoryForSelectedPeriod(CategoryBudget budget) {
    final normalizedCategory = budget.category.trim().toLowerCase();
    final duplicateExists = _budgets.any(
      (current) =>
          current.id != budget.id &&
          current.category.trim().toLowerCase() == normalizedCategory,
    );

    if (!duplicateExists) {
      return;
    }

    throw InputValidationException(
      'Budzet dla kategorii "${budget.category.trim()}" juz istnieje w tym okresie.',
    );
  }

  void _subscribe() {
    _subscription = repository
        .watchBudgets(userId: userId, periodStart: _selectedPeriod)
        .listen(
          (budgets) {
            _budgets = budgets;
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

  static DateTime _normalizePeriod(DateTime value) {
    return DateTime(value.year, value.month);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
