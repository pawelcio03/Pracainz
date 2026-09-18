import '../../../core/data/csv_utils.dart';
import '../../../models/finance_models.dart';

class ImportCategoryRule {
  const ImportCategoryRule({
    required this.id,
    required this.pattern,
    required this.category,
    required this.type,
    required this.updatedAt,
  });

  factory ImportCategoryRule.forTransaction({
    required FinanceTransaction transaction,
    required DateTime updatedAt,
  }) {
    final pattern = transaction.title.trim();
    final typeName = transaction.type.name;
    final normalizedPattern = normalizePattern(pattern);

    return ImportCategoryRule(
      id: '$typeName:$normalizedPattern',
      pattern: pattern,
      category: transaction.category,
      type: transaction.type,
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String pattern;
  final String category;
  final TransactionType type;
  final DateTime updatedAt;

  ImportCategoryRule copyWith({
    String? id,
    String? pattern,
    String? category,
    TransactionType? type,
    DateTime? updatedAt,
  }) {
    return ImportCategoryRule(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      category: category ?? this.category,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isUsable {
    return normalizePattern(pattern).length >= 3 && category.trim().isNotEmpty;
  }

  bool matches({
    required TransactionType transactionType,
    required String title,
    String? rawCategory,
    String? note,
  }) {
    if (!isUsable || transactionType != type) {
      return false;
    }

    final normalizedPattern = normalizePattern(pattern);
    final text = normalizePattern(
      [
        title,
        rawCategory ?? '',
        note ?? '',
      ].where((value) => value.trim().isNotEmpty).join(' '),
    );

    return text.contains(normalizedPattern);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'pattern': pattern,
      'category': category,
      'type': type.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ImportCategoryRule? fromJson(Map<String, Object?> json) {
    final id = json['id'] as String?;
    final pattern = json['pattern'] as String?;
    final category = json['category'] as String?;
    final typeName = json['type'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;
    final type = _parseType(typeName);
    final updatedAt = updatedAtRaw == null
        ? null
        : DateTime.tryParse(updatedAtRaw);

    if (id == null ||
        pattern == null ||
        category == null ||
        type == null ||
        updatedAt == null) {
      return null;
    }

    final rule = ImportCategoryRule(
      id: id,
      pattern: pattern,
      category: category,
      type: type,
      updatedAt: updatedAt,
    );

    return rule.isUsable ? rule : null;
  }

  static String normalizePattern(String value) {
    return CsvUtils.normalizeHeader(value);
  }

  static TransactionType? _parseType(String? value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      'transfer' => TransactionType.transfer,
      _ => null,
    };
  }
}
