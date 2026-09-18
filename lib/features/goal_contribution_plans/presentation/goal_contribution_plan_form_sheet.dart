import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';

Future<GoalContributionPlan?> showGoalContributionPlanFormSheet(
  BuildContext context, {
  required SavingsGoal goal,
  GoalContributionPlan? initialPlan,
}) {
  return showAppBottomSheet<GoalContributionPlan>(
    context,
    builder: (context) =>
        _GoalContributionPlanFormSheet(goal: goal, initialPlan: initialPlan),
  );
}

class _GoalContributionPlanFormSheet extends StatefulWidget {
  const _GoalContributionPlanFormSheet({
    required this.goal,
    required this.initialPlan,
  });

  final SavingsGoal goal;
  final GoalContributionPlan? initialPlan;

  @override
  State<_GoalContributionPlanFormSheet> createState() =>
      _GoalContributionPlanFormSheetState();
}

class _GoalContributionPlanFormSheetState
    extends State<_GoalContributionPlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late GoalContributionInterval _selectedInterval;
  late int _selectedDayOfMonth;
  late DateTime _startDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final initialPlan = widget.initialPlan;
    final now = DateTime.now();
    _nameController = TextEditingController(
      text: initialPlan?.name ?? 'Wplata do ${widget.goal.name}',
    );
    _amountController = TextEditingController(
      text: initialPlan == null
          ? ''
          : initialPlan.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: initialPlan?.note ?? '');
    _selectedInterval =
        initialPlan?.interval ?? GoalContributionInterval.monthly;
    _selectedDayOfMonth = initialPlan?.dayOfMonth ?? now.day;
    _startDate = initialPlan?.startDate ?? now;
    _isActive = initialPlan?.isActive ?? true;
  }

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
        label: isEditing ? 'Zapisz plan' : 'Dodaj plan',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj plan wplat' : 'Dodaj plan wplat',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan automatycznie dopisze transfer do celu po terminie kazdej zaplanowanej wplaty.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nazwa planu'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe planu.';
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
                labelText: 'Kwota jednej wplaty',
                hintText: 'np. 500,00',
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
            appBottomSheetResponsiveControl(
              context,
              child: SegmentedButton<GoalContributionInterval>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: GoalContributionInterval.monthly,
                    label: Text('Miesiecznie'),
                  ),
                  ButtonSegment(
                    value: GoalContributionInterval.quarterly,
                    label: Text('Kwartalnie'),
                  ),
                  ButtonSegment(
                    value: GoalContributionInterval.yearly,
                    label: Text('Rocznie'),
                  ),
                ],
                selected: {_selectedInterval},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedInterval = selection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedDayOfMonth,
              decoration: const InputDecoration(labelText: 'Dzien wplaty'),
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
                  _selectedDayOfMonth = value;
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
                'Nieaktywny plan nie dopisuje kolejnych wplat.',
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
                hintText: 'np. stale odkladanie po wyplacie',
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
      GoalContributionPlan(
        id: widget.initialPlan?.id ?? '',
        goalId: widget.goal.id,
        name: _nameController.text.trim(),
        amount: _parseAmount(_amountController.text)!,
        interval: _selectedInterval,
        dayOfMonth: _selectedDayOfMonth,
        startDate: _startDate,
        isActive: _isActive,
        lastGeneratedPeriodKey: widget.initialPlan?.lastGeneratedPeriodKey,
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
