import 'transaction_import_history_entry.dart';

abstract class TransactionImportHistoryRepository {
  Future<List<TransactionImportHistoryEntry>> loadEntries(String userId);

  Future<void> addEntry({
    required String userId,
    required TransactionImportHistoryEntry entry,
  });

  Future<void> replaceEntries({
    required String userId,
    required List<TransactionImportHistoryEntry> entries,
  });

  Future<void> clearEntries(String userId);
}
