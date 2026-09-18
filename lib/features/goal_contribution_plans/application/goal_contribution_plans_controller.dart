import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../domain/goal_contribution_plan_repository.dart';

class GoalContributionPlansController extends ChangeNotifier {
  GoalContributionPlansController({
    required this.repository,
    required this.transactionRepository,
    required this.userId,
  }) {
    _subscription = repository
        .watchGoalContributionPlans(userId)
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

  final GoalContributionPlanRepository repository;
  final TransactionRepository transactionRepository;
  final String userId;
  late final StreamSubscription<List<GoalContributionPlan>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<GoalContributionPlan> _plans = const [];
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _lastSyncStateKey;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  List<GoalContributionPlan> get plans => _plans;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  List<GoalContributionPlan> get activePlans =>
      _plans.where((plan) => plan.isActive).toList();

  Future<void> save(GoalContributionPlan plan) async {
    final sanitizedPlan = FinanceInputSanitizer.sanitizeGoalContributionPlan(
      plan,
    );

    if (sanitizedPlan.isPersisted) {
      await repository.updateGoalContributionPlan(
        userId: userId,
        plan: sanitizedPlan,
      );
      return;
    }

    await repository.createGoalContributionPlan(
      userId: userId,
      plan: sanitizedPlan,
    );
  }

  Future<void> delete(GoalContributionPlan plan) {
    return repository.deleteGoalContributionPlan(
      userId: userId,
      planId: plan.id,
    );
  }

  Future<void> deletePlansForGoal(String goalId) {
    return repository.deletePlansForGoal(userId: userId, goalId: goalId);
  }

  List<GoalContributionPlan> plansForGoal(String goalId) {
    final normalizedGoalId = goalId.trim();
    return _plans.where((plan) => plan.goalId == normalizedGoalId).toList();
  }

  int activePlanCountForGoal(String goalId) {
    return plansForGoal(goalId).where((plan) => plan.isActive).length;
  }

  double monthlyEquivalentForGoal(String goalId) {
    return plansForGoal(goalId)
        .where((plan) => plan.isActive)
        .fold<double>(0, (sum, plan) => sum + plan.monthlyEquivalentAmount);
  }

  DateTime? nextContributionDate(GoalContributionPlan plan) {
    if (!plan.isActive) {
      return null;
    }

    final now = DateTime.now();
    var cursor = plan.lastGeneratedPeriodKey == null
        ? DateTime(plan.startDate.year, plan.startDate.month, 1)
        : _addMonths(
            _monthStartFromKey(plan.lastGeneratedPeriodKey!),
            plan.intervalMonthCount,
          );

    while (true) {
      final scheduledDate = plan.scheduledDateForPeriod(cursor);
      if (!scheduledDate.isBefore(plan.startDate) &&
          !scheduledDate.isBefore(now)) {
        return scheduledDate;
      }

      cursor = _addMonths(cursor, plan.intervalMonthCount);
    }
  }

  Future<void> syncTransactions({
    required List<FinanceTransaction> transactions,
    required List<SavingsGoal> goals,
  }) async {
    final now = DateTime.now();
    final stateKey = _buildSyncStateKey(
      transactions: transactions,
      goals: goals,
      now: now,
    );
    if (_isLoading ||
        _isSyncing ||
        _plans.isEmpty ||
        goals.isEmpty ||
        _lastSyncStateKey == stateKey) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final goalIds = goals.map((goal) => goal.id).toSet();
      final plansToAdvance = <GoalContributionPlan>[];

      for (final plan in _plans) {
        if (!plan.isActive || !goalIds.contains(plan.goalId)) {
          continue;
        }

        final duePeriods = _duePeriodStarts(plan, now);
        if (duePeriods.isEmpty) {
          continue;
        }

        for (final periodStart in duePeriods) {
          final scheduledDate = plan.scheduledDateForPeriod(periodStart);
          if (_hasGeneratedTransaction(plan, periodStart, transactions) ||
              _hasMatchingManualContribution(plan, periodStart, transactions)) {
            continue;
          }

          await transactionRepository.createTransaction(
            userId: userId,
            transaction: FinanceTransaction(
              id: '',
              title: plan.name,
              category: goalContributionCategory,
              amount: plan.amount,
              date: scheduledDate,
              type: TransactionType.transfer,
              goalId: plan.goalId,
              goalContributionPlanId: plan.id,
              note: plan.note,
            ),
          );
        }

        final lastProcessedKey = _monthKey(duePeriods.last);
        if (plan.lastGeneratedPeriodKey != lastProcessedKey) {
          plansToAdvance.add(
            plan.copyWith(lastGeneratedPeriodKey: lastProcessedKey),
          );
        }
      }

      for (final plan in plansToAdvance) {
        await repository.updateGoalContributionPlan(userId: userId, plan: plan);
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

  List<DateTime> _duePeriodStarts(GoalContributionPlan plan, DateTime now) {
    final periodStarts = <DateTime>[];
    final firstPeriod = DateTime(plan.startDate.year, plan.startDate.month, 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    final startPeriod = plan.lastGeneratedPeriodKey == null
        ? firstPeriod
        : _addMonths(
            _monthStartFromKey(plan.lastGeneratedPeriodKey!),
            plan.intervalMonthCount,
          );

    var cursor = DateTime(startPeriod.year, startPeriod.month, 1);
    while (!cursor.isAfter(currentMonth)) {
      final scheduledDate = plan.scheduledDateForPeriod(cursor);
      if (!scheduledDate.isBefore(plan.startDate) &&
          !scheduledDate.isAfter(now)) {
        periodStarts.add(cursor);
      }

      cursor = _addMonths(cursor, plan.intervalMonthCount);
    }

    return periodStarts;
  }

  bool _hasGeneratedTransaction(
    GoalContributionPlan plan,
    DateTime periodStart,
    List<FinanceTransaction> transactions,
  ) {
    return transactions.any(
      (transaction) =>
          transaction.goalContributionPlanId == plan.id &&
          transaction.date.year == periodStart.year &&
          transaction.date.month == periodStart.month,
    );
  }

  bool _hasMatchingManualContribution(
    GoalContributionPlan plan,
    DateTime periodStart,
    List<FinanceTransaction> transactions,
  ) {
    final normalizedName = plan.name.trim().toLowerCase();
    final normalizedCategory = goalContributionCategory.trim().toLowerCase();
    return transactions.any(
      (transaction) =>
          transaction.goalContributionPlanId == null &&
          transaction.goalId == plan.goalId &&
          transaction.type == TransactionType.transfer &&
          transaction.date.year == periodStart.year &&
          transaction.date.month == periodStart.month &&
          transaction.title.trim().toLowerCase() == normalizedName &&
          transaction.category.trim().toLowerCase() == normalizedCategory &&
          (transaction.amount - plan.amount).abs() < 0.0001,
    );
  }

  String _buildSyncStateKey({
    required List<FinanceTransaction> transactions,
    required List<SavingsGoal> goals,
    required DateTime now,
  }) {
    final goalKey = goals.map((goal) => goal.id).join('|');
    final planKey = _plans
        .map(
          (plan) => [
            plan.id,
            plan.goalId,
            plan.isActive,
            plan.name,
            plan.amount.toStringAsFixed(2),
            plan.interval.name,
            plan.dayOfMonth,
            plan.startDate.toIso8601String(),
            plan.lastGeneratedPeriodKey ?? '',
          ].join(':'),
        )
        .join('|');
    final transactionKey = transactions
        .map(
          (transaction) => [
            transaction.id,
            transaction.goalId ?? '',
            transaction.goalContributionPlanId ?? '',
            transaction.type.name,
            transaction.date.year,
            transaction.date.month,
            transaction.title,
            transaction.category,
            transaction.amount.toStringAsFixed(2),
          ].join(':'),
        )
        .join('|');
    final dayKey = '${now.year}-${now.month}-${now.day}';
    return '$dayKey#$goalKey#$planKey#$transactionKey';
  }

  DateTime _monthStartFromKey(String monthKey) {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  DateTime _addMonths(DateTime value, int monthsToAdd) {
    return DateTime(value.year, value.month + monthsToAdd, 1);
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
