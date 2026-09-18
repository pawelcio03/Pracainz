import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';

Future<RecurringIncomePlan?> showRecurringIncomeFormSheet(
  BuildContext context, {
  RecurringIncomePlan? initialPlan,
  List<FinanceCategory> availableCategories = const [],
}) {
  return showAppBottomSheet<RecurringIncomePlan>(
    context,
    builder: (context) => _RecurringIncomeFormSheet(
      initialPlan: initialPlan,
      availableCategories: availableCategories,
    ),
  );
}

class _RecurringIncomeFormSheet extends StatefulWidget {
  const _RecurringIncomeFormSheet({
    required this.initialPlan,
    required this.availableCategories,
  });

  final RecurringIncomePlan? initialPlan;
  final List<FinanceCategory> availableCategories;

  @override
  State<_RecurringIncomeFormSheet> createState() =>
      _RecurringIncomeFormSheetState();
}

class _RecurringIncomeFormSheetState extends State<_RecurringIncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _selectedCategory;
  late int _selectedPayday;
  late DateTime _startDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final initialPlan = widget.initialPlan;
    _nameController = TextEditingController(
      text: initialPlan?.name ?? 'Wynagrodzenie',
    );
    _amountController = TextEditingController(
      text: initialPlan == null
          ? ''
          : initialPlan.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: initialPlan?.note ?? '');
    final categories = _availableCategories;
    _selectedCategory =
        initialPlan?.category ??
        (categories.isEmpty ? 'Praca' : categories.first);
    _selectedPayday = initialPlan?.payday ?? 1;
    _startDate =
        initialPlan?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    _isActive = initialPlan?.isActive ?? true;
  }

  List<String> get _availableCategories => categoryNamesForTypeOrFallback(
    widget.availableCategories,
    TransactionType.income,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPlan != null;
    final compact = appBottomSheetIsCompact(context);

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz staly dochod' : 'Dodaj staly dochod',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj staly dochod' : 'Dodaj staly dochod',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan sam wygeneruje miesieczne transakcje dochodowe od daty startu do biezacego miesiaca.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nazwa dochodu'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe stalego dochodu.';
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
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'Kwota miesieczna',
                hintText: 'np. 6800,00',
              ),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Podaj poprawna dodatnia kwote.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategoria dochodu'),
              items: _availableCategories
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
            DropdownButtonFormField<int>(
              initialValue: _selectedPayday,
              decoration: const InputDecoration(labelText: 'Dzien wyplaty'),
              items: List<DropdownMenuItem<int>>.generate(
                31,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedPayday = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickStartDate,
                icon: const Icon(Icons.event),
                label: Text('Start planu: ${_date(_startDate)}'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktywny'),
              subtitle: Text(
                'Nieaktywny plan nie dopisuje kolejnych miesiecy.',
                style: appBottomSheetDescriptionStyle(context),
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLength: 280,
              minLines: compact ? 1 : 2,
              maxLines: compact ? 3 : 4,
              decoration: const InputDecoration(
                labelText: 'Notatka',
                hintText: 'np. UoP, premia kwartalna, etat 1/1',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      RecurringIncomePlan(
        id: widget.initialPlan?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        amount: _parseAmount(_amountController.text)!,
        payday: _selectedPayday,
        startDate: _startDate,
        isActive: _isActive,
        lastGeneratedMonthKey: widget.initialPlan?.lastGeneratedMonthKey,
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
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
