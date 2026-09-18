class SubscriptionCsvSourceData {
  const SubscriptionCsvSourceData({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;

  bool get hasHeader => header.any((cell) => cell.trim().isNotEmpty);

  bool get hasRows => rows.isNotEmpty;
}
