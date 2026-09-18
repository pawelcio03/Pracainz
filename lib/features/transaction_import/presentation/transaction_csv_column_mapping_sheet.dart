import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../domain/transaction_csv_column_mapping.dart';
import '../domain/transaction_csv_source_data.dart';

Future<TransactionCsvColumnMapping?> showTransactionCsvColumnMappingSheet(
  BuildContext context, {
  required TransactionCsvSourceData source,
}) {
  return showAppBottomSheet<TransactionCsvColumnMapping>(
    context,
    builder: (context) => _TransactionCsvColumnMappingSheet(source: source),
  );
}

class _TransactionCsvColumnMappingSheet extends StatefulWidget {
  const _TransactionCsvColumnMappingSheet({required this.source});

  final TransactionCsvSourceData source;

  @override
  State<_TransactionCsvColumnMappingSheet> createState() =>
      _TransactionCsvColumnMappingSheetState();
}

class _TransactionCsvColumnMappingSheetState
    extends State<_TransactionCsvColumnMappingSheet> {
  String? _titleColumn;
  String? _categoryColumn;
  String? _amountColumn;
  String? _dateColumn;
  String? _typeColumn;
  String? _noteColumn;
  String? _goalIdColumn;

  @override
  void initState() {
    super.initState();
    _titleColumn = _guess(const ['title', 'nazwa', 'tytul', 'description']);
    _categoryColumn = _guess(const ['category', 'kategoria']);
    _amountColumn = _guess(const ['amount', 'kwota', 'value', 'saldo']);
    _dateColumn = _guess(const ['date', 'data', 'bookingdate']);
    _typeColumn = _guess(const ['type', 'typ']);
    _noteColumn = _guess(const ['note', 'notatka', 'opis', 'details']);
    _goalIdColumn = _guess(const ['goalid', 'celid', 'goal']);
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
            'Mapowanie kolumn CSV',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Plik nie pasuje 1:1 do oczekiwanych naglowkow. Wskaz, ktora kolumna odpowiada za tytul, kwote i date transakcji. Kategorie mozna tez zgadnac automatycznie.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          _ColumnDropdown(
            label: 'Tytul',
            value: _titleColumn,
            options: widget.source.header,
            onChanged: (value) => setState(() => _titleColumn = value),
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
            label: 'Data',
            value: _dateColumn,
            options: widget.source.header,
            onChanged: (value) => setState(() => _dateColumn = value),
          ),
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Typ',
            value: _typeColumn,
            options: widget.source.header,
            allowEmpty: true,
            emptyLabel: 'Brak, domyslnie wydatek',
            onChanged: (value) => setState(() => _typeColumn = value),
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
          const SizedBox(height: 12),
          _ColumnDropdown(
            label: 'Cel oszczednosciowy',
            value: _goalIdColumn,
            options: widget.source.header,
            allowEmpty: true,
            emptyLabel: 'Brak',
            onChanged: (value) => setState(() => _goalIdColumn = value),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit {
    return _titleColumn != null && _amountColumn != null && _dateColumn != null;
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }

    Navigator.of(context).pop(
      TransactionCsvColumnMapping(
        titleColumn: _titleColumn!,
        categoryColumn: _categoryColumn,
        amountColumn: _amountColumn!,
        dateColumn: _dateColumn!,
        typeColumn: _typeColumn,
        noteColumn: _noteColumn,
        goalIdColumn: _goalIdColumn,
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
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowEmpty)
          DropdownMenuItem<String>(value: null, child: Text(emptyLabel)),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(option.isEmpty ? '(pusta kolumna)' : option),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
