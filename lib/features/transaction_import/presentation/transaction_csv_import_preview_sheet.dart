import 'package:flutter/material.dart';

import '../../../core/formatting/display_number_formatter.dart';
import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/category_presets.dart';
import '../domain/transaction_csv_import_preview.dart';

Future<List<FinanceTransaction>?> showTransactionCsvImportPreviewSheet(
  BuildContext context, {
  required TransactionCsvImportPreview preview,
  required List<FinanceCategory> availableCategories,
}) {
  return showAppBottomSheet<List<FinanceTransaction>>(
    context,
    builder: (context) => _TransactionCsvImportPreviewSheet(
      preview: preview,
      availableCategories: availableCategories,
    ),
  );
}

class _TransactionCsvImportPreviewSheet extends StatefulWidget {
  const _TransactionCsvImportPreviewSheet({
    required this.preview,
    required this.availableCategories,
  });

  final TransactionCsvImportPreview preview;
  final List<FinanceCategory> availableCategories;

  @override
  State<_TransactionCsvImportPreviewSheet> createState() =>
      _TransactionCsvImportPreviewSheetState();
}

class _TransactionCsvImportPreviewSheetState
    extends State<_TransactionCsvImportPreviewSheet> {
  late final List<FinanceTransaction> _draftTransactions;

  @override
  void initState() {
    super.initState();
    _draftTransactions = List<FinanceTransaction>.from(
      widget.preview.transactionsToImport,
    );
  }

  List<String> _categoryOptionsFor(FinanceTransaction transaction) {
    final options = categoryNamesForTypeOrFallback(
      widget.availableCategories,
      transaction.type,
    ).toSet().toList()..sort();

    if (!options.contains(transaction.category)) {
      options.insert(0, transaction.category);
    }

    return options;
  }

  void _updateCategory(int index, String category) {
    setState(() {
      _draftTransactions[index] = _draftTransactions[index].copyWith(
        category: category,
      );
    });
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
              onPressed: _draftTransactions.isNotEmpty
                  ? () => Navigator.of(context).pop(
                      List<FinanceTransaction>.unmodifiable(_draftTransactions),
                    )
                  : null,
              child: Text(
                _draftTransactions.isNotEmpty
                    ? 'Importuj ${_draftTransactions.length}'
                    : 'Brak danych do importu',
              ),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podglad importu wyciagu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Wykryty format: ${widget.preview.formatLabel}. Sprawdz zakres dat, sumy i kategorie przed zapisem. Poprawione kategorie pomoga przy kolejnych importach.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ImportStatChip(
                label: 'Do importu',
                value: '${_draftTransactions.length}',
                tone: _ImportStatTone.success,
              ),
              _ImportStatChip(
                label: 'Wydatki',
                value: '${widget.preview.expenseCount}',
                tone: _ImportStatTone.info,
              ),
              _ImportStatChip(
                label: 'Przychody',
                value: '${widget.preview.incomeCount}',
                tone: _ImportStatTone.info,
              ),
              _ImportStatChip(
                label: 'Transfery',
                value: '${widget.preview.transferCount}',
                tone: _ImportStatTone.info,
              ),
              _ImportStatChip(
                label: 'Suma wydatkow',
                value: formatDisplayCurrency(widget.preview.expenseTotal),
                tone: _ImportStatTone.info,
              ),
              _ImportStatChip(
                label: 'Zakres dat',
                value: _dateRangeLabel(
                  widget.preview.firstDate,
                  widget.preview.lastDate,
                ),
                tone: _ImportStatTone.info,
              ),
              _ImportStatChip(
                label: 'Duplikaty',
                value: '${widget.preview.duplicateCount}',
                tone: _ImportStatTone.warning,
              ),
              _ImportStatChip(
                label: 'Bledne wiersze',
                value: '${widget.preview.issues.length}',
                tone: _ImportStatTone.danger,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_draftTransactions.isNotEmpty) ...[
            Text(
              'Transakcje do importu',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...List.generate(_draftTransactions.length, (index) {
              final transaction = _draftTransactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PreviewTransactionTile(
                  transaction: transaction,
                  categoryOptions: _categoryOptionsFor(transaction),
                  onCategoryChanged: (value) {
                    if (value != null) {
                      _updateCategory(index, value);
                    }
                  },
                ),
              );
            }),
          ],
          if (widget.preview.issues.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Wiersze z problemem',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...widget.preview.issues
                .take(6)
                .map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ImportIssueTile(issue: issue),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

enum _ImportStatTone { success, warning, danger, info }

class _ImportStatChip extends StatelessWidget {
  const _ImportStatChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _ImportStatTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _ImportStatTone.success => const Color(0xFF0F766E),
      _ImportStatTone.warning => const Color(0xFFB45309),
      _ImportStatTone.danger => Theme.of(context).colorScheme.error,
      _ImportStatTone.info => const Color(0xFF2563EB),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PreviewTransactionTile extends StatelessWidget {
  const _PreviewTransactionTile({
    required this.transaction,
    required this.categoryOptions,
    required this.onCategoryChanged,
  });

  final FinanceTransaction transaction;
  final List<String> categoryOptions;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (transaction.type.name) {
      'income' => 'Przychod',
      'transfer' => 'Transfer',
      _ => 'Wydatek',
    };
    final hasNote =
        transaction.note != null && transaction.note!.trim().isNotEmpty;

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
          Text(
            transaction.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatDisplayCurrency(transaction.amount)} | $typeLabel | ${_dateLabel(transaction.date)}',
          ),
          if (hasNote) ...[
            const SizedBox(height: 6),
            Text(
              transaction.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: transaction.category,
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

String _dateRangeLabel(DateTime? firstDate, DateTime? lastDate) {
  if (firstDate == null || lastDate == null) {
    return '-';
  }

  final first = _dateLabel(firstDate);
  final last = _dateLabel(lastDate);
  return first == last ? first : '$first - $last';
}

class _ImportIssueTile extends StatelessWidget {
  const _ImportIssueTile({required this.issue});

  final TransactionCsvImportIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final preview = issue.row.join(' | ').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wiersz ${issue.rowNumber}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(issue.message),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
