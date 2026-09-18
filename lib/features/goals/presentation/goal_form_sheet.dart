import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';

Future<SavingsGoal?> showGoalFormSheet(
  BuildContext context, {
  SavingsGoal? initialGoal,
}) {
  return showAppBottomSheet<SavingsGoal>(
    context,
    builder: (context) => _GoalFormSheet(initialGoal: initialGoal),
  );
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({this.initialGoal});

  final SavingsGoal? initialGoal;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGoal;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _targetController = TextEditingController(
      text: initial == null
          ? ''
          : initial.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _savedController = TextEditingController(
      text: initial == null
          ? ''
          : initial.savedAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _deadline =
        initial?.deadline ?? DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGoal != null;

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz cel' : 'Dodaj cel',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj cel' : 'Dodaj cel',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Cel zapisuje kwote docelowa, stan poczatkowy i termin realizacji. Kolejne wplaty beda liczone z powiazanych transakcji.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nazwa celu'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe celu.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Kwota docelowa'),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Podaj dodatnia kwote docelowa.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _savedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Stan poczatkowy'),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed < 0) {
                  return 'Podaj poprawny stan poczatkowy.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDeadline,
                icon: const Icon(Icons.event),
                label: Text('Termin: ${_date(_deadline)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _deadline = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      SavingsGoal(
        id: widget.initialGoal?.id ?? '',
        name: _nameController.text.trim(),
        targetAmount: _parseAmount(_targetController.text)!,
        savedAmount: _parseAmount(_savedController.text)!,
        deadline: _deadline,
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
