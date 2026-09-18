import '../../../models/finance_models.dart';

abstract class MonthlyReportRepository {
  Stream<List<MonthlyReport>> watchReports(String userId);

  Future<void> saveReport({
    required String userId,
    required MonthlyReport report,
  });

  Future<void> deleteReport({required String userId, required String reportId});
}
