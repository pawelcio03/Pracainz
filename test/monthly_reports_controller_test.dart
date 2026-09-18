import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/monthly_reports/application/monthly_reports_controller.dart';
import 'package:finovo/features/monthly_reports/domain/monthly_report_mutation_exception.dart';
import 'package:finovo/features/monthly_reports/domain/monthly_report_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('monthly reports controller blocks saving closed month', () async {
    final repository = _MonthlyReportRepositoryWithSeed([
      _report(periodStart: DateTime(2026, 6, 1), isClosed: true),
    ]);
    final controller = MonthlyReportsController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(() {
      controller.dispose();
      repository.dispose();
    });

    await Future<void>.delayed(Duration.zero);

    expect(
      () => controller.save(_report(periodStart: DateTime(2026, 6, 1))),
      throwsA(isA<MonthlyReportMutationException>()),
    );
  });

  test('monthly reports controller closes open month', () async {
    final repository = _MonthlyReportRepositoryWithSeed([]);
    final controller = MonthlyReportsController(
      repository: repository,
      userId: 'user-1',
    );
    addTearDown(() {
      controller.dispose();
      repository.dispose();
    });

    await Future<void>.delayed(Duration.zero);

    await controller.close(_report(periodStart: DateTime(2026, 6, 1)));

    expect(repository.lastSavedReport, isNotNull);
    expect(repository.lastSavedReport!.isClosed, isTrue);
    expect(repository.lastSavedReport!.closedAt, isNotNull);
  });
}

MonthlyReport _report({required DateTime periodStart, bool isClosed = false}) {
  return MonthlyReport(
    id: '${periodStart.year}-${periodStart.month.toString().padLeft(2, '0')}',
    periodStart: periodStart,
    generatedAt: DateTime(2026, 6, 30, 22),
    incomeTotal: 1000,
    expenseTotal: 500,
    transferTotal: 100,
    transactionCount: 4,
    budgetCount: 1,
    overspentBudgetCount: 0,
    budgetLimitTotal: 1000,
    budgetSpentTotal: 500,
    investmentValue: 3000,
    investmentProfit: 100,
    transferRate: 0.1,
    activeGoals: 1,
    completedGoals: 0,
    atRiskGoals: 0,
    isClosed: isClosed,
    closedAt: isClosed ? DateTime(2026, 7, 1, 8) : null,
  );
}

class _MonthlyReportRepositoryWithSeed implements MonthlyReportRepository {
  _MonthlyReportRepositoryWithSeed(List<MonthlyReport> seedReports)
    : _reports = List<MonthlyReport>.from(seedReports);

  final List<MonthlyReport> _reports;
  final StreamController<List<MonthlyReport>> _updates =
      StreamController<List<MonthlyReport>>.broadcast();

  MonthlyReport? lastSavedReport;

  void dispose() {
    _updates.close();
  }

  @override
  Future<void> deleteReport({
    required String userId,
    required String reportId,
  }) async {}

  @override
  Future<void> saveReport({
    required String userId,
    required MonthlyReport report,
  }) async {
    lastSavedReport = report;
  }

  @override
  Stream<List<MonthlyReport>> watchReports(String userId) async* {
    yield List<MonthlyReport>.unmodifiable(_reports);
    yield* _updates.stream;
  }
}
