import 'import_category_rule.dart';

abstract class ImportCategoryRuleRepository {
  Future<List<ImportCategoryRule>> loadRules(String userId);

  Future<void> upsertRules({
    required String userId,
    required List<ImportCategoryRule> rules,
  });

  Future<void> replaceRules({
    required String userId,
    required List<ImportCategoryRule> rules,
  });
}
