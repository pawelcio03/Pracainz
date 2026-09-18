class TransactionCsvColumnMapping {
  const TransactionCsvColumnMapping({
    required this.titleColumn,
    this.categoryColumn,
    required this.amountColumn,
    required this.dateColumn,
    this.typeColumn,
    this.noteColumn,
    this.goalIdColumn,
  });

  final String titleColumn;
  final String? categoryColumn;
  final String amountColumn;
  final String dateColumn;
  final String? typeColumn;
  final String? noteColumn;
  final String? goalIdColumn;
}
