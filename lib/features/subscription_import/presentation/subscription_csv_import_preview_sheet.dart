import 'package:flutter/material.dart';

import '../../../core/formatting/display_number_formatter.dart';
import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../domain/subscription_csv_import_preview.dart';

Future<List<SubscriptionPlan>?> showSubscriptionCsvImportPreviewSheet(
  BuildContext context, {
  required SubscriptionCsvImportPreview preview,
  required List<String> availableCategories,
}) {
  return showAppBottomSheet<List<SubscriptionPlan>>(
    context,
    builder: (context) => _SubscriptionCsvImportPreviewSheet(
      preview: preview,
      availableCategories: availableCategories,
    ),
  );
}

class _SubscriptionCsvImportPreviewSheet extends StatefulWidget {
  const _SubscriptionCsvImportPreviewSheet({
    required this.preview,
    required this.availableCategories,
  });

  final SubscriptionCsvImportPreview preview;
  final List<String> availableCategories;

  @override
  State<_SubscriptionCsvImportPreviewSheet> createState() =>
      _SubscriptionCsvImportPreviewSheetState();
}

class _SubscriptionCsvImportPreviewSheetState
    extends State<_SubscriptionCsvImportPreviewSheet> {
  late final List<SubscriptionPlan> _draftSubscriptions;

  @override
  void initState() {
    super.initState();
    _draftSubscriptions = List<SubscriptionPlan>.from(
      widget.preview.subscriptionsToImport,
    );
  }

  List<String> _categoryOptionsFor(SubscriptionPlan subscription) {
    final options =
        widget.availableCategories
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (!options.contains(subscription.category)) {
      options.insert(0, subscription.category);
    }

    return options;
  }

  void _updateCategory(int index, String category) {
    setState(() {
      _draftSubscriptions[index] = _draftSubscriptions[index].copyWith(
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
              onPressed: _draftSubscriptions.isNotEmpty
                  ? () => Navigator.of(context).pop(
                      List<SubscriptionPlan>.unmodifiable(_draftSubscriptions),
                    )
                  : null,
              child: Text(
                _draftSubscriptions.isNotEmpty
                    ? 'Importuj ${_draftSubscriptions.length}'
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
            'Podglad importu pliku subskrypcji',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Wykryty format: ${widget.preview.formatLabel}. Przed zapisem mozesz poprawic kategorie i sprawdzic, ile subskrypcji zostanie dodanych, a ile pominietych jako duplikaty albo bledne wiersze.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SubscriptionImportStatChip(
                label: 'Nowe subskrypcje',
                value: '${_draftSubscriptions.length}',
                tone: _SubscriptionImportStatTone.success,
              ),
              _SubscriptionImportStatChip(
                label: 'Duplikaty',
                value: '${widget.preview.duplicateCount}',
                tone: _SubscriptionImportStatTone.warning,
              ),
              _SubscriptionImportStatChip(
                label: 'Bledne wiersze',
                value: '${widget.preview.issues.length}',
                tone: _SubscriptionImportStatTone.danger,
              ),
            ],
          ),
          if (_draftSubscriptions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Subskrypcje do importu',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...List.generate(_draftSubscriptions.length, (index) {
              final subscription = _draftSubscriptions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubscriptionPreviewTile(
                  subscription: subscription,
                  categoryOptions: _categoryOptionsFor(subscription),
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
                    child: _SubscriptionImportIssueTile(issue: issue),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

enum _SubscriptionImportStatTone { success, warning, danger }

class _SubscriptionImportStatChip extends StatelessWidget {
  const _SubscriptionImportStatChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _SubscriptionImportStatTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _SubscriptionImportStatTone.success => const Color(0xFF0F766E),
      _SubscriptionImportStatTone.warning => const Color(0xFFB45309),
      _SubscriptionImportStatTone.danger => Theme.of(context).colorScheme.error,
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

class _SubscriptionPreviewTile extends StatelessWidget {
  const _SubscriptionPreviewTile({
    required this.subscription,
    required this.categoryOptions,
    required this.onCategoryChanged,
  });

  final SubscriptionPlan subscription;
  final List<String> categoryOptions;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final hasNote =
        subscription.note != null && subscription.note!.trim().isNotEmpty;

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
            subscription.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatDisplayCurrency(subscription.amount)} | ${_billingCycleLabel(subscription.billingCycle)} | ${_dateLabel(subscription.nextBillingDate)}',
          ),
          if (hasNote) ...[
            const SizedBox(height: 6),
            Text(
              subscription.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: subscription.category,
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

String _billingCycleLabel(SubscriptionBillingCycle cycle) {
  return switch (cycle) {
    SubscriptionBillingCycle.monthly => 'Miesiecznie',
    SubscriptionBillingCycle.quarterly => 'Kwartalnie',
    SubscriptionBillingCycle.yearly => 'Rocznie',
  };
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

class _SubscriptionImportIssueTile extends StatelessWidget {
  const _SubscriptionImportIssueTile({required this.issue});

  final SubscriptionCsvImportIssue issue;

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
