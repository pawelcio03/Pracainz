import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/transaction_import_history_entry.dart';
import '../domain/transaction_import_history_repository.dart';

class SharedPreferencesTransactionImportHistoryRepository
    implements TransactionImportHistoryRepository {
  const SharedPreferencesTransactionImportHistoryRepository();

  static const String _keyPrefix = 'transaction_import_history_v1';

  @override
  Future<List<TransactionImportHistoryEntry>> loadEntries(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <TransactionImportHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <TransactionImportHistoryEntry>[];
      }

      final entries =
          decoded
              .whereType<Map<String, Object?>>()
              .map(TransactionImportHistoryEntry.fromJson)
              .whereType<TransactionImportHistoryEntry>()
              .toList()
            ..sort(
              (left, right) => right.importedAt.compareTo(left.importedAt),
            );

      return List<TransactionImportHistoryEntry>.unmodifiable(entries);
    } catch (_) {
      return const <TransactionImportHistoryEntry>[];
    }
  }

  @override
  Future<void> addEntry({
    required String userId,
    required TransactionImportHistoryEntry entry,
  }) async {
    final entries = [entry, ...await loadEntries(userId)]
      ..sort((left, right) => right.importedAt.compareTo(left.importedAt));
    await replaceEntries(userId: userId, entries: entries);
  }

  @override
  Future<void> replaceEntries({
    required String userId,
    required List<TransactionImportHistoryEntry> entries,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final sortedEntries = List<TransactionImportHistoryEntry>.from(entries)
      ..sort((left, right) => right.importedAt.compareTo(left.importedAt));
    final trimmedEntries = sortedEntries.take(100).toList();
    if (trimmedEntries.isEmpty) {
      await preferences.remove(_key(userId));
      return;
    }

    final encoded = jsonEncode(
      trimmedEntries.map((entry) => entry.toJson()).toList(),
    );
    await preferences.setString(_key(userId), encoded);
  }

  @override
  Future<void> clearEntries(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(userId));
  }

  static String _key(String userId) {
    final normalizedUserId = userId.trim().isEmpty ? 'anonymous' : userId;
    return '$_keyPrefix:$normalizedUserId';
  }
}
