import 'package:flutter/material.dart';

import '../../../core/presentation/app_bottom_sheet.dart';
import '../domain/transaction_import_history_entry.dart';

enum TransactionImportHistoryActionType { clear, undo }

class TransactionImportHistoryAction {
  const TransactionImportHistoryAction.clear()
    : type = TransactionImportHistoryActionType.clear,
      entry = null;

  const TransactionImportHistoryAction.undo(this.entry)
    : type = TransactionImportHistoryActionType.undo;

  final TransactionImportHistoryActionType type;
  final TransactionImportHistoryEntry? entry;
}

Future<TransactionImportHistoryAction?> showTransactionImportHistorySheet(
  BuildContext context, {
  required List<TransactionImportHistoryEntry> entries,
}) {
  return showAppBottomSheet<TransactionImportHistoryAction>(
    context,
    builder: (context) => _TransactionImportHistorySheet(entries: entries),
  );
}

class _TransactionImportHistorySheet extends StatelessWidget {
  const _TransactionImportHistorySheet({required this.entries});

  final List<TransactionImportHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final canClear = entries.isNotEmpty;

    return AppBottomSheetFrame(
      bottomBar: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: canClear
                  ? () => Navigator.of(
                      context,
                    ).pop(const TransactionImportHistoryAction.clear())
                  : null,
              child: const Text('Wyczysc'),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historia importow',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Lista ostatnich importow wyciagow bankowych zapisanych lokalnie na tym urzadzeniu.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            const _EmptyImportHistoryState()
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ImportHistoryTile(
                  entry: entry,
                  onUndo: entry.canUndo
                      ? () => Navigator.of(
                          context,
                        ).pop(TransactionImportHistoryAction.undo(entry))
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyImportHistoryState extends StatelessWidget {
  const _EmptyImportHistoryState();

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
        'Brak zapisanych importow. Po zaimportowaniu wyciagu zobaczysz tutaj podsumowanie pliku.',
        style: appBottomSheetDescriptionStyle(context),
      ),
    );
  }
}

class _ImportHistoryTile extends StatelessWidget {
  const _ImportHistoryTile({required this.entry, required this.onUndo});

  final TransactionImportHistoryEntry entry;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            entry.sourceName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text('${entry.formatLabel} | ${_dateTimeLabel(entry.importedAt)}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryChip(label: 'Dodane', value: '${entry.importedCount}'),
              _HistoryChip(label: 'Pominiete', value: '${entry.skippedCount}'),
              _HistoryChip(label: 'Wydatki', value: '${entry.expenseCount}'),
              _HistoryChip(label: 'Przychody', value: '${entry.incomeCount}'),
              _HistoryChip(label: 'Transfery', value: '${entry.transferCount}'),
              _HistoryChip(label: 'Reguly', value: '${entry.learnedRuleCount}'),
            ],
          ),
          if (entry.undoneAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Cofniety ${_dateTimeLabel(entry.undoneAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (onUndo != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onUndo,
                icon: const Icon(Icons.undo_outlined),
                label: const Text('Cofnij import'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _dateTimeLabel(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day.$month.${dateTime.year} $hour:$minute';
}
