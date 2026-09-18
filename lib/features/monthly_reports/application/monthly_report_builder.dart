import '../../../models/finance_models.dart';
import '../../dashboard/dashboard_analytics.dart';

MonthlyReport buildMonthlyReport({
  required DateTime periodStart,
  required DateTime generatedAt,
  required List<FinanceTransaction> transactions,
  required List<CategoryBudget> budgets,
  required List<SavingsGoal> goals,
  required List<InvestmentHolding> investments,
}) {
  final normalizedPeriod = DateTime(periodStart.year, periodStart.month);
  final monthlyTransactions = transactions.where(
    (transaction) =>
        transaction.date.year == normalizedPeriod.year &&
        transaction.date.month == normalizedPeriod.month,
  );

  final incomeTotal = monthlyTransactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  final expenseTotal = monthlyTransactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  final transferTotal = monthlyTransactions
      .where((transaction) => transaction.type == TransactionType.transfer)
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  final budgetLimitTotal = budgets.fold<double>(
    0,
    (sum, budget) => sum + budget.limit,
  );
  final budgetSpentTotal = budgets.fold<double>(
    0,
    (sum, budget) => sum + budget.spent,
  );
  final analytics = DashboardAnalyticsSnapshot.fromData(
    transactions: transactions,
    investments: investments,
    goals: goals,
    referenceMonth: normalizedPeriod,
  );

  return MonthlyReport(
    id: monthlyReportIdForPeriod(normalizedPeriod),
    periodStart: normalizedPeriod,
    generatedAt: generatedAt,
    incomeTotal: incomeTotal,
    expenseTotal: expenseTotal,
    transferTotal: transferTotal,
    transactionCount: monthlyTransactions.length,
    budgetCount: budgets.length,
    overspentBudgetCount: budgets
        .where((budget) => budget.spent > budget.limit)
        .length,
    budgetLimitTotal: budgetLimitTotal,
    budgetSpentTotal: budgetSpentTotal,
    investmentValue: investments.fold<double>(
      0,
      (sum, investment) => sum + investment.currentValue,
    ),
    investmentProfit: investments.fold<double>(
      0,
      (sum, investment) => sum + investment.profit,
    ),
    transferRate: analytics.transferRate,
    activeGoals: analytics.activeGoals,
    completedGoals: analytics.completedGoals,
    atRiskGoals: analytics.atRiskGoals,
    topExpenseCategory: analytics.topExpenseCategory,
  );
}

String monthlyReportIdForPeriod(DateTime periodStart) {
  final normalizedPeriod = DateTime(periodStart.year, periodStart.month);
  final month = normalizedPeriod.month.toString().padLeft(2, '0');
  return '${normalizedPeriod.year}-$month';
}
