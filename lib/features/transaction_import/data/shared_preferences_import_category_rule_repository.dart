import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/import_category_rule.dart';
import '../domain/import_category_rule_repository.dart';

class SharedPreferencesImportCategoryRuleRepository
    implements ImportCategoryRuleRepository {
  const SharedPreferencesImportCategoryRuleRepository();

  static const String _keyPrefix = 'import_category_rules_v1';

  @override
  Future<List<ImportCategoryRule>> loadRules(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <ImportCategoryRule>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ImportCategoryRule>[];
      }

      final rules =
          decoded
              .whereType<Map<String, Object?>>()
              .map(ImportCategoryRule.fromJson)
              .whereType<ImportCategoryRule>()
              .toList()
            ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

      return List<ImportCategoryRule>.unmodifiable(rules);
    } catch (_) {
      return const <ImportCategoryRule>[];
    }
  }

  @override
  Future<void> upsertRules({
    required String userId,
    required List<ImportCategoryRule> rules,
  }) async {
    final usableRules = rules.where((rule) => rule.isUsable).toList();
    if (usableRules.isEmpty) {
      return;
    }

    final existingRules = await loadRules(userId);
    final merged = <String, ImportCategoryRule>{
      for (final rule in existingRules) rule.id: rule,
    };

    for (final rule in usableRules) {
      merged[rule.id] = rule;
    }

    await replaceRules(userId: userId, rules: merged.values.toList());
  }

  @override
  Future<void> replaceRules({
    required String userId,
    required List<ImportCategoryRule> rules,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final usableRules = rules.where((rule) => rule.isUsable).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final trimmedRules = usableRules.take(250).toList();

    if (trimmedRules.isEmpty) {
      await preferences.remove(_key(userId));
      return;
    }

    final encoded = jsonEncode(
      trimmedRules.map((rule) => rule.toJson()).toList(),
    );
    await preferences.setString(_key(userId), encoded);
  }

  static String _key(String userId) {
    final normalizedUserId = userId.trim().isEmpty ? 'anonymous' : userId;
    return '$_keyPrefix:$normalizedUserId';
  }
}
