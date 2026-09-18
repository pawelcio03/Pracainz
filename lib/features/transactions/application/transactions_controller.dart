import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/transaction_repository.dart';

enum TransactionSortOption { newest, oldest, highestAmount, lowestAmount }

enum TransactionTypeFilter { all, income, expense, transfer }

enum TransactionRangeFilter { all, currentMonth, last30Days }

class TransactionsController extends ChangeNotifier {
  TransactionsController({required this.repository, required this.userId}) {
    _subscription = repository
        .watchTransactions(userId)
        .listen(
          (transactions) {
            _transactions = transactions;
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

  final TransactionRepository repository;
  final String userId;
  late final StreamSubscription<List<FinanceTransaction>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<FinanceTransaction> _transactions = const [];
  String _searchQuery = '';
  String? _categoryFilter;
  String? _goalFilter;
  TransactionSortOption _sortOption = TransactionSortOption.newest;
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  TransactionRangeFilter _rangeFilter = TransactionRangeFilter.all;

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<FinanceTransaction> get transactions => _transactions;

  String get searchQuery => _searchQuery;

  String? get categoryFilter => _categoryFilter;

  String? get goalFilter => _goalFilter;

  TransactionSortOption get sortOption => _sortOption;

  TransactionTypeFilter get typeFilter => _typeFilter;

  TransactionRangeFilter get rangeFilter => _rangeFilter;

  List<String> get availableCategories {
    final categories =
        _transactions
            .map((transaction) => transaction.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return categories;
  }

  List<FinanceTransaction> get visibleTransactions {
    var filtered = _transactions.where(_matchesFilters).toList();

    filtered.sort((left, right) {
      switch (_sortOption) {
        case TransactionSortOption.newest:
          return right.date.compareTo(left.date);
        case TransactionSortOption.oldest:
          return left.date.compareTo(right.date);
        case TransactionSortOption.highestAmount:
          return right.amount.compareTo(left.amount);
        case TransactionSortOption.lowestAmount:
          return left.amount.compareTo(right.amount);
      }
    });

    return filtered;
  }

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _categoryFilter != null ||
        _goalFilter != null ||
        _rangeFilter != TransactionRangeFilter.all ||
        _typeFilter != TransactionTypeFilter.all ||
        _sortOption != TransactionSortOption.newest;
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value.trim()) {
      return;
    }

    _searchQuery = value.trim();
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    final normalized = value == null || value.isEmpty ? null : value;
    if (_categoryFilter == normalized) {
      return;
    }

    _categoryFilter = normalized;
    notifyListeners();
  }

  void setGoalFilter(String? value) {
    final normalized = value == null || value.isEmpty ? null : value;
    if (_goalFilter == normalized) {
      return;
    }

    _goalFilter = normalized;
    notifyListeners();
  }

  void setSortOption(TransactionSortOption value) {
    if (_sortOption == value) {
      return;
    }

    _sortOption = value;
    notifyListeners();
  }

  void setTypeFilter(TransactionTypeFilter value) {
    if (_typeFilter == value) {
      return;
    }

    _typeFilter = value;
    notifyListeners();
  }

  void setRangeFilter(TransactionRangeFilter value) {
    if (_rangeFilter == value) {
      return;
    }

    _rangeFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilters) {
      return;
    }

    _searchQuery = '';
    _categoryFilter = null;
    _goalFilter = null;
    _rangeFilter = TransactionRangeFilter.all;
    _sortOption = TransactionSortOption.newest;
    _typeFilter = TransactionTypeFilter.all;
    notifyListeners();
  }

  Future<void> save(FinanceTransaction transaction) async {
    final sanitizedTransaction = FinanceInputSanitizer.sanitizeTransaction(
      transaction,
    );

    if (sanitizedTransaction.isPersisted) {
      await repository.updateTransaction(
        userId: userId,
        transaction: sanitizedTransaction,
      );
      return;
    }

    await repository.createTransaction(
      userId: userId,
      transaction: sanitizedTransaction,
    );
  }

  Future<void> delete(FinanceTransaction transaction) {
    return repository.deleteTransaction(
      userId: userId,
      transactionId: transaction.id,
    );
  }

  Future<int> deleteTransactionsByIds(List<String> transactionIds) async {
    final normalizedIds = transactionIds
        .map((transactionId) => transactionId.trim())
        .where((transactionId) => transactionId.isNotEmpty)
        .toSet()
        .toList();

    for (final transactionId in normalizedIds) {
      await repository.deleteTransaction(
        userId: userId,
        transactionId: transactionId,
      );
    }

    return normalizedIds.length;
  }

  Future<List<FinanceTransaction>> importTransactions(
    List<FinanceTransaction> transactions,
  ) async {
    final createdTransactions = <FinanceTransaction>[];
    for (final transaction in transactions) {
      final sanitizedTransaction = FinanceInputSanitizer.sanitizeTransaction(
        transaction,
      );
      final createdTransaction = await repository.createTransaction(
        userId: userId,
        transaction: sanitizedTransaction,
      );
      createdTransactions.add(createdTransaction);
    }

    return List<FinanceTransaction>.unmodifiable(createdTransactions);
  }

  bool _matchesFilters(FinanceTransaction transaction) {
    if (!_matchesRangeFilter(transaction)) {
      return false;
    }

    if (_typeFilter == TransactionTypeFilter.income &&
        transaction.type != TransactionType.income) {
      return false;
    }

    if (_typeFilter == TransactionTypeFilter.expense &&
        transaction.type != TransactionType.expense) {
      return false;
    }

    if (_typeFilter == TransactionTypeFilter.transfer &&
        transaction.type != TransactionType.transfer) {
      return false;
    }

    if (_categoryFilter != null && transaction.category != _categoryFilter) {
      return false;
    }

    if (_goalFilter != null && transaction.goalId != _goalFilter) {
      return false;
    }

    if (_searchQuery.isEmpty) {
      return true;
    }

    final normalizedQuery = _searchQuery.toLowerCase();
    final note = transaction.note?.toLowerCase() ?? '';

    return transaction.title.toLowerCase().contains(normalizedQuery) ||
        transaction.category.toLowerCase().contains(normalizedQuery) ||
        note.contains(normalizedQuery);
  }

  bool _matchesRangeFilter(FinanceTransaction transaction) {
    final now = DateTime.now();

    switch (_rangeFilter) {
      case TransactionRangeFilter.all:
        return true;
      case TransactionRangeFilter.currentMonth:
        return transaction.date.year == now.year &&
            transaction.date.month == now.month;
      case TransactionRangeFilter.last30Days:
        final threshold = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        return !transactionDate.isBefore(threshold);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
