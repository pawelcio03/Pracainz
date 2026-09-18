import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';

Future<CategoryBudget?> showBudgetFormSheet(
  BuildContext context, {
  required DateTime periodStart,
  CategoryBudget? initialBudget,
  List<String> availableCategories = const [],
}) {
  return showAppBottomSheet<CategoryBudget>(
    context,
    builder: (context) {
      return _BudgetFormSheet(
        periodStart: periodStart,
        initialBudget: initialBudget,
        availableCategories: availableCategories,
      );
    },
  );
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({
    required this.periodStart,
    this.initialBudget,
    this.availableCategories = const [],
  });

  final DateTime periodStart;
  final CategoryBudget? initialBudget;
  final List<String> availableCategories;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.initialBudget == null
          ? ''
          : widget.initialBudget!.limit.toStringAsFixed(2).replaceAll('.', ','),
    );
    _selectedCategory =
        widget.initialBudget?.category ?? _categoryOptions.first;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialBudget != null;

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz budzet' : 'Dodaj budzet',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj budzet' : 'Dodaj budzet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ustaw limit dla ${_periodLabel(widget.periodStart)}. Wykorzystanie policzy sie automatycznie z transakcji.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategoria'),
              items: _categoryOptions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'Limit miesieczny',
                hintText: 'np. 1200,00',
              ),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Podaj poprawny dodatni limit.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CategoryBudget(
        id: widget.initialBudget?.id ?? '',
        category: _selectedCategory,
        limit: _parseAmount(_limitController.text)!,
        spent: widget.initialBudget?.spent ?? 0,
        periodStart: widget.periodStart,
      ),
    );
  }

  double? _parseAmount(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  List<String> get _categoryOptions {
    final categories = widget.availableCategories.isEmpty
        ? categoryNamesForTypeOrFallback(const [], TransactionType.expense)
        : widget.availableCategories.toList();
    final initialCategory = widget.initialBudget?.category;

    if (initialCategory != null &&
        initialCategory.isNotEmpty &&
        !categories.contains(initialCategory)) {
      categories.add(initialCategory);
    }

    return categories;
  }
}

String _periodLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '$month.${date.year}';
}
