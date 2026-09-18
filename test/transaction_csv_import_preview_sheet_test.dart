import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/transaction_import/domain/transaction_csv_import_preview.dart';
import 'package:finovo/features/transaction_import/presentation/transaction_csv_import_preview_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets('returns edited transaction categories from preview sheet', (
    tester,
  ) async {
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final future = showTransactionCsvImportPreviewSheet(
      context,
      preview: TransactionCsvImportPreview(
        formatLabel: 'Prosty CSV transakcji',
        transactionsToImport: [
          FinanceTransaction(
            id: '',
            title: 'Zakupy',
            category: 'Jedzenie',
            amount: 42.5,
            date: DateTime(2026, 6, 4),
            type: TransactionType.expense,
          ),
        ],
        duplicateCount: 0,
        issues: const [],
      ),
      availableCategories: const [
        FinanceCategory(
          id: '',
          name: 'Jedzenie',
          type: TransactionType.expense,
        ),
        FinanceCategory(
          id: '',
          name: 'Transport',
          type: TransactionType.expense,
        ),
      ],
    );

    await tester.pumpAndSettle();

    final categoryField = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(categoryField);
    await tester.pumpAndSettle();
    await tester.tap(categoryField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importuj 1'));
    await tester.pumpAndSettle();

    final result = await future;

    expect(result, isNotNull);
    expect(result, hasLength(1));
    expect(result!.single.category, 'Transport');
  });
}
