import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/finance_models.dart';
import '../application/monthly_report_comparison.dart';
import '../domain/monthly_report_mutation_exception.dart';
import '../domain/monthly_report_repository.dart';

class MonthlyReportsController extends ChangeNotifier {
  MonthlyReportsController({required this.repository, required this.userId}) {
    _subscription = repository
        .watchReports(userId)
        .listen(
          (reports) {
            _reports = reports;
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

  final MonthlyReportRepository repository;
  final String userId;
  late final StreamSubscription<List<MonthlyReport>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<MonthlyReport> _reports = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<MonthlyReport> get reports => _reports;

  MonthlyReport? reportForPeriod(DateTime periodStart) {
    final normalizedPeriod = DateTime(periodStart.year, periodStart.month);
    for (final report in _reports) {
      if (report.periodStart.year == normalizedPeriod.year &&
          report.periodStart.month == normalizedPeriod.month) {
        return report;
      }
    }

    return null;
  }

  MonthlyReport? previousReportForPeriod(DateTime periodStart) {
    return previousMonthlyReportForPeriod(_reports, periodStart);
  }

  bool isPeriodClosed(DateTime periodStart) {
    return reportForPeriod(periodStart)?.isClosed ?? false;
  }

  Future<void> save(MonthlyReport report) {
    final existingReport = reportForPeriod(report.periodStart);
    if (existingReport?.isClosed ?? false) {
      throw MonthlyReportMutationException(
        'Miesiac ${_periodLabel(report.periodStart)} jest zamkniety i nie mozna nadpisac snapshotu.',
      );
    }

    return repository.saveReport(userId: userId, report: report);
  }

  Future<void> close(MonthlyReport report) {
    final existingReport = reportForPeriod(report.periodStart);
    if (existingReport?.isClosed ?? false) {
      throw MonthlyReportMutationException(
        'Miesiac ${_periodLabel(report.periodStart)} jest juz zamkniety.',
      );
    }

    return repository.saveReport(
      userId: userId,
      report: report.copyWith(
        isClosed: true,
        closedAt: DateTime.now(),
        generatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> delete(MonthlyReport report) {
    return repository.deleteReport(userId: userId, reportId: report.id);
  }

  String _periodLabel(DateTime periodStart) {
    final month = periodStart.month.toString().padLeft(2, '0');
    return '$month.${periodStart.year}';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
