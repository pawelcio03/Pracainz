import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/monthly_reports/application/monthly_report_comparison.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('finds exact previous month report and computes deltas', () {
    final previous = MonthlyReport(
      id: '2026-05',
      periodStart: DateTime(2026, 5, 1),
      generatedAt: DateTime(2026, 5, 31, 22),
      incomeTotal: 4200,
      expenseTotal: 1600,
      transferTotal: 300,
      transactionCount: 12,
      budgetCount: 3,
      overspentBudgetCount: 1,
      budgetLimitTotal: 3000,
      budgetSpentTotal: 2500,
      investmentValue: 10000,
      investmentProfit: 350,
      transferRate: 0.07,
      activeGoals: 2,
      completedGoals: 1,
      atRiskGoals: 0,
    );
    final current = MonthlyReport(
      id: '2026-06',
      periodStart: DateTime(2026, 6, 1),
      generatedAt: DateTime(2026, 6, 30, 22),
      incomeTotal: 5000,
      expenseTotal: 1800,
      transferTotal: 500,
      transactionCount: 15,
      budgetCount: 3,
      overspentBudgetCount: 2,
      budgetLimitTotal: 3000,
      budgetSpentTotal: 2900,
      investmentValue: 10300,
      investmentProfit: 420,
      transferRate: 0.1,
      activeGoals: 2,
      completedGoals: 1,
      atRiskGoals: 1,
    );

    final foundPrevious = previousMonthlyReportForPeriod([
      current,
      previous,
    ], current.periodStart);
    final comparison = compareMonthlyReports(
      current: current,
      previous: previous,
    );

    expect(foundPrevious?.id, '2026-05');
    expect(comparison.incomeDelta, 800);
    expect(comparison.expenseDelta, 200);
    expect(comparison.transferDelta, 200);
    expect(comparison.netCashflowDelta, 400);
    expect(comparison.transactionCountDelta, 3);
    expect(comparison.investmentProfitDelta, 70);
  });
}
