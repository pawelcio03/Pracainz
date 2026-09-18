class TransactionCsvSourceData {
  const TransactionCsvSourceData({
    required this.header,
    required this.rows,
    this.sourceName = '',
  });

  final List<String> header;
  final List<List<String>> rows;
  final String sourceName;

  bool get hasHeader => header.any((cell) => cell.trim().isNotEmpty);

  bool get hasRows => rows.isNotEmpty;
}
