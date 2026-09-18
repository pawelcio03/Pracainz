import '../../../models/finance_models.dart';

const String goalContributionCategory = 'Oszczednosci';

const List<FinanceCategory> defaultFinanceCategories = [
  FinanceCategory(id: '', name: 'Praca', type: TransactionType.income),
  FinanceCategory(
    id: '',
    name: 'Dodatkowy dochod',
    type: TransactionType.income,
  ),
  FinanceCategory(id: '', name: 'Dom', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Transport', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Jedzenie', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Rozrywka', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Zdrowie', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Subskrypcje', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Inwestycje', type: TransactionType.expense),
  FinanceCategory(id: '', name: 'Inne', type: TransactionType.expense),
  FinanceCategory(
    id: '',
    name: goalContributionCategory,
    type: TransactionType.transfer,
  ),
];

List<FinanceCategory> categoriesForTypeOrFallback(
  Iterable<FinanceCategory> categories,
  TransactionType type,
) {
  final filtered =
      categories.where((category) => category.type == type).toList()
        ..sort((left, right) => left.name.compareTo(right.name));

  if (filtered.isNotEmpty) {
    return filtered;
  }

  return defaultFinanceCategories
      .where((category) => category.type == type)
      .toList();
}

List<String> categoryNamesForTypeOrFallback(
  Iterable<FinanceCategory> categories,
  TransactionType type,
) {
  return categoriesForTypeOrFallback(
    categories,
    type,
  ).map((category) => category.name).toList();
}
