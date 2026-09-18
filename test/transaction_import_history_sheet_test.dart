import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/transaction_import/domain/transaction_import_history_entry.dart';
import 'package:finovo/features/transaction_import/presentation/transaction_import_history_sheet.dart';

void main() {
  testWidgets('shows import history and returns clear action', (tester) async {
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

    final future = showTransactionImportHistorySheet(
      context,
      entries: [
        TransactionImportHistoryEntry(
          id: 'import-1',
          sourceName: 'historia-pko.csv',
          formatLabel: 'Szablon bankowy: PKO BP',
          importedAt: DateTime(2026, 6, 5, 14, 30),
          importedCount: 4,
          duplicateCount: 1,
          issueCount: 0,
          expenseCount: 3,
          incomeCount: 1,
          transferCount: 0,
          learnedRuleCount: 2,
        ),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Historia importow'), findsOneWidget);
    expect(find.text('historia-pko.csv'), findsOneWidget);
    expect(find.text('Dodane: 4'), findsOneWidget);
    expect(find.text('Pominiete: 1'), findsOneWidget);

    await tester.tap(find.text('Wyczysc'));
    await tester.pumpAndSettle();

    final action = await future;
    expect(action?.type, TransactionImportHistoryActionType.clear);
  });

  testWidgets('returns undo action for import with transaction ids', (
    tester,
  ) async {
    late BuildContext context;
    final entry = TransactionImportHistoryEntry(
      id: 'import-1',
      sourceName: 'historia-pko.csv',
      formatLabel: 'Szablon bankowy: PKO BP',
      importedAt: DateTime(2026, 6, 5, 14, 30),
      importedCount: 2,
      duplicateCount: 0,
      issueCount: 0,
      expenseCount: 2,
      incomeCount: 0,
      transferCount: 0,
      learnedRuleCount: 1,
      transactionIds: const ['tx-1', 'tx-2'],
    );

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

    final future = showTransactionImportHistorySheet(context, entries: [entry]);

    await tester.pumpAndSettle();

    expect(find.text('Cofnij import'), findsOneWidget);

    await tester.tap(find.text('Cofnij import'));
    await tester.pumpAndSettle();

    final action = await future;
    expect(action?.type, TransactionImportHistoryActionType.undo);
    expect(action?.entry, same(entry));
  });
}
