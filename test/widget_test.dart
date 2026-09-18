import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/app.dart';
import 'package:finovo/core/app/app_dependencies.dart';
import 'package:finovo/core/app/theme_preferences_repository.dart';
import 'package:finovo/core/firebase/firebase_bootstrap.dart';
import 'package:finovo/features/auth/presentation/auth_gate.dart';
import 'package:finovo/features/auth/presentation/app_bootstrap_screen.dart';
import 'package:finovo/features/auth/presentation/auth_screen.dart';
import 'package:finovo/features/auth/domain/account_security_snapshot.dart';
import 'package:finovo/features/auth/domain/auth_repository.dart';
import 'package:finovo/features/budgets/domain/budget_repository.dart';
import 'package:finovo/features/categories/domain/category_repository.dart';
import 'package:finovo/features/export/domain/export_share_gateway.dart';
import 'package:finovo/features/dashboard/dashboard_screen.dart';
import 'package:finovo/features/goal_contribution_plans/domain/goal_contribution_plan_repository.dart';
import 'package:finovo/features/goals/domain/goal_repository.dart';
import 'package:finovo/features/investments/domain/investment_repository.dart';
import 'package:finovo/features/monthly_reports/domain/monthly_report_repository.dart';
import 'package:finovo/features/portfolio_snapshots/domain/portfolio_snapshot_repository.dart';
import 'package:finovo/features/profile/domain/user_profile_repository.dart';
import 'package:finovo/features/recurring_incomes/domain/recurring_income_repository.dart';
import 'package:finovo/features/report_archives/domain/report_archive_repository.dart';
import 'package:finovo/features/subscriptions/domain/subscription_repository.dart';
import 'package:finovo/features/transactions/domain/transaction_repository.dart';
import 'package:finovo/models/finance_models.dart';

void _ignoreThemeMode(ThemeMode _) {}

