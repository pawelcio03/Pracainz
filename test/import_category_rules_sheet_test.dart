import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/transaction_import/domain/import_category_rule.dart';
import 'package:finovo/features/transaction_import/presentation/import_category_rules_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets('returns edited and deleted import category rules', (
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

    final future = showImportCategoryRulesSheet(
      context,
      rules: [
        ImportCategoryRule(
          id: 'expense:orlen',
          pattern: 'ORLEN',
          category: 'Transport',
          type: TransactionType.expense,
          updatedAt: DateTime(2026, 6, 1),
        ),
        ImportCategoryRule(
          id: 'expense:netflix',
          pattern: 'NETFLIX',
          category: 'Subskrypcje',
          type: TransactionType.expense,
          updatedAt: DateTime(2026, 6, 2),
        ),
      ],
      availableCategories: const [
        FinanceCategory(
          id: '',
          name: 'Transport',
          type: TransactionType.expense,
        ),
        FinanceCategory(id: '', name: 'Auto', type: TransactionType.expense),
        FinanceCategory(
          id: '',
          name: 'Subskrypcje',
          type: TransactionType.expense,
        ),
      ],
    );

    await tester.pumpAndSettle();

    final categoryField = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(categoryField);
    await tester.tap(categoryField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Usun regule').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    final result = await future;

    expect(result, isNotNull);
    expect(result, hasLength(1));
    expect(result!.single.pattern, 'ORLEN');
    expect(result.single.category, 'Auto');
  });
}
