import '../../models/finance_models.dart';
import '../../core/formatting/display_number_formatter.dart';

class DashboardAnalyticsSnapshot {
  const DashboardAnalyticsSnapshot({
    required this.monthlyCashflow,
    required this.expensesByCategory,
    required this.portfolioAllocations,
    required this.transferRate,
    required this.currentMonthTransfers,
    required this.averageExpense,
    required this.topExpenseCategory,
    required this.activeGoals,
    required this.completedGoals,
    required this.atRiskGoals,
    required this.investmentAnalytics,
  });

  factory DashboardAnalyticsSnapshot.fromData({
    required List<FinanceTransaction> transactions,
    required List<InvestmentHolding> investments,
    required List<SavingsGoal> goals,
    DateTime? referenceMonth,
    int months = 6,
    DateTime? accountCreatedAt,
  }) {
    final normalizedReference = _monthStart(referenceMonth ?? DateTime.now());
    final normalizedAccountCreatedAt = accountCreatedAt == null
        ? null
        : _monthStart(accountCreatedAt);
    final shouldPadIntoFuture =
        normalizedAccountCreatedAt != null &&
        _monthDistanceInclusive(
              normalizedAccountCreatedAt,
              normalizedReference,
            ) <
            months;
    final firstMonth = shouldPadIntoFuture
        ? normalizedAccountCreatedAt
        : DateTime(
            normalizedReference.year,
            normalizedReference.month - (months - 1),
            1,
          );
    final monthPoints = <MonthlyCashflowPoint>[];

    for (var offset = 0; offset < months; offset++) {
      final month = DateTime(firstMonth.year, firstMonth.month + offset, 1);
      final monthlyTransactions = transactions.where(
        (transaction) =>
            transaction.date.year == month.year &&
            transaction.date.month == month.month,
      );
      final income = monthlyTransactions
          .where((transaction) => transaction.type == TransactionType.income)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final expenses = monthlyTransactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final transfers = monthlyTransactions
          .where((transaction) => transaction.type == TransactionType.transfer)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);

      monthPoints.add(
        MonthlyCashflowPoint(
          monthStart: month,
          label: _monthLabel(month),
          income: income,
          expenses: expenses,
          transfers: transfers,
          isFuture: month.isAfter(normalizedReference),
        ),
      );
    }

    final currentMonthTransactions = transactions.where(
      (transaction) =>
          transaction.date.year == normalizedReference.year &&
          transaction.date.month == normalizedReference.month,
    );
    final currentMonthIncome = currentMonthTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final currentMonthExpenses = currentMonthTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final currentMonthTransfers = currentMonthTransactions
        .where((transaction) => transaction.type == TransactionType.transfer)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final expenseTotals = <String, double>{};
    for (final transaction in currentMonthTransactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      expenseTotals.update(
        transaction.category,
        (amount) => amount + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final expensesByCategory =
        expenseTotals.entries
            .map(
              (entry) => CategoryExpensePoint(
                category: entry.key,
                amount: entry.value,
                share: currentMonthExpenses <= 0
                    ? 0
                    : entry.value / currentMonthExpenses,
              ),
            )
            .toList()
          ..sort((left, right) => right.amount.compareTo(left.amount));

    final historicalMonthPoints = monthPoints
        .where((point) => !point.isFuture)
        .toList();

    final portfolioTotal = investments.fold<double>(
      0,
      (sum, investment) => sum + investment.currentValue,
    );
    final portfolioAllocations =
        investments
            .map(
              (investment) => PortfolioAllocationPoint(
                symbol: investment.displaySymbol,
                name: investment.name,
                currentValue: investment.currentValue,
                share: portfolioTotal <= 0
                    ? 0
                    : investment.currentValue / portfolioTotal,
                profit: investment.profit,
              ),
            )
            .toList()
          ..sort(
            (left, right) => right.currentValue.compareTo(left.currentValue),
          );

    final completedGoals = goals.where((goal) => goal.progress >= 1).length;
    final activeGoals = goals.where((goal) => goal.progress < 1).length;
    final atRiskGoals = goals.where((goal) {
      if (goal.progress >= 1) {
        return false;
      }

      final daysToDeadline = goal.deadline
          .difference(normalizedReference)
          .inDays;
      return goal.deadline.isBefore(normalizedReference) ||
          (daysToDeadline <= 30 && goal.progress < 0.75);
    }).length;

    return DashboardAnalyticsSnapshot(
      monthlyCashflow: monthPoints,
      expensesByCategory: expensesByCategory.take(5).toList(),
      portfolioAllocations: portfolioAllocations.take(5).toList(),
      transferRate: currentMonthIncome <= 0
          ? 0
          : currentMonthTransfers / currentMonthIncome,
      currentMonthTransfers: currentMonthTransfers,
      averageExpense: historicalMonthPoints.isEmpty
          ? 0
          : historicalMonthPoints.fold<double>(
                  0,
                  (sum, point) => sum + point.expenses,
                ) /
                historicalMonthPoints.length,
      topExpenseCategory: expensesByCategory.isEmpty
          ? null
          : expensesByCategory.first.category,
      activeGoals: activeGoals,
      completedGoals: completedGoals,
      atRiskGoals: atRiskGoals,
      investmentAnalytics: InvestmentAnalyticsSnapshot.fromData(
        investments: investments,
      ),
    );
  }

  final List<MonthlyCashflowPoint> monthlyCashflow;
  final List<CategoryExpensePoint> expensesByCategory;
  final List<PortfolioAllocationPoint> portfolioAllocations;
  final double transferRate;
  final double currentMonthTransfers;
  final double averageExpense;
  final String? topExpenseCategory;
  final int activeGoals;
  final int completedGoals;
  final int atRiskGoals;
  final InvestmentAnalyticsSnapshot investmentAnalytics;

  bool get hasTransactionData => monthlyCashflow.any(
    (point) => point.income > 0 || point.expenses > 0 || point.transfers > 0,
  );

  bool get hasExpenseData => expensesByCategory.isNotEmpty;

  bool get hasInvestmentData => portfolioAllocations.isNotEmpty;
}

class MonthlyCashflowPoint {
  const MonthlyCashflowPoint({
    required this.monthStart,
    required this.label,
    required this.income,
    required this.expenses,
    required this.transfers,
    this.isFuture = false,
  });

