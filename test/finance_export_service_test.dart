import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/export/application/finance_export_service.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = FinanceExportService();

  test('finance export service builds csv payload with main sections', () {
    final file = service.buildCsv(
      profile: UserProfile(
        userId: 'user-1',
        displayName: 'Pawel',
        email: 'pawel@example.com',
        createdAt: DateTime(2026, 1, 1),
        lastSignInAt: DateTime(2026, 6, 3),
        updatedAt: DateTime(2026, 6, 3),
      ),
      transactions: [
        FinanceTransaction(
          id: 'tx-1',
          title: 'Pensja',
          category: 'Praca',
          amount: 5000,
          date: DateTime(2026, 6, 1),
          type: TransactionType.income,
        ),
      ],
      budgets: [
        CategoryBudget(
          id: 'budget-1',
          category: 'Dom',
          limit: 1200,
          spent: 300,
          periodStart: DateTime(2026, 6, 1),
        ),
      ],
      goals: [
        SavingsGoal(
          id: 'goal-1',
          name: 'Poduszka',
          targetAmount: 10000,
          savedAmount: 2500,
          deadline: DateTime(2026, 12, 31),
        ),
      ],
      investments: [
        const InvestmentHolding(
          id: 'investment-1',
          assetType: InvestmentAssetType.etf,
          symbol: 'VWCE',
          name: 'ETF',
          units: 2,
          buyPrice: 100,
          currentPrice: 120,
        ),
      ],
      subscriptions: [
        SubscriptionPlan(
          id: 'subscription-1',
          name: 'Netflix',
          category: 'Rozrywka',
          amount: 39.99,
          billingCycle: SubscriptionBillingCycle.monthly,
          nextBillingDate: DateTime(2026, 6, 15),
          isActive: true,
        ),
      ],
      exportedAt: DateTime(2026, 6, 3, 12, 0),
    );

    final csv = utf8.decode(file.bytes);

    expect(file.filename.endsWith('.csv'), isTrue);
    expect(file.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(csv, contains('"profil";"display_name";"Pawel"'));
    expect(csv, contains('"transakcje";"tx-1";"Pensja";"Praca";"5000.00"'));
    expect(csv, contains('"budzety";"budget-1";"Dom";"1200.00";"300.00"'));
    expect(csv, contains('"cele";"goal-1";"Poduszka";"10000.00";"2500.00"'));
    expect(
      csv,
      contains('"inwestycje";"investment-1";"etf";"VWCE";"ETF";"2.0000"'),
    );
    expect(
      csv,
      contains('"subskrypcje";"subscription-1";"Netflix";"Rozrywka";"39.99"'),
    );
  });

  test('finance export service builds non-empty pdf payload', () async {
    final dashboard = DashboardSnapshot(
      userName: 'Pawel',
      transactions: [
        FinanceTransaction(
          id: 'tx-1',
          title: 'Pensja',
          category: 'Praca',
          amount: 5000,
          date: DateTime(2026, 6, 1),
          type: TransactionType.income,
        ),
      ],
      budgets: const [],
      goals: const [],
      investments: const [],
    );

    final file = await service.buildPdf(
      profile: UserProfile(
        userId: 'user-1',
        displayName: 'Pawel',
        email: 'pawel@example.com',
        createdAt: DateTime(2026, 1, 1),
        lastSignInAt: DateTime(2026, 6, 3),
        updatedAt: DateTime(2026, 6, 3),
      ),
      dashboard: dashboard,
      budgets: const [],
      goals: const [],
      investments: const [],
      subscriptions: const [],
      exportedAt: DateTime(2026, 6, 3, 12, 0),
    );

    expect(file.filename.endsWith('.pdf'), isTrue);
    expect(file.bytes.length, greaterThan(500));
    expect(file.bytes[0], equals(0x25));
    expect(file.bytes[1], equals(0x50));
    expect(file.bytes[2], equals(0x44));
    expect(file.bytes[3], equals(0x46));
  });
}
