import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';
import '../domain/import_category_rule.dart';

Future<List<ImportCategoryRule>?> showImportCategoryRulesSheet(
  BuildContext context, {
  required List<ImportCategoryRule> rules,
  required List<FinanceCategory> availableCategories,
}) {
  return showAppBottomSheet<List<ImportCategoryRule>>(
    context,
    builder: (context) => _ImportCategoryRulesSheet(
      rules: rules,
      availableCategories: availableCategories,
    ),
  );
}

class _ImportCategoryRulesSheet extends StatefulWidget {
  const _ImportCategoryRulesSheet({
    required this.rules,
    required this.availableCategories,
  });

  final List<ImportCategoryRule> rules;
  final List<FinanceCategory> availableCategories;

  @override
  State<_ImportCategoryRulesSheet> createState() =>
      _ImportCategoryRulesSheetState();
}

class _ImportCategoryRulesSheetState extends State<_ImportCategoryRulesSheet> {
  late final List<ImportCategoryRule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = List<ImportCategoryRule>.from(widget.rules);
  }

  void _removeRule(ImportCategoryRule rule) {
    setState(() {
      _rules.removeWhere((current) => current.id == rule.id);
    });
  }

  void _updateCategory(ImportCategoryRule rule, String category) {
    final index = _rules.indexWhere((current) => current.id == rule.id);
    if (index == -1) {
      return;
    }

    setState(() {
      _rules[index] = _rules[index].copyWith(
        category: category,
        updatedAt: DateTime.now(),
      );
    });
  }

  List<String> _categoryOptionsFor(ImportCategoryRule rule) {
    final options = categoryNamesForTypeOrFallback(
      widget.availableCategories,
      rule.type,
    ).toSet().toList()..sort();

    if (!options.contains(rule.category)) {
      options.insert(0, rule.category);
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => Navigator.of(
                context,
              ).pop(List<ImportCategoryRule>.unmodifiable(_rules)),
              child: const Text('Zapisz'),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reguly kategorii',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Reguly powstaja po poprawieniu kategorii w podgladzie importu. Mozesz zmienic kategorie albo usunac nietrafione dopasowanie.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          if (_rules.isEmpty)
            const _EmptyRulesState()
          else
            ..._rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ImportCategoryRuleTile(
                  rule: rule,
                  categoryOptions: _categoryOptionsFor(rule),
                  onCategoryChanged: (value) {
                    if (value != null) {
                      _updateCategory(rule, value);
                    }
                  },
                  onDelete: () => _removeRule(rule),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyRulesState extends StatelessWidget {
  const _EmptyRulesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        'Brak zapamietanych regul. Zmien kategorie w podgladzie importu, a aplikacja zapisze dopasowanie na przyszlosc.',
        style: appBottomSheetDescriptionStyle(context),
      ),
    );
  }
}

class _ImportCategoryRuleTile extends StatelessWidget {
  const _ImportCategoryRuleTile({
    required this.rule,
    required this.categoryOptions,
    required this.onCategoryChanged,
    required this.onDelete,
  });

  final ImportCategoryRule rule;
  final List<String> categoryOptions;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (rule.type) {
      TransactionType.income => 'Przychod',
      TransactionType.expense => 'Wydatek',
      TransactionType.transfer => 'Transfer',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.pattern,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$typeLabel | ${_dateLabel(rule.updatedAt)}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Usun regule',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: rule.category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Kategoria'),
            items: categoryOptions
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: onCategoryChanged,
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