  final DateTime monthStart;
  final String label;
  final double income;
  final double expenses;
  final double transfers;
  final bool isFuture;

  double get net => income - expenses - transfers;
}

class CategoryExpensePoint {
  const CategoryExpensePoint({
    required this.category,
    required this.amount,
    required this.share,
  });

  final String category;
  final double amount;
  final double share;
}

class PortfolioAllocationPoint {
  const PortfolioAllocationPoint({
    required this.symbol,
    required this.name,
    required this.currentValue,
    required this.share,
    required this.profit,
  });

  final String symbol;
  final String name;
  final double currentValue;
  final double share;
  final double profit;
}

class InvestmentAnalyticsSnapshot {
  const InvestmentAnalyticsSnapshot({
    required this.holdingCount,
    required this.largestHoldingShare,
    required this.weightedReturnRate,
    required this.bestHolding,
    required this.worstHolding,
    required this.holdings,
  });

  factory InvestmentAnalyticsSnapshot.fromData({
    required List<InvestmentHolding> investments,
  }) {
    final holdings =
        investments
            .map(
              (investment) => InvestmentPerformancePoint(
                symbol: investment.displaySymbol,
                name: investment.name,
                currentValue: investment.currentValue,
                investedValue: investment.investedValue,
                profit: investment.profit,
                returnRate: investment.investedValue <= 0
                    ? 0
                    : investment.profit / investment.investedValue,
              ),
            )
            .toList()
          ..sort((left, right) => right.returnRate.compareTo(left.returnRate));

    final totalCurrentValue = holdings.fold<double>(
      0,
      (sum, holding) => sum + holding.currentValue,
    );
    final totalInvestedValue = holdings.fold<double>(
      0,
      (sum, holding) => sum + holding.investedValue,
    );
    final totalProfit = holdings.fold<double>(
      0,
      (sum, holding) => sum + holding.profit,
    );
    final largestHolding = holdings.isEmpty
        ? null
        : holdings.reduce(
            (left, right) =>
                left.currentValue >= right.currentValue ? left : right,
          );
    return InvestmentAnalyticsSnapshot(
      holdingCount: holdings.length,
      largestHoldingShare: totalCurrentValue <= 0 || largestHolding == null
          ? 0
          : _clampPercent(largestHolding.currentValue / totalCurrentValue),
      weightedReturnRate: totalInvestedValue <= 0
          ? 0
          : totalProfit / totalInvestedValue,
      bestHolding: holdings.isEmpty ? null : holdings.first,
      worstHolding: holdings.isEmpty ? null : holdings.last,
      holdings: holdings,
    );
  }

  final int holdingCount;
  final double largestHoldingShare;
  final double weightedReturnRate;
  final InvestmentPerformancePoint? bestHolding;
  final InvestmentPerformancePoint? worstHolding;
  final List<InvestmentPerformancePoint> holdings;

  bool get hasData => holdings.isNotEmpty;
}

class InvestmentPerformancePoint {
  const InvestmentPerformancePoint({
    required this.symbol,
    required this.name,
    required this.currentValue,
    required this.investedValue,
    required this.profit,
    required this.returnRate,
  });

  final String symbol;
  final String name;
  final double currentValue;
  final double investedValue;
  final double profit;
  final double returnRate;
}

enum DashboardAlertSeverity { critical, warning, info }

class DashboardAlertItem {
  const DashboardAlertItem({
    required this.severity,
    required this.title,
    required this.message,
  });

