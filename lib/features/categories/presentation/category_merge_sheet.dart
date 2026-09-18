import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';

Future<FinanceCategory?> showCategoryMergeSheet(
  BuildContext context, {
  required FinanceCategory sourceCategory,
  required List<FinanceCategory> candidateCategories,
  required int transactionCount,
  required int budgetCount,
  required int subscriptionCount,
  required int recurringIncomeCount,
}) {
  return showAppBottomSheet<FinanceCategory>(
    context,
    builder: (context) => _CategoryMergeSheet(
      sourceCategory: sourceCategory,
      candidateCategories: candidateCategories,
      transactionCount: transactionCount,
      budgetCount: budgetCount,
      subscriptionCount: subscriptionCount,
      recurringIncomeCount: recurringIncomeCount,
    ),
  );
}

class _CategoryMergeSheet extends StatefulWidget {
  const _CategoryMergeSheet({
    required this.sourceCategory,
    required this.candidateCategories,
    required this.transactionCount,
    required this.budgetCount,
    required this.subscriptionCount,
    required this.recurringIncomeCount,
  });

  final FinanceCategory sourceCategory;
  final List<FinanceCategory> candidateCategories;
  final int transactionCount;
  final int budgetCount;
  final int subscriptionCount;
  final int recurringIncomeCount;

  @override
  State<_CategoryMergeSheet> createState() => _CategoryMergeSheetState();
}

class _CategoryMergeSheetState extends State<_CategoryMergeSheet> {
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.candidateCategories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.candidateCategories.firstWhere(
      (category) => category.id == _selectedCategoryId,
    );

    return AppBottomSheetFrame(
      bottomBar: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(selectedCategory),
              child: const Text('Scal i przepnij dane'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scal kategorie',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Kategoria "${widget.sourceCategory.name}" zostanie usunieta z listy, a powiazane dane zostana przepiete do wybranej kategorii tego samego typu.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kategoria docelowa'),
            items: widget.candidateCategories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ImpactChip(
                label: 'Transakcje',
                value: '${widget.transactionCount}',
              ),
              if (widget.sourceCategory.type == TransactionType.expense)
                _ImpactChip(
                  label: 'Subskrypcje',
                  value: '${widget.subscriptionCount}',
                ),
              if (widget.sourceCategory.type == TransactionType.income)
                _ImpactChip(
                  label: 'Stale dochody',
                  value: '${widget.recurringIncomeCount}',
                ),
              if (widget.sourceCategory.type == TransactionType.expense)
                _ImpactChip(
                  label: 'Budzety teraz',
                  value: '${widget.budgetCount}',
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              switch (widget.sourceCategory.type) {
                TransactionType.expense =>
                  'Budzety z innych miesiecy z ta sama etykieta tez zostana przepiete w Firestore.',
                TransactionType.income =>
                  'Stale dochody z ta sama etykieta tez zostana przepiete w Firestore.',
                TransactionType.transfer =>
                  'Zostana zaktualizowane tylko transakcje zgodne z typem tej kategorii.',
              },
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
