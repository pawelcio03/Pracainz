class TransactionImportHistoryEntry {
  const TransactionImportHistoryEntry({
    required this.id,
    required this.sourceName,
    required this.formatLabel,
    required this.importedAt,
    required this.importedCount,
    required this.duplicateCount,
    required this.issueCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.transferCount,
    required this.learnedRuleCount,
    this.transactionIds = const <String>[],
    this.undoneAt,
  });

  final String id;
  final String sourceName;
  final String formatLabel;
  final DateTime importedAt;
  final int importedCount;
  final int duplicateCount;
  final int issueCount;
  final int expenseCount;
  final int incomeCount;
  final int transferCount;
  final int learnedRuleCount;
  final List<String> transactionIds;
  final DateTime? undoneAt;

  int get skippedCount => duplicateCount + issueCount;

  bool get canUndo =>
      transactionIds.any((transactionId) => transactionId.trim().isNotEmpty) &&
      undoneAt == null;

  TransactionImportHistoryEntry copyWith({
    String? id,
    String? sourceName,
    String? formatLabel,
    DateTime? importedAt,
    int? importedCount,
    int? duplicateCount,
    int? issueCount,
    int? expenseCount,
    int? incomeCount,
    int? transferCount,
    int? learnedRuleCount,
    List<String>? transactionIds,
    Object? undoneAt = _notProvided,
  }) {
    return TransactionImportHistoryEntry(
      id: id ?? this.id,
      sourceName: sourceName ?? this.sourceName,
      formatLabel: formatLabel ?? this.formatLabel,
      importedAt: importedAt ?? this.importedAt,
      importedCount: importedCount ?? this.importedCount,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      issueCount: issueCount ?? this.issueCount,
      expenseCount: expenseCount ?? this.expenseCount,
      incomeCount: incomeCount ?? this.incomeCount,
      transferCount: transferCount ?? this.transferCount,
      learnedRuleCount: learnedRuleCount ?? this.learnedRuleCount,
      transactionIds: transactionIds ?? this.transactionIds,
      undoneAt: identical(undoneAt, _notProvided)
          ? this.undoneAt
          : undoneAt as DateTime?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'sourceName': sourceName,
      'formatLabel': formatLabel,
      'importedAt': importedAt.toIso8601String(),
      'importedCount': importedCount,
      'duplicateCount': duplicateCount,
      'issueCount': issueCount,
      'expenseCount': expenseCount,
      'incomeCount': incomeCount,
      'transferCount': transferCount,
      'learnedRuleCount': learnedRuleCount,
      'transactionIds': transactionIds,
      'undoneAt': undoneAt?.toIso8601String(),
    };
  }

  static TransactionImportHistoryEntry? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final sourceName = json['sourceName'] as String?;
    final formatLabel = json['formatLabel'] as String?;
    final importedAtRaw = json['importedAt'] as String?;
    final importedAt = importedAtRaw == null
        ? null
        : DateTime.tryParse(importedAtRaw);
    final undoneAtRaw = json['undoneAt'] as String?;
    final undoneAt = undoneAtRaw == null
        ? null
        : DateTime.tryParse(undoneAtRaw);
    final transactionIds = switch (json['transactionIds']) {
      final List<Object?> values => values.whereType<String>().toList(),
      _ => const <String>[],
    };

    if (id == null ||
        sourceName == null ||
        formatLabel == null ||
        importedAt == null) {
      return null;
    }

    return TransactionImportHistoryEntry(
      id: id,
      sourceName: sourceName,
      formatLabel: formatLabel,
      importedAt: importedAt,
      importedCount: _intValue(json['importedCount']),
      duplicateCount: _intValue(json['duplicateCount']),
      issueCount: _intValue(json['issueCount']),
      expenseCount: _intValue(json['expenseCount']),
      incomeCount: _intValue(json['incomeCount']),
      transferCount: _intValue(json['transferCount']),
      learnedRuleCount: _intValue(json['learnedRuleCount']),
      transactionIds: List<String>.unmodifiable(transactionIds),
      undoneAt: undoneAt,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}

const Object _notProvided = Object();
