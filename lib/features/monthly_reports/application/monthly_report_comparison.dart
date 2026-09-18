import '../../../models/finance_models.dart';

MonthlyReport? previousMonthlyReportForPeriod(
  List<MonthlyReport> reports,
  DateTime periodStart,
) {
  final target = _previousMonthStart(periodStart);

  for (final report in reports) {
    if (report.periodStart.year == target.year &&
        report.periodStart.month == target.month) {
      return report;
    }
  }

  return null;
}

MonthlyReportComparison compareMonthlyReports({
  required MonthlyReport current,
  required MonthlyReport previous,
}) {
  return MonthlyReportComparison(
    current: current,
    previous: previous,
    incomeDelta: current.incomeTotal - previous.incomeTotal,
    expenseDelta: current.expenseTotal - previous.expenseTotal,
    transferDelta: current.transferTotal - previous.transferTotal,
    netCashflowDelta: current.netCashflow - previous.netCashflow,
    transactionCountDelta: current.transactionCount - previous.transactionCount,
    investmentProfitDelta: current.investmentProfit - previous.investmentProfit,
  );
}

DateTime _previousMonthStart(DateTime periodStart) {
  if (periodStart.month == 1) {
    return DateTime(periodStart.year - 1, 12);
  }

  return DateTime(periodStart.year, periodStart.month - 1);
}

class MonthlyReportComparison {
  const MonthlyReportComparison({
    required this.current,
    required this.previous,
    required this.incomeDelta,
    required this.expenseDelta,
    required this.transferDelta,
    required this.netCashflowDelta,
    required this.transactionCountDelta,
    required this.investmentProfitDelta,
  });

  final MonthlyReport current;
  final MonthlyReport previous;
  final double incomeDelta;
  final double expenseDelta;
  final double transferDelta;
  final double netCashflowDelta;
  final int transactionCountDelta;
  final double investmentProfitDelta;
}
