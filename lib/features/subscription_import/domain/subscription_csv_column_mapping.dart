class SubscriptionCsvColumnMapping {
  const SubscriptionCsvColumnMapping({
    required this.nameColumn,
    this.categoryColumn,
    required this.amountColumn,
    required this.billingCycleColumn,
    required this.nextBillingDateColumn,
    this.isActiveColumn,
    this.noteColumn,
  });

  final String nameColumn;
  final String? categoryColumn;
  final String amountColumn;
  final String billingCycleColumn;
  final String nextBillingDateColumn;
  final String? isActiveColumn;
  final String? noteColumn;
}
