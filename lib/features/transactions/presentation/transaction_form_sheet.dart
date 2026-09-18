import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';

Future<FinanceTransaction?> showTransactionFormSheet(
  BuildContext context, {
  FinanceTransaction? initialTransaction,
  List<FinanceCategory> availableCategories = const [],
  List<SavingsGoal> availableGoals = const [],
  String? presetGoalId,
}) {
  return showAppBottomSheet<FinanceTransaction>(
    context,
    builder: (context) {
      return _TransactionFormSheet(
        initialTransaction: initialTransaction,
        availableCategories: availableCategories,
        availableGoals: availableGoals,
        presetGoalId: presetGoalId,
      );
    },
  );
}

class _TransactionFormSheet extends StatefulWidget {
  const _TransactionFormSheet({
    this.initialTransaction,
    this.availableCategories = const [],
    this.availableGoals = const [],
    this.presetGoalId,
  });

  final FinanceTransaction? initialTransaction;
  final List<FinanceCategory> availableCategories;
  final List<SavingsGoal> availableGoals;
  final String? presetGoalId;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _selectedType;
  late String _selectedCategory;
  late String? _selectedGoalId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;

    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : initial.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _selectedType = initial?.type ?? TransactionType.expense;
    _selectedCategory = initial?.category ?? '';
    final initialGoalId = initial?.goalId;
    final effectiveGoalId = initialGoalId ?? widget.presetGoalId;
    _selectedGoalId =
        widget.availableGoals.any((goal) => goal.id == effectiveGoalId)
        ? effectiveGoalId
        : null;
    if (_selectedGoalId != null) {
      _selectedType = TransactionType.transfer;
      _selectedCategory = goalContributionCategory;
    } else {
      _syncSelectedCategory();
    }
    _selectedDate = initial?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTransaction != null;
    final availableCategoryOptions = _categoryOptionsForType(_selectedType);
    final compact = appBottomSheetIsCompact(context);

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz zmiany' : 'Dodaj transakcje',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj transakcje' : 'Dodaj transakcje',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Wprowadz dane transakcji i przypisz je do odpowiedniej kategorii.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            appBottomSheetResponsiveControl(
              context,
              child: SegmentedButton<TransactionType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Wydatek'),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.transfer,
                    label: Text('Transfer'),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Przychod'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                    if (_selectedType != TransactionType.transfer) {
                      _selectedGoalId = null;
                    }
                    _syncSelectedCategory();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nazwa transakcji'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe transakcji.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'Kwota',
                hintText: 'np. 149,99',
              ),
              validator: (value) {
                final amount = _parseAmount(value);
                if (amount == null || amount <= 0) {
                  return 'Podaj poprawna dodatnia kwote.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategoria'),
              items: availableCategoryOptions
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: _selectedGoalId != null
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedCategory = value;
                      });
                    },
            ),
            if (widget.availableGoals.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGoalId,
                decoration: const InputDecoration(
                  labelText: 'Powiaz z celem oszczednosciowym',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Bez celu'),
                  ),
                  ...widget.availableGoals.map(
                    (goal) => DropdownMenuItem<String>(
                      value: goal.id,
                      child: Text(goal.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGoalId = value;
                    if (value != null) {
                      _selectedType = TransactionType.transfer;
                    }
                    _syncSelectedCategory();
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Powiazana transakcja zostanie potraktowana jako transfer do oszczednosci i podniesie postep celu automatycznie.',
                style: appBottomSheetDescriptionStyle(context),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text('Data: ${_date(_selectedDate)}'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLength: 280,
              maxLines: compact ? 2 : 3,
              decoration: const InputDecoration(
                labelText: 'Opis',
                hintText: 'Opcjonalny komentarz do transakcji',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = _parseAmount(_amountController.text)!;
    final initial = widget.initialTransaction;

    Navigator.of(context).pop(
      FinanceTransaction(
        id: initial?.id ?? '',
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        type: _selectedType,
        goalId: _selectedGoalId,
        goalContributionPlanId: initial?.goalContributionPlanId,
        recurringIncomeId: initial?.recurringIncomeId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
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

  List<String> _categoryOptionsForType(TransactionType type) {
    final options = categoryNamesForTypeOrFallback(
      widget.availableCategories,
      type,
    ).toList();
    final initialCategory = widget.initialTransaction?.category;

    if (type == TransactionType.transfer &&
        !options.contains(goalContributionCategory)) {
      options.insert(0, goalContributionCategory);
    }

    if (initialCategory != null &&
        initialCategory.isNotEmpty &&
        widget.initialTransaction?.type == type &&
        !options.contains(initialCategory)) {
      options.add(initialCategory);
    }

    return options;
  }

  void _syncSelectedCategory() {
    if (_selectedGoalId != null) {
      _selectedCategory = goalContributionCategory;
      return;
    }

    final options = _categoryOptionsForType(_selectedType);
    if (options.isEmpty) {
      _selectedCategory = goalContributionCategory;
      return;
    }

    if (!options.contains(_selectedCategory)) {
      _selectedCategory = options.first;
    }
  }
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
