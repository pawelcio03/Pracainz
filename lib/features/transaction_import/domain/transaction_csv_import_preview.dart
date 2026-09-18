import '../../../models/finance_models.dart';

class TransactionCsvImportPreview {
  const TransactionCsvImportPreview({
    required this.formatLabel,
    required this.transactionsToImport,
    required this.duplicateCount,
    required this.issues,
  });

  final String formatLabel;
  final List<FinanceTransaction> transactionsToImport;
  final int duplicateCount;
  final List<TransactionCsvImportIssue> issues;

  int get validCount => transactionsToImport.length;

  bool get canImport => transactionsToImport.isNotEmpty;

  int get expenseCount => transactionsToImport
      .where((transaction) => transaction.type == TransactionType.expense)
      .length;

  int get incomeCount => transactionsToImport
      .where((transaction) => transaction.type == TransactionType.income)
      .length;

  int get transferCount => transactionsToImport
      .where((transaction) => transaction.type == TransactionType.transfer)
      .length;

  double get expenseTotal => transactionsToImport
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get incomeTotal => transactionsToImport
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  DateTime? get firstDate {
    if (transactionsToImport.isEmpty) {
      return null;
    }

    return transactionsToImport
        .map((transaction) => transaction.date)
        .reduce((left, right) => left.isBefore(right) ? left : right);
  }

  DateTime? get lastDate {
    if (transactionsToImport.isEmpty) {
      return null;
    }

    return transactionsToImport
        .map((transaction) => transaction.date)
        .reduce((left, right) => left.isAfter(right) ? left : right);
  }
}

class TransactionCsvImportIssue {
  const TransactionCsvImportIssue({
    required this.rowNumber,
    required this.message,
    required this.row,
  });

  final int rowNumber;
  final String message;
  final List<String> row;
}