  final DashboardAlertSeverity severity;
  final String title;
  final String message;
}

List<DashboardAlertItem> buildDashboardAlerts({
  required DateTime referenceMonth,
  required List<CategoryBudget> budgets,
  required List<SavingsGoal> goals,
  required List<SubscriptionPlan> subscriptions,
  required InvestmentAnalyticsSnapshot investmentAnalytics,
}) {
  final alerts = <DashboardAlertItem>[];

  for (final budget in budgets) {
    if (budget.limit <= 0) {
      continue;
    }

    if (budget.spent > budget.limit) {
      final overflow = budget.spent - budget.limit;
      alerts.add(
        DashboardAlertItem(
          severity: DashboardAlertSeverity.critical,
          title: 'Budzet przekroczony: ${budget.category}',
          message:
              'Przekroczenie o ${formatDisplayCurrency(overflow)} w okresie ${_periodLabel(budget.periodStart)}.',
        ),
      );
      continue;
    }

    if (budget.progress >= 0.85) {
      alerts.add(
        DashboardAlertItem(
          severity: DashboardAlertSeverity.warning,
          title: 'Budzet blisko limitu: ${budget.category}',
          message:
              'Wykorzystanie ${(_clampPercent(budget.progress) * 100).toStringAsFixed(0)}% w okresie ${_periodLabel(budget.periodStart)}.',
        ),
      );
    }
  }

  for (final goal in goals) {
    if (goal.progress >= 1) {
      continue;
    }

    final daysToDeadline = goal.deadline.difference(referenceMonth).inDays;
    if (goal.deadline.isBefore(referenceMonth) ||
        (daysToDeadline <= 30 && goal.progress < 0.75)) {
      alerts.add(
        DashboardAlertItem(
          severity: DashboardAlertSeverity.warning,
          title: 'Cel zagrozony: ${goal.name}',
          message:
              'Postep ${(_clampPercent(goal.progress) * 100).toStringAsFixed(0)}%, termin ${_date(goal.deadline)}.',
        ),
      );
    }
  }

  for (final subscription in subscriptions) {
    if (!subscription.isActive) {
      continue;
    }

    final daysToCharge = _dayStart(
      subscription.nextBillingDate,
    ).difference(_dayStart(referenceMonth)).inDays;
    if (daysToCharge < 0 || daysToCharge > 7) {
      continue;
    }

    alerts.add(
      DashboardAlertItem(
        severity: daysToCharge <= 2
            ? DashboardAlertSeverity.warning
            : DashboardAlertSeverity.info,
        title: 'Nadchodzi obciazenie: ${subscription.name}',
        message:
            '${formatDisplayCurrency(subscription.amount)} ${_subscriptionCycleLabel(subscription.billingCycle)}, termin ${_date(subscription.nextBillingDate)}.',
      ),
    );
  }

  if (investmentAnalytics.largestHoldingShare >= 0.5 &&
      investmentAnalytics.bestHolding != null) {
    final largestHoldingSharePercent =
        (_clampPercent(investmentAnalytics.largestHoldingShare) * 100)
            .toStringAsFixed(0);
    alerts.add(
      DashboardAlertItem(
        severity: DashboardAlertSeverity.warning,
        title: 'Wysoka koncentracja portfela',
        message:
            'Najwieksza pozycja stanowi okolo $largestHoldingSharePercent% wartosci portfela.',
      ),
    );
  }

  final worstHolding = investmentAnalytics.worstHolding;
  if (worstHolding != null && worstHolding.returnRate <= -0.12) {
    alerts.add(
      DashboardAlertItem(
        severity: DashboardAlertSeverity.critical,
        title: 'Slaba pozycja: ${worstHolding.symbol}',
        message:
            'Stopa zwrotu ${(worstHolding.returnRate * 100).toStringAsFixed(1)}%. Warto sprawdzic ekspozycje.',
      ),
    );
  }

  alerts.sort((left, right) {
    final severityDiff = _severityRank(
      right.severity,
    ).compareTo(_severityRank(left.severity));
    if (severityDiff != 0) {
      return severityDiff;
    }

    return left.title.compareTo(right.title);
  });

  return alerts.take(6).toList();
}

int _severityRank(DashboardAlertSeverity severity) {
  switch (severity) {
    case DashboardAlertSeverity.critical:
      return 3;
    case DashboardAlertSeverity.warning:
      return 2;
    case DashboardAlertSeverity.info:
      return 1;
  }
}

double _clampPercent(double value) {
  return value.clamp(0, 1);
}

DateTime _monthStart(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

int _monthDistanceInclusive(DateTime start, DateTime end) {
  return (end.year - start.year) * 12 + end.month - start.month + 1;
}

DateTime _dayStart(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _periodLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '$month.${date.year}';
}

String _subscriptionCycleLabel(SubscriptionBillingCycle cycle) {
  switch (cycle) {
    case SubscriptionBillingCycle.monthly:
      return 'miesiecznie';
    case SubscriptionBillingCycle.quarterly:
      return 'kwartalnie';
    case SubscriptionBillingCycle.yearly:
      return 'rocznie';
  }
}

String _monthLabel(DateTime date) {
  const monthLabels = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paz',
    'lis',
    'gru',
  ];
  return '${monthLabels[date.month - 1]} ${date.year.toString().substring(2)}';
}
