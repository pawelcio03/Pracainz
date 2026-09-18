import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finovo/features/transaction_import/data/shared_preferences_import_category_rule_repository.dart';
import 'package:finovo/features/transaction_import/domain/import_category_rule.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('repository upserts category rules per user', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const repository = SharedPreferencesImportCategoryRuleRepository();

    final firstRule = ImportCategoryRule(
      id: 'expense:orlen',
      pattern: 'ORLEN',
      category: 'Transport',
      type: TransactionType.expense,
      updatedAt: DateTime(2026, 6, 5),
    );

    await repository.upsertRules(userId: 'user-a', rules: [firstRule]);

    var loadedRules = await repository.loadRules('user-a');
    expect(loadedRules, hasLength(1));
    expect(loadedRules.single.category, 'Transport');
    expect(await repository.loadRules('user-b'), isEmpty);

    final updatedRule = ImportCategoryRule(
      id: 'expense:orlen',
      pattern: 'ORLEN',
      category: 'Auto',
      type: TransactionType.expense,
      updatedAt: DateTime(2026, 6, 6),
    );

    await repository.upsertRules(userId: 'user-a', rules: [updatedRule]);

    loadedRules = await repository.loadRules('user-a');
    expect(loadedRules, hasLength(1));
    expect(loadedRules.single.category, 'Auto');
    expect(loadedRules.single.updatedAt, DateTime(2026, 6, 6));

    await repository.replaceRules(userId: 'user-a', rules: const []);

    expect(await repository.loadRules('user-a'), isEmpty);
  });
}
