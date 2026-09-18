import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../application/monthly_report_builder.dart';
import '../domain/monthly_report_repository.dart';

class FirestoreMonthlyReportRepository implements MonthlyReportRepository {
  const FirestoreMonthlyReportRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MonthlyReport>> watchReports(String userId) {
    return _reports(userId)
        .orderBy('periodStart', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Future<void> saveReport({
    required String userId,
    required MonthlyReport report,
  }) async {
    final documentId = monthlyReportIdForPeriod(report.periodStart);
    await _reports(userId).doc(documentId).set(_toDocument(report));
  }

  @override
  Future<void> deleteReport({
    required String userId,
    required String reportId,
  }) async {
    await _reports(userId).doc(reportId).delete();
  }

  CollectionReference<Map<String, dynamic>> _reports(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('monthlyReports');
  }

  MonthlyReport _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final periodStart =
        (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now();
    final generatedAt =
        (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return MonthlyReport(
      id: document.id,
      periodStart: DateTime(periodStart.year, periodStart.month),
      generatedAt: generatedAt,
      incomeTotal: (data['incomeTotal'] as num?)?.toDouble() ?? 0,
      expenseTotal: (data['expenseTotal'] as num?)?.toDouble() ?? 0,
      transferTotal: (data['transferTotal'] as num?)?.toDouble() ?? 0,
      transactionCount: (data['transactionCount'] as num?)?.toInt() ?? 0,
      budgetCount: (data['budgetCount'] as num?)?.toInt() ?? 0,
      overspentBudgetCount:
          (data['overspentBudgetCount'] as num?)?.toInt() ?? 0,
      budgetLimitTotal: (data['budgetLimitTotal'] as num?)?.toDouble() ?? 0,
      budgetSpentTotal: (data['budgetSpentTotal'] as num?)?.toDouble() ?? 0,
      investmentValue: (data['investmentValue'] as num?)?.toDouble() ?? 0,
      investmentProfit: (data['investmentProfit'] as num?)?.toDouble() ?? 0,
      transferRate: (data['transferRate'] as num?)?.toDouble() ?? 0,
      activeGoals: (data['activeGoals'] as num?)?.toInt() ?? 0,
      completedGoals: (data['completedGoals'] as num?)?.toInt() ?? 0,
      atRiskGoals: (data['atRiskGoals'] as num?)?.toInt() ?? 0,
      topExpenseCategory: data['topExpenseCategory'] as String?,
      isClosed: data['isClosed'] as bool? ?? false,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _toDocument(MonthlyReport report) {
    final periodStart = DateTime(
      report.periodStart.year,
      report.periodStart.month,
    );

    return {
      'periodStart': Timestamp.fromDate(periodStart),
      'generatedAt': Timestamp.fromDate(report.generatedAt),
      'incomeTotal': report.incomeTotal,
      'expenseTotal': report.expenseTotal,
      'transferTotal': report.transferTotal,
      'transactionCount': report.transactionCount,
      'budgetCount': report.budgetCount,
      'overspentBudgetCount': report.overspentBudgetCount,
      'budgetLimitTotal': report.budgetLimitTotal,
      'budgetSpentTotal': report.budgetSpentTotal,
      'investmentValue': report.investmentValue,
      'investmentProfit': report.investmentProfit,
      'transferRate': report.transferRate,
      'activeGoals': report.activeGoals,
      'completedGoals': report.completedGoals,
      'atRiskGoals': report.atRiskGoals,
      'topExpenseCategory': report.topExpenseCategory,
      'isClosed': report.isClosed,
      'closedAt': report.closedAt == null
          ? null
          : Timestamp.fromDate(report.closedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
