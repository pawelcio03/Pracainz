class MonthlyReportMutationException implements Exception {
  const MonthlyReportMutationException(this.message);

  final String message;

  @override
  String toString() => message;
}
