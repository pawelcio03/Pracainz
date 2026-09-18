import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../domain/recurring_income_repository.dart';

class RecurringIncomesController extends ChangeNotifier {
  RecurringIncomesController({
    required this.repository,
    required this.transactionRepository,
    required this.userId,
  }) {
    _subscription = repository
        .watchRecurringIncomes(userId)
        .listen(
          (plans) {
            _plans = plans;
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

  final RecurringIncomeRepository repository;
  final TransactionRepository transactionRepository;
  final String userId;
  late final StreamSubscription<List<RecurringIncomePlan>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<RecurringIncomePlan> _plans = const [];
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastSyncStateKey;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<RecurringIncomePlan> get plans => _plans;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  List<RecurringIncomePlan> get activePlans =>
      _plans.where((plan) => plan.isActive).toList();

  double get monthlyIncomeTotal =>
      activePlans.fold<double>(0, (sum, plan) => sum + plan.amount);

  Future<void> save(RecurringIncomePlan plan) async {
    final sanitizedPlan = FinanceInputSanitizer.sanitizeRecurringIncomePlan(
      plan,
    );

    if (sanitizedPlan.isPersisted) {
      await repository.updateRecurringIncome(
        userId: userId,
        plan: sanitizedPlan,
      );
      return;
    }

    await repository.createRecurringIncome(userId: userId, plan: sanitizedPlan);
  }

  Future<void> delete(RecurringIncomePlan plan) {
    return repository.deleteRecurringIncome(
      userId: userId,
      recurringIncomeId: plan.id,
    );
  }

  Future<void> syncTransactions(List<FinanceTransaction> transactions) async {
    final now = DateTime.now();
    final stateKey = _buildSyncStateKey(transactions, now);
    if (_isLoading ||
        _isSyncing ||
        _plans.isEmpty ||
        _lastSyncStateKey == stateKey) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final plansToAdvance = <RecurringIncomePlan>[];

      for (final plan in _plans) {
        if (!plan.isActive) {
          continue;
        }

        final dueMonths = _dueMonthStarts(plan, now);
        if (dueMonths.isEmpty) {
          continue;
        }

        for (final monthStart in dueMonths) {
          final scheduledDate = plan.scheduledDateForMonth(monthStart);
          if (_hasGeneratedTransaction(plan, monthStart, transactions) ||
              _hasMatchingManualIncome(plan, monthStart, transactions)) {
            continue;
          }

          await transactionRepository.createTransaction(
            userId: userId,
            transaction: FinanceTransaction(
              id: '',
              title: plan.name,
              category: plan.category,
              amount: plan.amount,
              date: scheduledDate,
              type: TransactionType.income,
              recurringIncomeId: plan.id,
              note: plan.note,
            ),
          );
        }

        final lastProcessedMonth = dueMonths.last;
        final lastProcessedKey = _monthKey(lastProcessedMonth);
        if (plan.lastGeneratedMonthKey != lastProcessedKey) {
          plansToAdvance.add(
            plan.copyWith(lastGeneratedMonthKey: lastProcessedKey),
          );
        }
      }

      for (final plan in plansToAdvance) {
        await repository.updateRecurringIncome(userId: userId, plan: plan);
      }

      _lastSyncedAt = DateTime.now();
      _lastSyncStateKey = stateKey;
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  DateTime? nextPayoutDate(RecurringIncomePlan plan) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final currentScheduledDate = plan.scheduledDateForMonth(currentMonth);
    if (currentScheduledDate.isAfter(now) ||
        _monthKey(currentMonth) != plan.lastGeneratedMonthKey) {
      return currentScheduledDate.isBefore(plan.startDate)
          ? plan.startDate
          : currentScheduledDate;
    }

    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    final nextScheduledDate = plan.scheduledDateForMonth(nextMonth);
    return nextScheduledDate.isBefore(plan.startDate)
        ? plan.startDate
        : nextScheduledDate;
  }

  List<DateTime> _dueMonthStarts(RecurringIncomePlan plan, DateTime now) {
    final monthStarts = <DateTime>[];
    final firstMonth = DateTime(plan.startDate.year, plan.startDate.month, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    final startMonth = plan.lastGeneratedMonthKey == null
        ? firstMonth
        : _monthStartFromKey(
            plan.lastGeneratedMonthKey!,
          ).add(const Duration(days: 32));

    var cursor = DateTime(startMonth.year, startMonth.month, 1);
    while (!cursor.isAfter(currentMonth)) {
      final scheduledDate = plan.scheduledDateForMonth(cursor);
      if (!scheduledDate.isBefore(plan.startDate) &&
          !scheduledDate.isAfter(now)) {
        monthStarts.add(cursor);
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return monthStarts;
  }

  bool _hasGeneratedTransaction(
    RecurringIncomePlan plan,
    DateTime monthStart,
    List<FinanceTransaction> transactions,
  ) {
    return transactions.any(
      (transaction) =>
          transaction.recurringIncomeId == plan.id &&
          transaction.date.year == monthStart.year &&
          transaction.date.month == monthStart.month,
    );
  }

  bool _hasMatchingManualIncome(
    RecurringIncomePlan plan,
    DateTime monthStart,
    List<FinanceTransaction> transactions,
  ) {
    final normalizedName = plan.name.trim().toLowerCase();
    final normalizedCategory = plan.category.trim().toLowerCase();
    return transactions.any(
      (transaction) =>
          transaction.recurringIncomeId == null &&
          transaction.type == TransactionType.income &&
          transaction.date.year == monthStart.year &&
          transaction.date.month == monthStart.month &&
          transaction.title.trim().toLowerCase() == normalizedName &&
          transaction.category.trim().toLowerCase() == normalizedCategory &&
          (transaction.amount - plan.amount).abs() < 0.0001,
    );
  }

  String _buildSyncStateKey(
    List<FinanceTransaction> transactions,
    DateTime now,
  ) {
    final planKey = _plans
        .map(
          (plan) => [
            plan.id,
            plan.isActive,
            plan.name,
            plan.category,
            plan.amount.toStringAsFixed(2),
            plan.payday,
            plan.startDate.toIso8601String(),
            plan.lastGeneratedMonthKey ?? '',
          ].join(':'),
        )
        .join('|');
    final transactionKey = transactions
        .map(
          (transaction) => [
            transaction.id,
            transaction.recurringIncomeId ?? '',
            transaction.date.year,
            transaction.date.month,
            transaction.title,
            transaction.category,
            transaction.amount.toStringAsFixed(2),
          ].join(':'),
        )
        .join('|');
    final dayKey = '${now.year}-${now.month}-${now.day}';
    return '$dayKey#$planKey#$transactionKey';
  }

  DateTime _monthStartFromKey(String monthKey) {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  String _monthKey(DateTime monthStart) {
    final month = monthStart.month.toString().padLeft(2, '0');
    return '${monthStart.year}-$month';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
