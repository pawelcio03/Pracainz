import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/monthly_reports/application/monthly_report_builder.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('monthly report builder aggregates selected month snapshot', () {
    final report = buildMonthlyReport(
      periodStart: DateTime(2026, 6, 18),
      generatedAt: DateTime(2026, 6, 30, 21, 15),
      transactions: [
        FinanceTransaction(
          id: 'tx-1',
          title: 'Pensja',
          category: 'Praca',
          amount: 5000,
          date: DateTime(2026, 6, 5),
          type: TransactionType.income,
        ),
        FinanceTransaction(
          id: 'tx-2',
          title: 'Czynsz',
          category: 'Dom',
          amount: 1200,
          date: DateTime(2026, 6, 7),
          type: TransactionType.expense,
        ),
        FinanceTransaction(
          id: 'tx-3',
          title: 'Wplata do celu',
          category: 'Oszczednosci',
          amount: 500,
          date: DateTime(2026, 6, 9),
          type: TransactionType.transfer,
          goalId: 'goal-1',
        ),
        FinanceTransaction(
          id: 'tx-4',
          title: 'Stary koszt',
          category: 'Dom',
          amount: 300,
          date: DateTime(2026, 5, 20),
          type: TransactionType.expense,
        ),
      ],
      budgets: [
        CategoryBudget(
          id: 'budget-1',
          category: 'Dom',
          limit: 1000,
          spent: 1200,
          periodStart: DateTime(2026, 6, 1),
        ),
      ],
      goals: [
        SavingsGoal(
          id: 'goal-1',
          name: 'Poduszka',
          targetAmount: 5000,
          savedAmount: 2500,
          deadline: DateTime(2026, 12, 31),
        ),
        SavingsGoal(
          id: 'goal-2',
          name: 'Wakacje',
          targetAmount: 3000,
          savedAmount: 3000,
          deadline: DateTime(2026, 8, 31),
        ),
      ],
      investments: const [
        InvestmentHolding(
          id: 'investment-1',
          symbol: 'VWCE',
          name: 'ETF globalny',
          units: 3,
          buyPrice: 110,
          currentPrice: 123,
        ),
      ],
    );

    expect(report.id, '2026-06');
    expect(report.periodStart, DateTime(2026, 6, 1));
    expect(report.incomeTotal, 5000);
    expect(report.expenseTotal, 1200);
    expect(report.transferTotal, 500);
    expect(report.netCashflow, 3300);
    expect(report.transactionCount, 3);
    expect(report.budgetCount, 1);
    expect(report.overspentBudgetCount, 1);
    expect(report.budgetLimitTotal, 1000);
    expect(report.budgetSpentTotal, 1200);
    expect(report.investmentValue, 369);
    expect(report.investmentProfit, 39);
    expect(report.transferRate, 0.1);
    expect(report.topExpenseCategory, 'Dom');
    expect(report.activeGoals, 1);
    expect(report.completedGoals, 1);
    expect(report.atRiskGoals, 0);
  });
}
