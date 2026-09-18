import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finovo/features/transaction_import/data/shared_preferences_transaction_import_history_repository.dart';
import 'package:finovo/features/transaction_import/domain/transaction_import_history_entry.dart';

void main() {
  test('history entry stores undo metadata in json', () {
    final undoneAt = DateTime(2026, 6, 7, 12, 15);
    final entry = _entry(
      id: 'import-1',
      sourceName: 'historia.csv',
      importedAt: DateTime(2026, 6, 5, 10),
      transactionIds: const ['tx-1', 'tx-2'],
    ).copyWith(undoneAt: undoneAt);

    final decoded = TransactionImportHistoryEntry.fromJson(entry.toJson());

    expect(decoded, isNotNull);
    expect(decoded!.transactionIds, ['tx-1', 'tx-2']);
    expect(decoded.undoneAt, undoneAt);
    expect(decoded.canUndo, isFalse);
  });

  test('repository stores import history per user and clears it', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const repository = SharedPreferencesTransactionImportHistoryRepository();

    final olderEntry = _entry(
      id: 'older',
      sourceName: 'older.csv',
      importedAt: DateTime(2026, 6, 5, 10),
    );
    final newerEntry = _entry(
      id: 'newer',
      sourceName: 'newer.csv',
      importedAt: DateTime(2026, 6, 6, 10),
    );

    await repository.addEntry(userId: 'user-a', entry: olderEntry);
    await repository.addEntry(userId: 'user-a', entry: newerEntry);

    final loadedEntries = await repository.loadEntries('user-a');
    expect(loadedEntries.map((entry) => entry.id), ['newer', 'older']);
    expect(await repository.loadEntries('user-b'), isEmpty);

    await repository.clearEntries('user-a');

    expect(await repository.loadEntries('user-a'), isEmpty);
  });

  test('repository replaces entries with undo metadata', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const repository = SharedPreferencesTransactionImportHistoryRepository();
    final undoneAt = DateTime(2026, 6, 7, 12, 15);

    await repository.addEntry(
      userId: 'user-a',
      entry: _entry(
        id: 'import-1',
        sourceName: 'historia.csv',
        importedAt: DateTime(2026, 6, 5, 10),
        transactionIds: const ['tx-1', 'tx-2'],
      ),
    );

    await repository.replaceEntries(
      userId: 'user-a',
      entries: [
        _entry(
          id: 'import-1',
          sourceName: 'historia.csv',
          importedAt: DateTime(2026, 6, 5, 10),
          transactionIds: const ['tx-1', 'tx-2'],
        ).copyWith(undoneAt: undoneAt),
      ],
    );

    final loadedEntries = await repository.loadEntries('user-a');
    expect(loadedEntries, hasLength(1));
    expect(loadedEntries.single.transactionIds, ['tx-1', 'tx-2']);
    expect(loadedEntries.single.undoneAt, undoneAt);
    expect(loadedEntries.single.canUndo, isFalse);
  });
}

TransactionImportHistoryEntry _entry({
  required String id,
  required String sourceName,
  required DateTime importedAt,
  List<String> transactionIds = const <String>[],
}) {
  return TransactionImportHistoryEntry(
    id: id,
    sourceName: sourceName,
    formatLabel: 'Szablon bankowy: PKO BP',
    importedAt: importedAt,
    importedCount: 3,
    duplicateCount: 1,
    issueCount: 2,
    expenseCount: 2,
    incomeCount: 1,
    transferCount: 0,
    learnedRuleCount: 1,
    transactionIds: transactionIds,
  );
}
