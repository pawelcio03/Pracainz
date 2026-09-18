import '../../../models/finance_models.dart';

class SubscriptionCsvImportPreview {
  const SubscriptionCsvImportPreview({
    required this.formatLabel,
    required this.subscriptionsToImport,
    required this.duplicateCount,
    required this.issues,
  });

  final String formatLabel;
  final List<SubscriptionPlan> subscriptionsToImport;
  final int duplicateCount;
  final List<SubscriptionCsvImportIssue> issues;

  int get validCount => subscriptionsToImport.length;

  bool get canImport => subscriptionsToImport.isNotEmpty;
}

class SubscriptionCsvImportIssue {
  const SubscriptionCsvImportIssue({
    required this.rowNumber,
    required this.message,
    required this.row,
  });

  final int rowNumber;
  final String message;
  final List<String> row;
}
