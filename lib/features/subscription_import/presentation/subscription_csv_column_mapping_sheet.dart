import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../domain/subscription_csv_column_mapping.dart';
import '../domain/subscription_csv_source_data.dart';

Future<SubscriptionCsvColumnMapping?> showSubscriptionCsvColumnMappingSheet(
  BuildContext context, {
  required SubscriptionCsvSourceData source,
}) {
  return showAppBottomSheet<SubscriptionCsvColumnMapping>(
    context,
    builder: (context) => _SubscriptionCsvColumnMappingSheet(source: source),
  );
}

class _SubscriptionCsvColumnMappingSheet extends StatefulWidget {
  const _SubscriptionCsvColumnMappingSheet({required this.source});

  final SubscriptionCsvSourceData source;

  @override
  State<_SubscriptionCsvColumnMappingSheet> createState() =>
      _SubscriptionCsvColumnMappingSheetState();
}

class _SubscriptionCsvColumnMappingSheetState
    extends State<_SubscriptionCsvColumnMappingSheet> {
  String? _nameColumn;
  String? _categoryColumn;
  String? _amountColumn;
  String? _billingCycleColumn;
  String? _nextBillingDateColumn;
  String? _isActiveColumn;
  String? _noteColumn;

  @override
  void initState() {
    super.initState();
    _nameColumn = _guess(const ['name', 'nazwa']);
    _categoryColumn = _guess(const ['category', 'kategoria']);
    _amountColumn = _guess(const ['amount', 'kwota', 'value']);
    _billingCycleColumn = _guess(const ['billingcycle', 'cycle', 'cykl']);
    _nextBillingDateColumn = _guess(const [
      'nextbillingdate',
      'date',
      'data',
      'terminplatnosci',
    ]);
    _isActiveColumn = _guess(const ['isactive', 'active', 'aktywna']);
    _noteColumn = _guess(const ['note', 'notatka', 'opis']);
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
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Pokaz preview'),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mapowanie kolumn subskrypcji',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Wskaz kolumny dla nazwy, kwoty, cyklu i daty kolejnego obciazenia. Kategoria jest opcjonalna i moze zostac zgadnieta automatycznie.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          _ColumnDropdown(
            label: 'Nazwa',
            value: _nameColumn,
            options: widget.source.header,
            onChanged: (value) => setState(() => _nameColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Kategoria',
            value: _categoryColumn,
            options: widget.source.header,
            allowEmpty: true,
            emptyLabel: 'Brak, sproboj zgadnac',
            onChanged: (value) => setState(() => _categoryColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Kwota',
            value: _amountColumn,
            options: widget.source.header,
            onChanged: (value) => setState(() => _amountColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Cykl',
            value: _billingCycleColumn,
            options: widget.source.header,
            onChanged: (value) => setState(() => _billingCycleColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Data kolejnego obciazenia',
            value: _nextBillingDateColumn,
            options: widget.source.header,
            onChanged: (value) =>
                setState(() => _nextBillingDateColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Aktywna',
            value: _isActiveColumn,
            options: widget.source.header,
            allowEmpty: true,
            emptyLabel: 'Brak, domyslnie aktywna',
            onChanged: (value) => setState(() => _isActiveColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Notatka',
            value: _noteColumn,
            options: widget.source.header,
            allowEmpty: true,
            emptyLabel: 'Brak',
            onChanged: (value) => setState(() => _noteColumn = value),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit {
    return _nameColumn != null &&
        _amountColumn != null &&
        _billingCycleColumn != null &&
        _nextBillingDateColumn != null;
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }

    Navigator.of(context).pop(
      SubscriptionCsvColumnMapping(
        nameColumn: _nameColumn!,
        categoryColumn: _categoryColumn,
        amountColumn: _amountColumn!,
        billingCycleColumn: _billingCycleColumn!,
        nextBillingDateColumn: _nextBillingDateColumn!,
        isActiveColumn: _isActiveColumn,
        noteColumn: _noteColumn,
      ),
    );
  }

  String? _guess(List<String> aliases) {
    for (final alias in aliases) {
      for (final header in widget.source.header) {
        if (_normalize(header) == _normalize(alias)) {
          return header;
        }
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
  }
}

class _ColumnDropdown extends StatelessWidget {
  const _ColumnDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allowEmpty = false,
    this.emptyLabel = 'Brak',
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool allowEmpty;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowEmpty)
          DropdownMenuItem<String?>(value: null, child: Text(emptyLabel)),
        ...options.map(
          (option) => DropdownMenuItem<String?>(
            value: option,
            child: Text(option.isEmpty ? '(pusta kolumna)' : option),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