Future<void> _openSection(WidgetTester tester, String label) async {
  final finder = find.byKey(
    ValueKey('sidebar-section-${_sidebarSectionName(label)}'),
  );
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openAccountWorkspaceSection(
  WidgetTester tester,
  String label,
) async {
  final finder = find.byKey(
    ValueKey('account-workspace-${_accountWorkspaceName(label)}'),
  );
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _sidebarSectionName(String label) {
  switch (label) {
    case 'Przeglad':
      return 'overview';
    case 'Transakcje':
      return 'transactions';
    case 'Budzety':
      return 'budgets';
    case 'Cele':
      return 'goals';
    case 'Inwestycje':
      return 'investments';
    case 'Subskrypcje':
      return 'subscriptions';
    case 'Raporty':
      return 'reports';
    case 'Kategorie':
      return 'categories';
    case 'Konto':
      return 'account';
  }

  throw ArgumentError.value(label, 'label', 'Unknown dashboard section');
}

String _accountWorkspaceName(String label) {
  switch (label) {
    case 'Konto':
      return 'profile';
    case 'Dostep':
      return 'access';
    case 'Dane':
      return 'data';
    case 'Wyglad':
      return 'appearance';
  }

  throw ArgumentError.value(label, 'label', 'Unknown account workspace');
}

String _portfolioPeriodLabelMonthsAgo(int monthsAgo) {
  final monthStart = DateTime(
    DateTime.now().year,
    DateTime.now().month - monthsAgo,
    1,
  );
  final month = monthStart.month.toString().padLeft(2, '0');
  return '$month.${monthStart.year}';
}

String _portfolioPeriodLabelFromDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '$month.${date.year}';
}

String _earliestVisiblePeriodLabel({
  required int selectedMonths,
  required DateTime createdAt,
}) {
  final now = DateTime.now();
  final normalizedCreatedAt = DateTime(createdAt.year, createdAt.month, 1);
  final earliestRequested = DateTime(
    now.year,
    now.month - (selectedMonths - 1),
    1,
  );
  final visibleStart = normalizedCreatedAt.isAfter(earliestRequested)
      ? normalizedCreatedAt
      : earliestRequested;
  return _portfolioPeriodLabelFromDate(visibleStart);
}

void main() {
  testWidgets('bootstrap renders loading placeholder while setup is pending', (
    tester,
  ) async {
    final completer = Completer<FirebaseBootstrapResult>();

    await tester.pumpWidget(
      FinanceApp(
        dependencies: AppDependencies(
          bootstrap: () => completer.future,
          authRepository: const _FakeAuthRepository(),
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          portfolioSnapshotRepository: const _FakePortfolioSnapshotRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          recurringIncomeRepository: const _FakeRecurringIncomeRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          themePreferencesRepository: const _FakeThemePreferencesRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Uruchamianie aplikacji'), findsOneWidget);
    expect(
      find.text('Laczenie z uslugami i przygotowanie sesji uzytkownika.'),
      findsOneWidget,
    );
  });

  testWidgets('auth screen renders when bootstrap succeeds', (tester) async {
    await tester.pumpWidget(
      FinanceApp(
        dependencies: AppDependencies(
          bootstrap: () async => const FirebaseBootstrapResult.ready(),
          authRepository: const _FakeAuthRepository(),
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          portfolioSnapshotRepository: const _FakePortfolioSnapshotRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          recurringIncomeRepository: const _FakeRecurringIncomeRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          themePreferencesRepository: const _FakeThemePreferencesRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Zaloguj sie'), findsAtLeastNWidgets(1));
    expect(find.text('Zaloguj przez Google'), findsOneWidget);
    expect(find.text('Reset hasla'), findsOneWidget);
    expect(find.text('Adres e-mail'), findsOneWidget);
    expect(find.text('Haslo'), findsOneWidget);
  });

  testWidgets('auth screen toggles password visibility', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AuthScreen(authRepository: _FakeAuthRepository()),
      ),
    );

    await tester.pumpAndSettle();

    EditableText passwordField() =>
        tester.widget<EditableText>(find.byType(EditableText).at(1));

    expect(passwordField().obscureText, isTrue);
    expect(find.byTooltip('Pokaz haslo'), findsOneWidget);

    await tester.tap(find.byTooltip('Pokaz haslo'));
    await tester.pumpAndSettle();

    expect(passwordField().obscureText, isFalse);
    expect(find.byTooltip('Ukryj haslo'), findsOneWidget);
  });

  testWidgets('auth screen shows inline success after password reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _RecordingAuthRepository();

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authRepository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'pawel@example.com',
    );
    await tester.tap(find.text('Reset hasla'));
    await tester.pumpAndSettle();

    expect(repository.lastResetEmail, 'pawel@example.com');
    expect(
      find.text('Wyslano link do resetu hasla na pawel@example.com.'),
      findsOneWidget,
    );
  });

  testWidgets('auth screen triggers google sign in', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _RecordingAuthRepository();

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authRepository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Zaloguj przez Google'));
    await tester.pumpAndSettle();

    expect(repository.googleSignInCallCount, 1);
  });

  testWidgets('auth screen requires matching passwords during registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _RecordingAuthRepository();

    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authRepository: repository)),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejestracja'));
    await tester.pumpAndSettle();

    expect(find.text('Powtorz haslo'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nazwa profilu'),
      'Pawel',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adres e-mail'),
      'pawel@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Haslo'),
      'haslo123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Powtorz haslo'),
      'inne123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Utworz konto'));
    await tester.pumpAndSettle();

    expect(find.text('Hasla musza byc takie same.'), findsOneWidget);
    expect(repository.registerCallCount, 0);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Powtorz haslo'),
      'haslo123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Utworz konto'));
    await tester.pumpAndSettle();

    expect(repository.registerCallCount, 1);
    expect(repository.lastRegisteredDisplayName, 'Pawel');
    expect(repository.lastRegisteredEmail, 'pawel@example.com');
    expect(repository.lastRegisteredPassword, 'haslo123');
  });

  testWidgets(
    'auth gate renders loading placeholder while session is pending',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            dependencies: AppDependencies(
              bootstrap: () async => const FirebaseBootstrapResult.ready(),
              authRepository: const _PendingAuthRepository(),
              budgetRepository: const _FakeBudgetRepository(),
              categoryRepository: const _FakeCategoryRepository(),
              exportShareGateway: const _FakeExportShareGateway(),
              goalRepository: const _FakeGoalRepository(),
              investmentRepository: const _FakeInvestmentRepository(),
              monthlyReportRepository: const _FakeMonthlyReportRepository(),
              reportArchiveRepository: const _FakeReportArchiveRepository(),
              recurringIncomeRepository: const _FakeRecurringIncomeRepository(),
              subscriptionRepository: const _FakeSubscriptionRepository(),
              themePreferencesRepository:
                  const _FakeThemePreferencesRepository(),
              transactionRepository: const _FakeTransactionRepository(),
              userProfileRepository: const _FakeUserProfileRepository(),
            ),
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Przywracanie sesji'), findsOneWidget);
      expect(
        find.text(
          'Sprawdzanie aktywnego logowania i przygotowanie panelu uzytkownika.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('finance app restores saved theme mode', (tester) async {
    await tester.pumpWidget(
      FinanceApp(
        dependencies: AppDependencies(
          bootstrap: () async => const FirebaseBootstrapResult.ready(),
          authRepository: const _FakeAuthRepository(),
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          portfolioSnapshotRepository: const _FakePortfolioSnapshotRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          recurringIncomeRepository: const _FakeRecurringIncomeRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          themePreferencesRepository: const _FakeThemePreferencesRepository(
            initialThemeMode: ThemeMode.dark,
          ),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets(
    'app bootstrap initializes firebase only once across theme changes',
    (tester) async {
      var bootstrapCallCount = 0;

      await tester.pumpWidget(
        _BootstrapThemeHost(
          dependencies: AppDependencies(
            bootstrap: () async {
              bootstrapCallCount++;
              return const FirebaseBootstrapResult.ready();
            },
            authRepository: const _FakeAuthRepository(),
            budgetRepository: const _FakeBudgetRepository(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalRepository: const _FakeGoalRepository(),
            investmentRepository: const _FakeInvestmentRepository(),
            monthlyReportRepository: const _FakeMonthlyReportRepository(),
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            recurringIncomeRepository: const _FakeRecurringIncomeRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            themePreferencesRepository: const _FakeThemePreferencesRepository(),
            transactionRepository: const _FakeTransactionRepository(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(bootstrapCallCount, 1);

      await tester.tap(find.text('Przelacz motyw'));
      await tester.pumpAndSettle();

      expect(bootstrapCallCount, 1);
    },
  );

  testWidgets(
    'dashboard keeps account appearance panel selected after theme change',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const _DashboardThemeHost());

      await tester.pumpAndSettle();

      await _openSection(tester, 'Konto');
      await _openAccountWorkspaceSection(tester, 'Wyglad');

      expect(find.text('Wyglad i sesja'), findsOneWidget);

      await tester.tap(find.text('Ciemny'));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('Wyglad i sesja'), findsOneWidget);
      expect(find.text('Wyglad aplikacji'), findsOneWidget);
    },
  );

  testWidgets(
    'overview keeps transaction analytics and investments own portfolio analytics',
    (tester) async {
      final profileCreatedAt = DateTime(2026, 1, 10);
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final monthlyReportRepository = _MutableMonthlyReportRepository([
        MonthlyReport(
          id: 'report-2026-05',
          periodStart: DateTime(2026, 5, 1),
          generatedAt: DateTime(2026, 5, 31, 21, 45),
          incomeTotal: 0,
          expenseTotal: 0,
          transferTotal: 0,
          transactionCount: 0,
          budgetCount: 0,
          overspentBudgetCount: 0,
          budgetLimitTotal: 0,
          budgetSpentTotal: 0,
          investmentValue: 320,
          investmentProfit: 30,
          transferRate: 0,
          activeGoals: 0,
          completedGoals: 0,
          atRiskGoals: 0,
        ),
      ]);
      addTearDown(monthlyReportRepository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _BudgetRepositoryWithData(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalRepository: const _GoalRepositoryWithData(),
            investmentRepository: const _InvestmentRepositoryWithData(),
            monthlyReportRepository: monthlyReportRepository,
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository: const _MonthlyReportTransactionRepository(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trend przychodow i wydatkow'), findsOneWidget);
      expect(find.text('z ostatnich 6 miesiecy'), findsOneWidget);
      expect(find.text('Analityka portfela'), findsNothing);
      expect(find.text('Alokacja portfela'), findsNothing);
      expect(find.text('Wartosc portfela w czasie'), findsNothing);

      await tester.tap(find.text('12M'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Trend przychodow i wydatkow 12 mies. od startu konta oraz struktura wydatkow dla wybranego okresu.',
        ),
        findsOneWidget,
      );

      await _openSection(tester, 'Inwestycje');

      expect(find.text('Analityka portfela'), findsOneWidget);
      expect(find.text('Alokacja portfela'), findsOneWidget);
      expect(find.text('Wartosc portfela w czasie'), findsOneWidget);
      expect(find.text('Teraz'), findsOneWidget);

      await tester.tap(find.text('12M').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Na podstawie historii raportow i biezacej wyceny 12 mies. od startu konta',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          _earliestVisiblePeriodLabel(
            selectedMonths: 12,
            createdAt: profileCreatedAt,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(_portfolioPeriodLabelMonthsAgo(11)), findsNothing);
      expect(find.text('Teraz'), findsOneWidget);

      final mayLabelFinder = find.text('05.2026');
      await tester.ensureVisible(mayLabelFinder);
      await tester.tap(mayLabelFinder);
      await tester.pumpAndSettle();

      expect(find.text('31.05.2026 21:45'), findsOneWidget);

      await tester.tap(find.text('3M').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Wartosc portfela w czasie'), findsOneWidget);
      expect(find.text('Teraz'), findsOneWidget);
    },
  );

  testWidgets(
    'investments chart keeps current month report point alongside Teraz',
    (tester) async {
      final now = DateTime.now();
      tester.view.physicalSize = const Size(1440, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final currentPeriodStart = DateTime(now.year, now.month, 1);
      final currentPeriodLabel = _portfolioPeriodLabelFromDate(now);
      final currentShortDateLabel =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
      final currentReportGeneratedAt = DateTime(
        now.year,
        now.month,
        now.day,
        9,
        30,
      );
      final currentReportDetailLabel =
          '${currentReportGeneratedAt.day.toString().padLeft(2, '0')}.'
          '${currentReportGeneratedAt.month.toString().padLeft(2, '0')}.'
          '${currentReportGeneratedAt.year} 09:30';
      final monthlyReportRepository = _MutableMonthlyReportRepository([
        MonthlyReport(
          id: 'report-current',
          periodStart: currentPeriodStart,
          generatedAt: currentReportGeneratedAt,
          incomeTotal: 0,
          expenseTotal: 0,
          transferTotal: 0,
          transactionCount: 0,
          budgetCount: 0,
          overspentBudgetCount: 0,
          budgetLimitTotal: 0,
          budgetSpentTotal: 0,
          investmentValue: 410,
          investmentProfit: 40,
          transferRate: 0,
          activeGoals: 0,
          completedGoals: 0,
          atRiskGoals: 0,
        ),
      ]);
      addTearDown(monthlyReportRepository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _BudgetRepositoryWithData(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalRepository: const _GoalRepositoryWithData(),
            investmentRepository: const _InvestmentRepositoryWithData(),
            monthlyReportRepository: monthlyReportRepository,
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository: const _MonthlyReportTransactionRepository(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _openSection(tester, 'Inwestycje');

      expect(find.text('Wartosc portfela w czasie'), findsOneWidget);
      expect(find.text('0 zl'), findsOneWidget);
      expect(find.text(currentPeriodLabel), findsOneWidget);
      expect(find.text('Teraz'), findsOneWidget);
      expect(find.text(currentShortDateLabel), findsOneWidget);

      await tester.tap(find.text(currentPeriodLabel));
      await tester.pumpAndSettle();

      expect(find.text(currentReportDetailLabel), findsOneWidget);
    },
  );

  testWidgets('investments chart shows daily portfolio snapshots', (
    tester,
  ) async {
    final now = DateTime.now();
    final snapshotDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final snapshotLabel =
        '${snapshotDate.day.toString().padLeft(2, '0')}.${snapshotDate.month.toString().padLeft(2, '0')}';
    final snapshotRepository = _MutablePortfolioSnapshotRepository([
      PortfolioDailySnapshot(
        id: 'snapshot-1',
        recordedAt: DateTime(
          snapshotDate.year,
          snapshotDate.month,
          snapshotDate.day,
          8,
        ),
        value: 405,
      ),
    ]);
    addTearDown(snapshotRepository.dispose);

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          dailyPortfolioSnapshotRepository: snapshotRepository,
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Inwestycje');

    expect(
      find.text(
        'Na podstawie dziennych zapisow portfela i biezacej wyceny z ostatnich 6 miesiecy',
      ),
      findsOneWidget,
    );
    expect(find.text(snapshotLabel), findsOneWidget);
    expect(find.text('Teraz'), findsOneWidget);
  });

  testWidgets('investments chart does not duplicate today date label', (
    tester,
  ) async {
    final now = DateTime.now();
    final currentShortDateLabel =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}';
    final snapshotRepository = _MutablePortfolioSnapshotRepository([
      PortfolioDailySnapshot(
        id: 'snapshot-today',
        recordedAt: DateTime(now.year, now.month, now.day, 8),
        value: 405,
      ),
    ]);
    addTearDown(snapshotRepository.dispose);

    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          dailyPortfolioSnapshotRepository: snapshotRepository,
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Inwestycje');

    expect(find.text(currentShortDateLabel), findsOneWidget);
    expect(find.text('Teraz'), findsOneWidget);
  });

  testWidgets('overview keeps centered single-month cashflow chart', (
    tester,
  ) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: _FakeUserProfileRepository(
            createdAtYear: now.year,
            createdAtMonth: now.month,
            createdAtDay: 2,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'Masz dopiero jeden miesiac historii, wiec zamiast wykresu pokazuje sie szybkie podsumowanie.',
      ),
      findsNothing,
    );
    expect(find.text('Biezacy miesiac'), findsNothing);
    expect(find.text('Przychody'), findsOneWidget);
    expect(find.text('Wydatki'), findsOneWidget);
    expect(find.text('Transfery'), findsOneWidget);
  });

  testWidgets('dashboard restores collapsed sidebar and allows expanding it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          dailyPortfolioSnapshotRepository:
              const _FakePortfolioSnapshotRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          themePreferencesRepository: const _FakeThemePreferencesRepository(
            initialSidebarCollapsed: true,
          ),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jasny'), findsNothing);

    await tester.tap(find.byTooltip('Rozwin menu').first);
    await tester.pumpAndSettle();

    expect(find.text('Jasny'), findsOneWidget);
  });

  testWidgets('dashboard exposes compact bottom navigation and more sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          dailyPortfolioSnapshotRepository:
              const _FakePortfolioSnapshotRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Wiecej'), findsOneWidget);

    await tester.tap(find.text('Transakcje'));
    await tester.pumpAndSettle();

    expect(find.text('Importuj wyciag'), findsAtLeastNWidgets(1));
    expect(find.text('Dodaj recznie'), findsOneWidget);
    expect(find.text('Sortowanie'), findsOneWidget);

    await tester.tap(find.text('Wiecej'));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);

    await tester.tap(find.text('Inwestycje').last);
    await tester.pumpAndSettle();

    expect(find.text('Dodaj inwestycje'), findsAtLeastNWidgets(1));
  });

  testWidgets('dashboard remembers scroll position per section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MutableTransactionRepository(
      List<FinanceTransaction>.generate(
        40,
        (index) => FinanceTransaction(
          id: 'tx-$index',
          title: 'Transakcja ${index.toString().padLeft(2, '0')}',
          category: index.isEven ? 'Dom' : 'Praca',
          amount: 100 + index.toDouble(),
          date: DateTime(2026, 1, 1).add(Duration(days: index)),
          type: index.isEven ? TransactionType.expense : TransactionType.income,
        ),
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: repository,
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Transakcje');

    final targetFinder = find.text('Transakcja 00');
    final initialTop = tester.getTopLeft(targetFinder).dy;
    await tester.dragUntilVisible(
      targetFinder,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    final beforeTop = tester.getTopLeft(targetFinder).dy;
    expect(beforeTop, lessThan(initialTop - 500));

    await _openSection(tester, 'Budzety');
    await _openSection(tester, 'Transakcje');

    final afterTop = tester.getTopLeft(targetFinder).dy;
    expect((afterTop - beforeTop).abs(), lessThan(24));
  });

  testWidgets(
    'transactions module shows view summary and daily balance headers',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _BudgetRepositoryWithData(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalRepository: const _GoalRepositoryWithData(),
            investmentRepository: const _InvestmentRepositoryWithData(),
            monthlyReportRepository: const _FakeMonthlyReportRepository(),
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository: const _MonthlyReportTransactionRepository(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _openSection(tester, 'Transakcje');

      expect(find.text('Przeglad widoku'), findsOneWidget);
      expect(find.text('Rytm wydatkow'), findsOneWidget);
      expect(find.text('Top kategoria wydatkow'), findsOneWidget);
      expect(find.textContaining('Bilans dnia'), findsNWidgets(3));
    },
  );

  testWidgets('transactions module filters by time range', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final repository = _MutableTransactionRepository([
      FinanceTransaction(
        id: 'tx-current',
        title: 'Aktualna transakcja',
        category: 'Praca',
        amount: 4200,
        date: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 2)),
        type: TransactionType.income,
      ),
      FinanceTransaction(
        id: 'tx-30',
        title: 'Z ostatnich 30 dni',
        category: 'Dom',
        amount: 300,
        date: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 20)),
        type: TransactionType.expense,
      ),
      FinanceTransaction(
        id: 'tx-old',
        title: 'Stara transakcja',
        category: 'Praca',
        amount: 1000,
        date: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 50)),
        type: TransactionType.income,
      ),
    ]);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalContributionPlanRepository:
              const _FakeGoalContributionPlanRepository(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: repository,
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Transakcje');

    expect(find.text('Aktualna transakcja'), findsOneWidget);
    expect(find.text('Z ostatnich 30 dni'), findsOneWidget);
    expect(find.text('Stara transakcja'), findsOneWidget);

    await tester.tap(find.text('30 dni'));
    await tester.pumpAndSettle();

    expect(find.text('Aktualna transakcja'), findsOneWidget);
    expect(find.text('Z ostatnich 30 dni'), findsOneWidget);
    expect(find.text('Stara transakcja'), findsNothing);

    await tester.tap(find.text('Miesiac'));
    await tester.pumpAndSettle();

    expect(find.text('Aktualna transakcja'), findsOneWidget);
    expect(find.text('Z ostatnich 30 dni'), findsNothing);
    expect(find.text('Stara transakcja'), findsNothing);

    await tester.tap(find.text('Calosc'));
    await tester.pumpAndSettle();

    expect(find.text('Stara transakcja'), findsOneWidget);
  });

  testWidgets(
    'goals module shows recurring contribution plans in tile and details',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _BudgetRepositoryWithData(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalContributionPlanRepository:
                const _GoalContributionPlanRepositoryWithData(),
            goalRepository: const _GoalRepositoryWithData(),
            investmentRepository: const _InvestmentRepositoryWithData(),
            monthlyReportRepository: const _FakeMonthlyReportRepository(),
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository:
                const _TransactionRepositoryWithTimelineData(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _openSection(tester, 'Cele');

      expect(find.text('Plan wplat'), findsOneWidget);
      expect(find.textContaining('Plany 1'), findsOneWidget);

      await tester.tap(find.text('Szczegoly').first);
      await tester.pumpAndSettle();

      expect(find.text('Plany cyklicznych wplat'), findsOneWidget);
      expect(find.text('Wplata do Poduszka'), findsOneWidget);
      expect(find.textContaining('Co miesiac'), findsOneWidget);
    },
  );

  testWidgets('dashboard renders reports responsively on narrow mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final monthlyReportRepository = _MutableMonthlyReportRepository();
    final archiveRepository = _MutableReportArchiveRepository();
    addTearDown(monthlyReportRepository.dispose);
    addTearDown(archiveRepository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: monthlyReportRepository,
          reportArchiveRepository: archiveRepository,
          subscriptionRepository: const _SubscriptionRepositoryWithData(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Wiecej'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Raporty').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Zapisz raport').first);
    await tester.tap(find.text('Zapisz raport').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Archiwizuj CSV'));
    await tester.tap(find.text('Archiwizuj CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Raport 06.2026'), findsOneWidget);
    expect(find.text('Pobierz'), findsAtLeastNWidgets(1));
  });

  testWidgets('goal card shows linked contribution history', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _TransactionRepositoryWithData(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Cele');

    expect(find.textContaining('Stan poczatkowy 1 000,00 zl'), findsOneWidget);
    expect(find.text('Ostatnie wplaty (1)'), findsOneWidget);
    expect(find.text('Wplata na poduszke'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'editing goal keeps stored starting amount without contributions',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final goalRepository = _RecordingGoalRepository([
        SavingsGoal(
          id: 'goal-1',
          name: 'Poduszka',
          targetAmount: 5000,
          savedAmount: 1000,
          deadline: DateTime(2026, 12, 31),
        ),
      ]);
      addTearDown(goalRepository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _FakeBudgetRepository(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalRepository: goalRepository,
            investmentRepository: const _FakeInvestmentRepository(),
            monthlyReportRepository: const _FakeMonthlyReportRepository(),
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository: const _TransactionRepositoryWithData(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _openSection(tester, 'Cele');

      expect(
        find.textContaining('Stan poczatkowy 1 000,00 zl'),
        findsOneWidget,
      );
      expect(find.textContaining('wplaty 300,00 zl'), findsOneWidget);
      expect(find.text('1 300,00 zl / 5 000,00 zl'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edytuj').last);
      await tester.pumpAndSettle();

      expect(find.text('1000,00'), findsOneWidget);
      expect(find.text('1300,00'), findsNothing);

      await tester.tap(find.text('Zapisz cel'));
      await tester.pumpAndSettle();

      expect(goalRepository.updatedGoals.single.savedAmount, 1000);
    },
  );

  testWidgets('goal details screen shows full timeline', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _TransactionRepositoryWithTimelineData(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Cele');

    await tester.ensureVisible(find.text('Szczegoly').first);
    await tester.tap(find.text('Szczegoly').first);
    await tester.pumpAndSettle();

    expect(find.text('Prognoza dojscia do celu'), findsOneWidget);
    expect(find.text('Pelna os czasu wplat'), findsOneWidget);
    expect(find.text('Liczba wplat'), findsOneWidget);
    expect(find.text('Wplata druga'), findsOneWidget);
    expect(find.text('Wplata pierwsza'), findsOneWidget);
  });

  testWidgets('goal details screen edits a contribution from timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MutableTransactionRepository([
      FinanceTransaction(
        id: 'tx-2',
        title: 'Wplata druga',
        category: 'Oszczednosci',
        amount: 400,
        date: DateTime(2026, 6, 10),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
      FinanceTransaction(
        id: 'tx-1',
        title: 'Wplata pierwsza',
        category: 'Oszczednosci',
        amount: 300,
        date: DateTime(2026, 6, 2),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
    ]);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: repository,
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Cele');

    await tester.ensureVisible(find.text('Szczegoly').first);
    await tester.tap(find.text('Szczegoly').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edytuj wplate'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Edytuj wplate').first);
    await tester.pumpAndSettle();

    expect(find.text('Edytuj transakcje'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Wplata poprawiona',
    );
    await tester.tap(find.text('Zapisz zmiany'));
    await tester.pumpAndSettle();

    expect(find.text('Wplata poprawiona'), findsOneWidget);
    expect(find.text('Wplata druga'), findsNothing);
  });

  testWidgets('goal details screen deletes a contribution from timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MutableTransactionRepository([
      FinanceTransaction(
        id: 'tx-2',
        title: 'Wplata druga',
        category: 'Oszczednosci',
        amount: 400,
        date: DateTime(2026, 6, 10),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
      FinanceTransaction(
        id: 'tx-1',
        title: 'Wplata pierwsza',
        category: 'Oszczednosci',
        amount: 300,
        date: DateTime(2026, 6, 2),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
    ]);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: repository,
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Cele');

    await tester.ensureVisible(find.text('Szczegoly').first);
    await tester.tap(find.text('Szczegoly').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Usun wplate'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Usun wplate').first);
    await tester.pumpAndSettle();

    expect(find.text('Usunac transakcje?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Usun'));
    await tester.pumpAndSettle();

    expect(find.text('Wplata druga'), findsNothing);
    expect(find.text('Wplata pierwsza'), findsOneWidget);
    expect(find.byTooltip('Usun wplate'), findsOneWidget);
  });

  testWidgets('dashboard renders categories from repository', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalContributionPlanRepository:
              const _FakeGoalContributionPlanRepository(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Kategorie');

    expect(find.text('Kategorie'), findsAtLeastNWidgets(1));
    expect(find.text('Praca'), findsOneWidget);
    expect(find.text('Dom'), findsOneWidget);
    expect(find.text('Oszczednosci'), findsOneWidget);
  });

  testWidgets('dashboard renders profile data from repository', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Fallback',
          userEmail: 'fallback@example.com',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalContributionPlanRepository:
              const _FakeGoalContributionPlanRepository(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Konto');

    expect(find.text('Dane konta'), findsAtLeastNWidgets(1));
    expect(find.text('Pawel Profil'), findsAtLeastNWidgets(1));
    expect(find.text('pawel@example.com'), findsAtLeastNWidgets(1));
  });

  testWidgets('dashboard profile renders initials without profile image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Fallback',
          userEmail: 'fallback@example.com',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalContributionPlanRepository:
              const _FakeGoalContributionPlanRepository(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(
            photoUrl: 'https://google.example/avatar.png',
            customPhotoUrl: 'https://storage.example/custom-avatar.png',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Konto');

    expect(find.byType(Image), findsNothing);
    expect(find.text('Widok'), findsNothing);
    expect(find.text('Inicjal'), findsNothing);
    expect(find.text('Pawel Profil'), findsAtLeastNWidgets(1));
  });

  testWidgets('dashboard opens account security sheet and sends reset link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authRepository = _RecordingAuthRepository(
      securitySnapshot: const AccountSecuritySnapshot(
        email: 'pawel@example.com',
        emailVerified: false,
        providerIds: <String>['password', 'google.com'],
        hasPasswordProvider: true,
        hasGoogleProvider: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          authRepository: authRepository,
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalContributionPlanRepository:
              const _FakeGoalContributionPlanRepository(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Konto');
    await _openAccountWorkspaceSection(tester, 'Dostep');

    expect(find.text('E-mail zweryfikowany'), findsOneWidget);
    expect(find.text('E-mail niezweryfikowany'), findsOneWidget);

    await tester.tap(find.text('Bezpieczenstwo konta'));
    await tester.pumpAndSettle();

    expect(find.text('Bezpieczenstwo konta'), findsAtLeastNWidgets(1));
    expect(find.text('Wyslij e-mail weryfikacyjny'), findsOneWidget);
    expect(find.text('Reset hasla'), findsAtLeastNWidgets(1));
    expect(find.text('Zmien e-mail'), findsAtLeastNWidgets(1));
    expect(find.text('Zmien haslo'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Reset hasla').last);
    await tester.pumpAndSettle();

    expect(authRepository.currentUserResetCallCount, 1);
    expect(
      find.text('Wyslano link do resetu hasla na adres konta.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'dashboard security sheet blocks password actions for Google-only account',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authRepository = _RecordingAuthRepository(
        securitySnapshot: const AccountSecuritySnapshot(
          email: 'pawel@example.com',
          emailVerified: true,
          providerIds: <String>['google.com'],
          hasPasswordProvider: false,
          hasGoogleProvider: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            userId: 'user-1',
            authRepository: authRepository,
            themeMode: ThemeMode.light,
            onThemeModeChanged: _ignoreThemeMode,
            userName: 'Pawel',
            budgetRepository: const _FakeBudgetRepository(),
            categoryRepository: const _FakeCategoryRepository(),
            exportShareGateway: const _FakeExportShareGateway(),
            goalContributionPlanRepository:
                const _FakeGoalContributionPlanRepository(),
            goalRepository: const _FakeGoalRepository(),
            investmentRepository: const _FakeInvestmentRepository(),
            monthlyReportRepository: const _FakeMonthlyReportRepository(),
            reportArchiveRepository: const _FakeReportArchiveRepository(),
            subscriptionRepository: const _FakeSubscriptionRepository(),
            transactionRepository: const _FakeTransactionRepository(),
            userProfileRepository: const _FakeUserProfileRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await _openSection(tester, 'Konto');
      await _openAccountWorkspaceSection(tester, 'Dostep');

      expect(find.text('E-mail zweryfikowany'), findsAtLeastNWidgets(1));
      expect(find.text('Tak'), findsOneWidget);
      expect(find.text('Logowanie'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);

      await tester.tap(find.text('Bezpieczenstwo konta'));
      await tester.pumpAndSettle();

      expect(find.text('Bezpieczenstwo konta'), findsAtLeastNWidgets(1));
      expect(find.text('Bez hasla'), findsOneWidget);
      expect(find.text('Google aktywne'), findsOneWidget);
      expect(find.text('Zmiana e-maila niedostepna'), findsOneWidget);
      expect(find.text('Zmiana hasla niedostepna'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nowy e-mail'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Nowe haslo'), findsNothing);
      expect(find.text('Zmien e-mail'), findsNothing);
      expect(find.text('Zmien haslo'), findsNothing);

      final resetButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Reset hasla'),
      );
      expect(resetButton.onPressed, isNull);

      expect(authRepository.currentUserResetCallCount, 0);
      expect(authRepository.lastUpdatedEmail, isNull);
      expect(authRepository.lastNewPassword, isNull);
    },
  );

  testWidgets('dashboard security sheet requests email change', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authRepository = _RecordingAuthRepository(
      securitySnapshot: const AccountSecuritySnapshot(
        email: 'pawel@example.com',
        emailVerified: false,
        providerIds: <String>['password'],
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          authRepository: authRepository,
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Konto');
    await _openAccountWorkspaceSection(tester, 'Dostep');
    await tester.tap(find.text('Bezpieczenstwo konta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nowy e-mail'),
      'nowy@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Aktualne haslo').first,
      'stare123',
    );
    await tester.tap(find.text('Zmien e-mail').last);
    await tester.pumpAndSettle();

    expect(authRepository.lastUpdatedEmail, 'nowy@example.com');
    expect(authRepository.lastEmailCurrentPassword, 'stare123');
    expect(
      find.textContaining('Wyslano link potwierdzajacy zmiane e-maila'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('dashboard security sheet changes password', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authRepository = _RecordingAuthRepository(
      securitySnapshot: const AccountSecuritySnapshot(
        email: 'pawel@example.com',
        emailVerified: true,
        providerIds: <String>['password'],
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          authRepository: authRepository,
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Konto');
    await _openAccountWorkspaceSection(tester, 'Dostep');
    await tester.tap(find.text('Bezpieczenstwo konta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Aktualne haslo').last,
      'stare123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nowe haslo'),
      'nowe123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Powtorz nowe haslo'),
      'nowe123',
    );
    await tester.tap(find.text('Zmien haslo').last);
    await tester.pumpAndSettle();

    expect(authRepository.lastCurrentPassword, 'stare123');
    expect(authRepository.lastNewPassword, 'nowe123');
    expect(find.text('Haslo zostalo zmienione.'), findsAtLeastNWidgets(1));
  });

  testWidgets('investment details screen shows holding details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Inwestycje');

    await tester.ensureVisible(find.text('Szczegoly').first);
    await tester.tap(find.text('Szczegoly').first);
    await tester.pumpAndSettle();

    expect(find.text('Pozycja i aktualna wycena'), findsOneWidget);
    expect(find.text('Historia cen zamkniecia'), findsOneWidget);
    expect(find.text('Jednostki'), findsOneWidget);
  });

  testWidgets('dashboard saves monthly report snapshot', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MutableMonthlyReportRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: repository,
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Raporty');

    expect(find.text('Raporty miesieczne'), findsOneWidget);
    expect(find.text('Zapisz raport'), findsAtLeastNWidgets(1));

    await tester.ensureVisible(find.text('Zapisz raport').first);
    await tester.tap(find.text('Zapisz raport').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Raport 06.2026'), findsOneWidget);
    expect(find.textContaining('Biezacy okres'), findsOneWidget);
  });

  testWidgets('dashboard closes selected month and locks report actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _MutableMonthlyReportRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: repository,
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _FakeSubscriptionRepository(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Raporty');

    await tester.ensureVisible(find.text('Zamknij miesiac').first);
    await tester.tap(find.text('Zamknij miesiac').first);
    await tester.pumpAndSettle();

    expect(find.text('Zamknac miesiac?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Zamknij'));
    await tester.pumpAndSettle();

    expect(find.text('Miesiac zamkniety'), findsAtLeastNWidgets(1));
    expect(find.text('Zamkniety'), findsAtLeastNWidgets(1));
  });

  testWidgets('dashboard renders subscriptions from repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _FakeBudgetRepository(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _FakeGoalRepository(),
          investmentRepository: const _FakeInvestmentRepository(),
          monthlyReportRepository: const _FakeMonthlyReportRepository(),
          reportArchiveRepository: const _FakeReportArchiveRepository(),
          subscriptionRepository: const _SubscriptionRepositoryWithData(),
          transactionRepository: const _FakeTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Subskrypcje');

    expect(find.text('Subskrypcje'), findsAtLeastNWidgets(1));
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.textContaining('Miesieczne obciazenie'), findsOneWidget);
  });

  testWidgets('dashboard archives monthly csv report', (tester) async {
    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final monthlyReportRepository = _MutableMonthlyReportRepository();
    final archiveRepository = _MutableReportArchiveRepository();
    addTearDown(monthlyReportRepository.dispose);
    addTearDown(archiveRepository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: const _FakeExportShareGateway(),
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: monthlyReportRepository,
          reportArchiveRepository: archiveRepository,
          subscriptionRepository: const _SubscriptionRepositoryWithData(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Raporty');

    await tester.ensureVisible(find.text('Zapisz raport').first);
    await tester.tap(find.text('Zapisz raport').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Archiwizuj CSV'));
    await tester.tap(find.text('Archiwizuj CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('.csv'), findsOneWidget);
  });

  testWidgets('dashboard opens archived report from storage list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final shareGateway = _RecordingExportShareGateway();
    final monthlyReportRepository = _MutableMonthlyReportRepository();
    final archiveRepository = _MutableReportArchiveRepository();
    addTearDown(monthlyReportRepository.dispose);
    addTearDown(archiveRepository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          userId: 'user-1',
          themeMode: ThemeMode.light,
          onThemeModeChanged: _ignoreThemeMode,
          userName: 'Pawel',
          budgetRepository: const _BudgetRepositoryWithData(),
          categoryRepository: const _FakeCategoryRepository(),
          exportShareGateway: shareGateway,
          goalRepository: const _GoalRepositoryWithData(),
          investmentRepository: const _InvestmentRepositoryWithData(),
          monthlyReportRepository: monthlyReportRepository,
          reportArchiveRepository: archiveRepository,
          subscriptionRepository: const _SubscriptionRepositoryWithData(),
          transactionRepository: const _MonthlyReportTransactionRepository(),
          userProfileRepository: const _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _openSection(tester, 'Raporty');

    await tester.ensureVisible(find.text('Archiwizuj CSV'));
    await tester.tap(find.text('Archiwizuj CSV'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pobierz'));
    await tester.tap(find.text('Pobierz').first);
    await tester.pumpAndSettle();

    expect(shareGateway.lastSharedFile, isNotNull);
    expect(shareGateway.lastSharedFile!.filename.endsWith('.csv'), isTrue);
  });
}

class _BootstrapThemeHost extends StatefulWidget {
  const _BootstrapThemeHost({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_BootstrapThemeHost> createState() => _BootstrapThemeHostState();
}

class _BootstrapThemeHostState extends State<_BootstrapThemeHost> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _themeMode = _themeMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                });
              },
              child: const Text('Przelacz motyw'),
            ),
            Expanded(
              child: AppBootstrapScreen(
                dependencies: widget.dependencies,
                themeMode: _themeMode,
                onThemeModeChanged: (value) {
                  setState(() {
                    _themeMode = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardThemeHost extends StatefulWidget {
  const _DashboardThemeHost();

  @override
  State<_DashboardThemeHost> createState() => _DashboardThemeHostState();
}

class _DashboardThemeHostState extends State<_DashboardThemeHost> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: DashboardScreen(
        userId: 'user-1',
        themeMode: _themeMode,
        onThemeModeChanged: (value) {
          setState(() {
            _themeMode = value;
          });
        },
        userName: 'Pawel',
        budgetRepository: const _FakeBudgetRepository(),
        categoryRepository: const _FakeCategoryRepository(),
        exportShareGateway: const _FakeExportShareGateway(),
        goalRepository: const _FakeGoalRepository(),
        investmentRepository: const _FakeInvestmentRepository(),
        monthlyReportRepository: const _FakeMonthlyReportRepository(),
        reportArchiveRepository: const _FakeReportArchiveRepository(),
        subscriptionRepository: const _FakeSubscriptionRepository(),
        themePreferencesRepository: const _FakeThemePreferencesRepository(
          initialSidebarCollapsed: true,
        ),
        transactionRepository: const _FakeTransactionRepository(),
        userProfileRepository: const _FakeUserProfileRepository(),
      ),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository();

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AccountSecuritySnapshot> getAccountSecuritySnapshot() async =>
      const AccountSecuritySnapshot(
        email: 'test@example.com',
        emailVerified: false,
        providerIds: <String>['password'],
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      );

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmailToCurrentUser() async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class _PendingAuthRepository implements AuthRepository {
  const _PendingAuthRepository();

  @override
  Stream<User?> authStateChanges() {
    return Stream<User?>.fromFuture(Completer<User?>().future);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AccountSecuritySnapshot> getAccountSecuritySnapshot() async =>
      const AccountSecuritySnapshot(
        email: 'test@example.com',
        emailVerified: false,
        providerIds: <String>['password'],
        hasPasswordProvider: true,
        hasGoogleProvider: false,
      );

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordResetEmailToCurrentUser() async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class _RecordingAuthRepository implements AuthRepository {
  _RecordingAuthRepository({AccountSecuritySnapshot? securitySnapshot})
    : _securitySnapshot =
          securitySnapshot ??
          const AccountSecuritySnapshot(
            email: 'pawel@example.com',
            emailVerified: false,
            providerIds: <String>['password'],
            hasPasswordProvider: true,
            hasGoogleProvider: false,
          );

  final AccountSecuritySnapshot _securitySnapshot;
  String? _lastResetEmail;
  String? _lastRegisteredEmail;
  String? _lastRegisteredPassword;
  String? _lastRegisteredDisplayName;
  String? _lastUpdatedDisplayName;
  String? _lastUpdatedEmail;
  String? _lastEmailCurrentPassword;
  String? _lastCurrentPassword;
  String? _lastNewPassword;
  int _registerCallCount = 0;
  int _googleSignInCallCount = 0;
  int _sendEmailVerificationCallCount = 0;
  int _currentUserResetCallCount = 0;

  String? get lastResetEmail => _lastResetEmail;
  String? get lastRegisteredEmail => _lastRegisteredEmail;
  String? get lastRegisteredPassword => _lastRegisteredPassword;
  String? get lastRegisteredDisplayName => _lastRegisteredDisplayName;
  String? get lastUpdatedDisplayName => _lastUpdatedDisplayName;
  String? get lastUpdatedEmail => _lastUpdatedEmail;
  String? get lastEmailCurrentPassword => _lastEmailCurrentPassword;
  String? get lastCurrentPassword => _lastCurrentPassword;
  String? get lastNewPassword => _lastNewPassword;
  int get registerCallCount => _registerCallCount;
  int get googleSignInCallCount => _googleSignInCallCount;
  int get sendEmailVerificationCallCount => _sendEmailVerificationCallCount;
  int get currentUserResetCallCount => _currentUserResetCallCount;

  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _registerCallCount++;
    _lastRegisteredEmail = email;
    _lastRegisteredPassword = password;
    _lastRegisteredDisplayName = displayName;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _lastResetEmail = email;
  }

  @override
  Future<AccountSecuritySnapshot> getAccountSecuritySnapshot() async =>
      _securitySnapshot;

  @override
  Future<void> sendEmailVerification() async {
    _sendEmailVerificationCallCount++;
  }

  @override
  Future<void> sendPasswordResetEmailToCurrentUser() async {
    _currentUserResetCallCount++;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    _lastUpdatedDisplayName = displayName;
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    _lastEmailCurrentPassword = currentPassword;
    _lastUpdatedEmail = newEmail;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _lastCurrentPassword = currentPassword;
    _lastNewPassword = newPassword;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {
    _googleSignInCallCount++;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeThemePreferencesRepository implements ThemePreferencesRepository {
  const _FakeThemePreferencesRepository({
    this.initialThemeMode,
    this.initialSidebarCollapsed,
  });

  final ThemeMode? initialThemeMode;
  final bool? initialSidebarCollapsed;

  @override
  Future<ThemeMode?> loadThemeMode() async => initialThemeMode;

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {}

  @override
  Future<bool?> loadSidebarCollapsed() async => initialSidebarCollapsed;

  @override
  Future<void> saveSidebarCollapsed(bool isCollapsed) async {}
}

class _FakeTransactionRepository implements TransactionRepository {
  const _FakeTransactionRepository();

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    return transaction;
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {}

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return Stream<List<FinanceTransaction>>.value(const []);
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  const _FakeBudgetRepository();

  @override
  Future<void> createBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {}

  @override
  Future<void> deleteBudget({
    required String userId,
    required String budgetId,
  }) async {}

  @override
  Future<void> updateBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {}

  @override
  Stream<List<CategoryBudget>> watchBudgets({
    required String userId,
    required DateTime periodStart,
  }) {
    return Stream<List<CategoryBudget>>.value(const []);
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  const _FakeCategoryRepository();

  @override
  Future<void> createCategory({
    required String userId,
    required FinanceCategory category,
  }) async {}

  @override
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {}

  @override
  Future<void> ensureDefaultCategories({
    required String userId,
    required List<FinanceCategory> defaults,
  }) async {}

  @override
  Future<void> mergeCategory({
    required String userId,
    required FinanceCategory sourceCategory,
    required FinanceCategory targetCategory,
  }) async {}

  @override
  Future<CategoryUsageSummary> readCategoryUsage({
    required String userId,
    required FinanceCategory category,
  }) async {
    return const CategoryUsageSummary();
  }

  @override
  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  }) async {}

  @override
  Stream<List<FinanceCategory>> watchCategories(String userId) {
    return Stream<List<FinanceCategory>>.value([
      FinanceCategory(
        id: 'category-1',
        name: 'Praca',
        type: TransactionType.income,
      ),
      FinanceCategory(
        id: 'category-2',
        name: 'Dom',
        type: TransactionType.expense,
      ),
      FinanceCategory(
        id: 'category-3',
        name: 'Oszczednosci',
        type: TransactionType.transfer,
      ),
    ]);
  }
}

class _FakeUserProfileRepository implements UserProfileRepository {
  const _FakeUserProfileRepository({
    this.photoUrl,
    this.customPhotoUrl,
    this.createdAtYear = 2026,
    this.createdAtMonth = 1,
    this.createdAtDay = 10,
  });

  final String? photoUrl;
  final String? customPhotoUrl;
  final int createdAtYear;
  final int createdAtMonth;
  final int createdAtDay;

  @override
  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
  }) async {}

  @override
  Future<void> updateProfile({
    required String userId,
    required UserProfile profile,
  }) async {}

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return Stream<UserProfile?>.value(
      UserProfile(
        userId: userId,
        displayName: 'Pawel Profil',
        email: 'pawel@example.com',
        photoUrl: photoUrl,
        customPhotoUrl: customPhotoUrl,
        createdAt: DateTime(createdAtYear, createdAtMonth, createdAtDay),
        lastSignInAt: DateTime(2026, 6, 3),
        updatedAt: DateTime(2026, 6, 3),
      ),
    );
  }
}

class _FakeExportShareGateway implements ExportShareGateway {
  const _FakeExportShareGateway();

  @override
  Future<void> share(ExportFilePayload file) async {}
}

class _RecordingExportShareGateway implements ExportShareGateway {
  ExportFilePayload? lastSharedFile;

  @override
  Future<void> share(ExportFilePayload file) async {
    lastSharedFile = file;
  }
}

class _FakeGoalRepository implements GoalRepository {
  const _FakeGoalRepository();

  @override
  Future<void> createGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {}

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<void> updateGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {}

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) {
    return Stream<List<SavingsGoal>>.value(const []);
  }
}

class _GoalRepositoryWithData implements GoalRepository {
  const _GoalRepositoryWithData();

  @override
  Future<void> createGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {}

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<void> updateGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {}

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) {
    return Stream<List<SavingsGoal>>.value([
      SavingsGoal(
        id: 'goal-1',
        name: 'Poduszka',
        targetAmount: 5000,
        savedAmount: 1000,
        deadline: DateTime(2026, 12, 31),
      ),
    ]);
  }
}

class _RecordingGoalRepository implements GoalRepository {
  _RecordingGoalRepository(List<SavingsGoal> seedGoals)
    : _goals = List<SavingsGoal>.from(seedGoals);

  final List<SavingsGoal> _goals;
  final List<SavingsGoal> updatedGoals = <SavingsGoal>[];
  final StreamController<List<SavingsGoal>> _updates =
      StreamController<List<SavingsGoal>>.broadcast();

  void dispose() {
    _updates.close();
  }

  @override
  Future<void> createGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {
    _goals.add(goal);
    _emit();
  }

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    _goals.removeWhere((goal) => goal.id == goalId);
    _emit();
  }

  @override
  Future<void> updateGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {
    updatedGoals.add(goal);
    final index = _goals.indexWhere((current) => current.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      _emit();
    }
  }

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) async* {
    yield List<SavingsGoal>.unmodifiable(_goals);
    yield* _updates.stream;
  }

  void _emit() {
    _updates.add(List<SavingsGoal>.unmodifiable(_goals));
  }
}

class _FakeInvestmentRepository implements InvestmentRepository {
  const _FakeInvestmentRepository();

  @override
  Future<void> createInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {}

  @override
  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  }) async {}

  @override
  Future<void> clearPriceHistory({
    required String userId,
    required String investmentId,
  }) async {}

  @override
  Future<void> upsertPriceHistoryPoints({
    required String userId,
    required String investmentId,
    required List<InvestmentPricePoint> pricePoints,
  }) async {}

  @override
  Future<void> updateInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {}

  @override
  Stream<List<InvestmentPricePoint>> watchPriceHistory({
    required String userId,
    required String investmentId,
  }) {
    return Stream<List<InvestmentPricePoint>>.value(const []);
  }

  @override
  Stream<List<InvestmentHolding>> watchInvestments(String userId) {
    return Stream<List<InvestmentHolding>>.value(const []);
  }
}

class _FakeMonthlyReportRepository implements MonthlyReportRepository {
  const _FakeMonthlyReportRepository();

  @override
  Future<void> deleteReport({
    required String userId,
    required String reportId,
  }) async {}

  @override
  Future<void> saveReport({
    required String userId,
    required MonthlyReport report,
  }) async {}

  @override
  Stream<List<MonthlyReport>> watchReports(String userId) {
    return Stream<List<MonthlyReport>>.value(const []);
  }
}

class _FakePortfolioSnapshotRepository implements PortfolioSnapshotRepository {
  const _FakePortfolioSnapshotRepository();

  @override
  Stream<List<PortfolioDailySnapshot>> watchSnapshots(String userId) {
    return Stream<List<PortfolioDailySnapshot>>.value(const []);
  }
}

class _FakeReportArchiveRepository implements ReportArchiveRepository {
  const _FakeReportArchiveRepository();

  @override
  Future<void> archiveFile({
    required String userId,
    required ExportFilePayload file,
    required DateTime periodStart,
    required ReportArchiveFormat format,
    String? reportId,
  }) async {}

  @override
  Future<ExportFilePayload> loadArchiveFile({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    return ExportFilePayload(
      filename: archive.filename,
      mimeType: archive.contentType,
      bytes: Uint8List.fromList(const [1, 2, 3]),
    );
  }

  @override
  Future<void> deleteArchive({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {}

  @override
  Stream<List<ReportArchiveEntry>> watchArchives(String userId) {
    return Stream<List<ReportArchiveEntry>>.value(const []);
  }
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  const _FakeSubscriptionRepository();

  @override
  Future<void> createSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {}

  @override
  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {}

  @override
  Future<void> updateSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {}

  @override
  Stream<List<SubscriptionPlan>> watchSubscriptions(String userId) {
    return Stream<List<SubscriptionPlan>>.value(const []);
  }
}

class _FakeRecurringIncomeRepository implements RecurringIncomeRepository {
  const _FakeRecurringIncomeRepository();

  @override
  Future<void> createRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {}

  @override
  Future<void> deleteRecurringIncome({
    required String userId,
    required String recurringIncomeId,
  }) async {}

  @override
  Future<void> updateRecurringIncome({
    required String userId,
    required RecurringIncomePlan plan,
  }) async {}

  @override
  Stream<List<RecurringIncomePlan>> watchRecurringIncomes(String userId) {
    return Stream<List<RecurringIncomePlan>>.value(const []);
  }
}

class _FakeGoalContributionPlanRepository
    implements GoalContributionPlanRepository {
  const _FakeGoalContributionPlanRepository();

  @override
  Future<void> createGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Future<void> deleteGoalContributionPlan({
    required String userId,
    required String planId,
  }) async {}

  @override
  Future<void> deletePlansForGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<void> updateGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId) {
    return Stream<List<GoalContributionPlan>>.value(const []);
  }
}

class _GoalContributionPlanRepositoryWithData
    implements GoalContributionPlanRepository {
  const _GoalContributionPlanRepositoryWithData();

  @override
  Future<void> createGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Future<void> deleteGoalContributionPlan({
    required String userId,
    required String planId,
  }) async {}

  @override
  Future<void> deletePlansForGoal({
    required String userId,
    required String goalId,
  }) async {}

  @override
  Future<void> updateGoalContributionPlan({
    required String userId,
    required GoalContributionPlan plan,
  }) async {}

  @override
  Stream<List<GoalContributionPlan>> watchGoalContributionPlans(String userId) {
    final now = DateTime.now();
    return Stream<List<GoalContributionPlan>>.value([
      GoalContributionPlan(
        id: 'goal-plan-1',
        goalId: 'goal-1',
        name: 'Wplata do Poduszka',
        amount: 400,
        interval: GoalContributionInterval.monthly,
        dayOfMonth: now.day.clamp(1, 28),
        startDate: DateTime(now.year, now.month, 1),
        isActive: true,
      ),
    ]);
  }
}

class _SubscriptionRepositoryWithData implements SubscriptionRepository {
  const _SubscriptionRepositoryWithData();

  @override
  Future<void> createSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {}

  @override
  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {}

  @override
  Future<void> updateSubscription({
    required String userId,
    required SubscriptionPlan subscription,
  }) async {}

  @override
  Stream<List<SubscriptionPlan>> watchSubscriptions(String userId) {
    return Stream<List<SubscriptionPlan>>.value([
      SubscriptionPlan(
        id: 'subscription-1',
        name: 'Netflix',
        category: 'Rozrywka',
        amount: 39.99,
        billingCycle: SubscriptionBillingCycle.monthly,
        nextBillingDate: DateTime(2026, 6, 8),
        isActive: true,
      ),
      SubscriptionPlan(
        id: 'subscription-2',
        name: 'Dropbox',
        category: 'Praca',
        amount: 299.0,
        billingCycle: SubscriptionBillingCycle.yearly,
        nextBillingDate: DateTime(2026, 9, 10),
        isActive: false,
      ),
    ]);
  }
}

class _InvestmentRepositoryWithData implements InvestmentRepository {
  const _InvestmentRepositoryWithData();

  @override
  Future<void> createInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {}

  @override
  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  }) async {}

  @override
  Future<void> clearPriceHistory({
    required String userId,
    required String investmentId,
  }) async {}

  @override
  Future<void> upsertPriceHistoryPoints({
    required String userId,
    required String investmentId,
    required List<InvestmentPricePoint> pricePoints,
  }) async {}

  @override
  Future<void> updateInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {}

  @override
  Stream<List<InvestmentPricePoint>> watchPriceHistory({
    required String userId,
    required String investmentId,
  }) {
    return Stream<List<InvestmentPricePoint>>.value([
      InvestmentPricePoint(
        id: '2026-06-03',
        investmentId: investmentId,
        closePrice: 121.0,
        priceDate: DateTime(2026, 6, 3),
        recordedAt: DateTime(2026, 6, 4, 12),
      ),
      InvestmentPricePoint(
        id: '2026-06-04',
        investmentId: investmentId,
        closePrice: 123.0,
        priceDate: DateTime(2026, 6, 4),
        recordedAt: DateTime(2026, 6, 4, 12),
      ),
    ]);
  }

  @override
  Stream<List<InvestmentHolding>> watchInvestments(String userId) {
    return Stream<List<InvestmentHolding>>.value([
      InvestmentHolding(
        id: 'investment-1',
        assetType: InvestmentAssetType.etf,
        symbol: 'VWCE',
        name: 'ETF globalny',
        units: 3,
        buyPrice: 110,
        currentPrice: 123,
        lastPriceDate: DateTime(2026, 6, 4),
        lastPriceUpdateAt: DateTime(2026, 6, 4, 12),
      ),
    ]);
  }
}

class _BudgetRepositoryWithData implements BudgetRepository {
  const _BudgetRepositoryWithData();

  @override
  Future<void> createBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {}

  @override
  Future<void> deleteBudget({
    required String userId,
    required String budgetId,
  }) async {}

  @override
  Future<void> updateBudget({
    required String userId,
    required CategoryBudget budget,
  }) async {}

  @override
  Stream<List<CategoryBudget>> watchBudgets({
    required String userId,
    required DateTime periodStart,
  }) {
    return Stream<List<CategoryBudget>>.value([
      CategoryBudget(
        id: 'budget-1',
        category: 'Dom',
        limit: 1500,
        spent: 0,
        periodStart: DateTime(2026, 6, 1),
      ),
    ]);
  }
}

class _TransactionRepositoryWithData implements TransactionRepository {
  const _TransactionRepositoryWithData();

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    return transaction;
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {}

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return Stream<List<FinanceTransaction>>.value([
      FinanceTransaction(
        id: 'tx-1',
        title: 'Wplata na poduszke',
        category: 'Oszczednosci',
        amount: 300,
        date: DateTime(2026, 6, 2),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
    ]);
  }
}

class _TransactionRepositoryWithTimelineData implements TransactionRepository {
  const _TransactionRepositoryWithTimelineData();

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    return transaction;
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {}

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return Stream<List<FinanceTransaction>>.value([
      FinanceTransaction(
        id: 'tx-2',
        title: 'Wplata druga',
        category: 'Oszczednosci',
        amount: 400,
        date: DateTime(2026, 6, 10),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
      FinanceTransaction(
        id: 'tx-1',
        title: 'Wplata pierwsza',
        category: 'Oszczednosci',
        amount: 300,
        date: DateTime(2026, 6, 2),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
    ]);
  }
}

class _MonthlyReportTransactionRepository implements TransactionRepository {
  const _MonthlyReportTransactionRepository();

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    return transaction;
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {}

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {}

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) {
    return Stream<List<FinanceTransaction>>.value([
      FinanceTransaction(
        id: 'tx-1',
        title: 'Pensja',
        category: 'Praca',
        amount: 5000,
        date: DateTime(2026, 6, 3),
        type: TransactionType.income,
      ),
      FinanceTransaction(
        id: 'tx-2',
        title: 'Czynsz',
        category: 'Dom',
        amount: 1200,
        date: DateTime(2026, 6, 4),
        type: TransactionType.expense,
      ),
      FinanceTransaction(
        id: 'tx-3',
        title: 'Wplata na poduszke',
        category: 'Oszczednosci',
        amount: 400,
        date: DateTime(2026, 6, 5),
        type: TransactionType.transfer,
        goalId: 'goal-1',
      ),
    ]);
  }
}

class _MutableTransactionRepository implements TransactionRepository {
  _MutableTransactionRepository(List<FinanceTransaction> seedTransactions)
    : _transactions = List<FinanceTransaction>.from(seedTransactions);

  final List<FinanceTransaction> _transactions;
  final StreamController<List<FinanceTransaction>> _updates =
      StreamController<List<FinanceTransaction>>.broadcast();
  int _nextId = 100;

  void dispose() {
    _updates.close();
  }

  @override
  Future<FinanceTransaction> createTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    final created = transaction.isPersisted
        ? transaction
        : transaction.copyWith(id: 'tx-${_nextId++}');
    _transactions.add(created);
    _emit();
    return created;
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    _transactions.removeWhere((transaction) => transaction.id == transactionId);
    _emit();
  }

  @override
  Future<void> updateTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    final index = _transactions.indexWhere(
      (current) => current.id == transaction.id,
    );
    if (index == -1) {
      return;
    }

    _transactions[index] = transaction;
    _emit();
  }

  @override
  Stream<List<FinanceTransaction>> watchTransactions(String userId) async* {
    yield List<FinanceTransaction>.unmodifiable(_transactions);
    yield* _updates.stream;
  }

  void _emit() {
    _updates.add(List<FinanceTransaction>.unmodifiable(_transactions));
  }
}

class _MutableMonthlyReportRepository implements MonthlyReportRepository {
  _MutableMonthlyReportRepository([List<MonthlyReport> seedReports = const []])
    : _reports = List<MonthlyReport>.from(seedReports);

  final List<MonthlyReport> _reports;
  final StreamController<List<MonthlyReport>> _updates =
      StreamController<List<MonthlyReport>>.broadcast();

  void dispose() {
    _updates.close();
  }

  @override
  Future<void> deleteReport({
    required String userId,
    required String reportId,
  }) async {
    _reports.removeWhere((report) => report.id == reportId);
    _emit();
  }

  @override
  Future<void> saveReport({
    required String userId,
    required MonthlyReport report,
  }) async {
    final index = _reports.indexWhere((current) => current.id == report.id);
    if (index == -1) {
      _reports.add(report);
    } else {
      _reports[index] = report;
    }

    _reports.sort(
      (left, right) => right.periodStart.compareTo(left.periodStart),
    );
    _emit();
  }

  @override
  Stream<List<MonthlyReport>> watchReports(String userId) async* {
    yield List<MonthlyReport>.unmodifiable(_reports);
    yield* _updates.stream;
  }

  void _emit() {
    _updates.add(List<MonthlyReport>.unmodifiable(_reports));
  }
}

class _MutablePortfolioSnapshotRepository
    implements PortfolioSnapshotRepository {
  _MutablePortfolioSnapshotRepository([
    List<PortfolioDailySnapshot> seedSnapshots = const [],
  ]) : _snapshots = List<PortfolioDailySnapshot>.from(seedSnapshots);

  final List<PortfolioDailySnapshot> _snapshots;
  final StreamController<List<PortfolioDailySnapshot>> _updates =
      StreamController<List<PortfolioDailySnapshot>>.broadcast();

  void dispose() {
    _updates.close();
  }

  @override
  Stream<List<PortfolioDailySnapshot>> watchSnapshots(String userId) async* {
    yield List<PortfolioDailySnapshot>.unmodifiable(_snapshots);
    yield* _updates.stream;
  }
}

class _MutableReportArchiveRepository implements ReportArchiveRepository {
  final List<ReportArchiveEntry> _archives = <ReportArchiveEntry>[];
  final Map<String, ExportFilePayload> _filesById =
      <String, ExportFilePayload>{};
  final StreamController<List<ReportArchiveEntry>> _updates =
      StreamController<List<ReportArchiveEntry>>.broadcast();
  int _nextId = 1;

  void dispose() {
    _updates.close();
  }

  @override
  Future<void> archiveFile({
    required String userId,
    required ExportFilePayload file,
    required DateTime periodStart,
    required ReportArchiveFormat format,
    String? reportId,
  }) async {
    final archiveId = 'archive-${_nextId++}';
    _archives.add(
      ReportArchiveEntry(
        id: archiveId,
        reportId: reportId,
        filename: file.filename,
        format: format,
        periodStart: DateTime(periodStart.year, periodStart.month),
        uploadedAt: DateTime(2026, 6, 30, 21, 0),
        sizeBytes: file.bytes.length,
        contentType: file.mimeType,
        storagePath: 'users/$userId/reports/test/${file.filename}',
      ),
    );
    _filesById[archiveId] = file;
    _emit();
  }

  @override
  Future<ExportFilePayload> loadArchiveFile({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    return _filesById[archive.id] ??
        ExportFilePayload(
          filename: archive.filename,
          mimeType: archive.contentType,
          bytes: Uint8List.fromList(const [1, 2, 3]),
        );
  }

  @override
  Future<void> deleteArchive({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    _archives.removeWhere((entry) => entry.id == archive.id);
    _filesById.remove(archive.id);
    _emit();
  }

  @override
  Stream<List<ReportArchiveEntry>> watchArchives(String userId) async* {
    yield List<ReportArchiveEntry>.unmodifiable(_archives);
    yield* _updates.stream;
  }

  void _emit() {
    _updates.add(List<ReportArchiveEntry>.unmodifiable(_archives));
  }
}
