import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/dashboard/dashboard_analytics.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'dashboard analytics aggregates transactions, goals and investments',
    () {
      final analytics = DashboardAnalyticsSnapshot.fromData(
        transactions: [
          FinanceTransaction(
            id: 'income-june',
            title: 'Pensja',
            category: 'Praca',
            amount: 10000,
            date: DateTime(2026, 6, 3),
            type: TransactionType.income,
          ),
          FinanceTransaction(
            id: 'expense-dom',
            title: 'Zakupy',
            category: 'Dom',
            amount: 1200,
            date: DateTime(2026, 6, 4),
            type: TransactionType.expense,
          ),
          FinanceTransaction(
            id: 'expense-transport',
            title: 'Paliwo',
            category: 'Transport',
            amount: 500,
            date: DateTime(2026, 6, 5),
            type: TransactionType.expense,
          ),
          FinanceTransaction(
            id: 'transfer-june',
            title: 'Wplata na poduszke',
            category: 'Oszczednosci',
            amount: 2000,
            date: DateTime(2026, 6, 6),
            type: TransactionType.transfer,
            goalId: 'goal-1',
          ),
          FinanceTransaction(
            id: 'income-may',
            title: 'Projekt',
            category: 'Freelance',
            amount: 3000,
            date: DateTime(2026, 5, 12),
            type: TransactionType.income,
          ),
          FinanceTransaction(
            id: 'expense-may',
            title: 'Rachunki',
            category: 'Dom',
            amount: 900,
            date: DateTime(2026, 5, 18),
            type: TransactionType.expense,
          ),
        ],
        investments: [
          InvestmentHolding(
            id: 'inv-1',
            symbol: 'VWCE',
            name: 'ETF globalny',
            units: 10,
            buyPrice: 100,
            currentPrice: 130,
          ),
          InvestmentHolding(
            id: 'inv-2',
            symbol: 'TSLA',
            name: 'Tesla',
            units: 2,
            buyPrice: 200,
            currentPrice: 150,
          ),
        ],
        goals: [
          SavingsGoal(
            id: 'goal-1',
            name: 'Poduszka',
            targetAmount: 10000,
            savedAmount: 3000,
            deadline: DateTime(2026, 6, 20),
          ),
          SavingsGoal(
            id: 'goal-2',
            name: 'Wakacje',
            targetAmount: 5000,
            savedAmount: 5000,
            deadline: DateTime(2026, 8, 10),
          ),
        ],
        referenceMonth: DateTime(2026, 6, 1),
        months: 3,
      );

      expect(analytics.monthlyCashflow, hasLength(3));
      expect(analytics.monthlyCashflow.last.income, 10000);
      expect(analytics.monthlyCashflow.last.expenses, 1700);
      expect(analytics.monthlyCashflow.last.transfers, 2000);
      expect(analytics.topExpenseCategory, 'Dom');
      expect(analytics.transferRate, closeTo(0.20, 0.01));
      expect(analytics.currentMonthTransfers, 2000);
      expect(analytics.averageExpense, closeTo((0 + 900 + 1700) / 3, 0.01));
      expect(analytics.completedGoals, 1);
      expect(analytics.activeGoals, 1);
      expect(analytics.atRiskGoals, 1);
      expect(analytics.portfolioAllocations.first.symbol, 'VWCE');
      expect(analytics.portfolioAllocations.first.share, closeTo(0.81, 0.01));
      expect(
        analytics.investmentAnalytics.weightedReturnRate,
        closeTo(0.14, 0.01),
      );
      expect(analytics.investmentAnalytics.holdingCount, 2);
      expect(analytics.investmentAnalytics.bestHolding?.symbol, 'VWCE');
      expect(analytics.investmentAnalytics.worstHolding?.symbol, 'TSLA');

      final alerts = buildDashboardAlerts(
        referenceMonth: DateTime(2026, 6, 1),
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
            targetAmount: 10000,
            savedAmount: 3000,
            deadline: DateTime(2026, 6, 20),
          ),
        ],
        subscriptions: [
          SubscriptionPlan(
            id: 'subscription-1',
            name: 'Netflix',
            category: 'Rozrywka',
            amount: 39.99,
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime(2026, 6, 5),
            isActive: true,
          ),
        ],
        investmentAnalytics: analytics.investmentAnalytics,
      );

      expect(alerts, isNotEmpty);
      expect(alerts.first.title, contains('Budzet przekroczony'));
    },
  );

  test('investment concentration alert describes capped portfolio share', () {
    final alerts = buildDashboardAlerts(
      referenceMonth: DateTime(2026, 6, 1),
      budgets: const [],
      goals: const [],
      subscriptions: const [],
      investmentAnalytics: const InvestmentAnalyticsSnapshot(
        holdingCount: 1,
        largestHoldingShare: 1.35,
        weightedReturnRate: 0,
        bestHolding: InvestmentPerformancePoint(
          symbol: 'BTCPLN',
          name: 'Bitcoin',
          currentValue: 1000,
          investedValue: 900,
          profit: 100,
          returnRate: 0.11,
        ),
        worstHolding: null,
        holdings: [],
      ),
    );

    final alert = alerts.single;
    expect(alert.title, 'Wysoka koncentracja portfela');
    expect(
      alert.message,
      'Najwieksza pozycja stanowi okolo 100% wartosci portfela.',
    );
    expect(alert.message, isNot(contains('przekracza')));
  });
}
