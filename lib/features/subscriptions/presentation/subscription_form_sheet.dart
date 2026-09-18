import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';

const _defaultSubscriptionCategory = 'Subskrypcje';

Future<SubscriptionPlan?> showSubscriptionFormSheet(
  BuildContext context, {
  SubscriptionPlan? initialSubscription,
}) {
  return showAppBottomSheet<SubscriptionPlan>(
    context,
    builder: (context) {
      return _SubscriptionFormSheet(initialSubscription: initialSubscription);
    },
  );
}

class _SubscriptionFormSheet extends StatefulWidget {
  const _SubscriptionFormSheet({this.initialSubscription});

  final SubscriptionPlan? initialSubscription;

  @override
  State<_SubscriptionFormSheet> createState() => _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends State<_SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late SubscriptionBillingCycle _selectedCycle;
  late DateTime _nextBillingDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSubscription;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : initial.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _selectedCycle = initial?.billingCycle ?? SubscriptionBillingCycle.monthly;
    _nextBillingDate =
        initial?.nextBillingDate ?? DateTime.now().add(const Duration(days: 7));
    _isActive = initial?.isActive ?? true;
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
    final isEditing = widget.initialSubscription != null;
    final compact = appBottomSheetIsCompact(context);

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz subskrypcje' : 'Dodaj subskrypcje',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj subskrypcje' : 'Dodaj subskrypcje',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Zapisz cykliczny koszt z kwota, cyklem i data kolejnego obciazenia. Wszystkie wpisy z tego modulu trafiaja do kategorii Subskrypcje.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nazwa'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Podaj nazwe subskrypcji.';
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
                labelText: 'Kwota obciazenia',
                hintText: 'np. 39,99',
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
            DropdownButtonFormField<SubscriptionBillingCycle>(
              initialValue: _selectedCycle,
              decoration: const InputDecoration(labelText: 'Cykl'),
              items: SubscriptionBillingCycle.values
                  .map(
                    (cycle) => DropdownMenuItem<SubscriptionBillingCycle>(
                      value: cycle,
                      child: Text(_billingCycleLabel(cycle)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCycle = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickNextBillingDate,
                icon: const Icon(Icons.event),
                label: Text('Kolejne obciazenie: ${_date(_nextBillingDate)}'),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktywna'),
              subtitle: Text(
                'Nieaktywnych pozycji nie licz do alertow.',
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
                hintText: 'np. plan rodzinny albo subskrypcja roczna',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNextBillingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _nextBillingDate = picked;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      SubscriptionPlan(
        id: widget.initialSubscription?.id ?? '',
        name: _nameController.text.trim(),
        category: _defaultSubscriptionCategory,
        amount: _parseAmount(_amountController.text)!,
        billingCycle: _selectedCycle,
        nextBillingDate: _nextBillingDate,
        isActive: _isActive,
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

  String _billingCycleLabel(SubscriptionBillingCycle cycle) {
    switch (cycle) {
      case SubscriptionBillingCycle.monthly:
        return 'Miesiecznie';
      case SubscriptionBillingCycle.quarterly:
        return 'Kwartalnie';
      case SubscriptionBillingCycle.yearly:
        return 'Rocznie';
    }
  }
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
