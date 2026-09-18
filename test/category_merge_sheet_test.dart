import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/categories/presentation/category_merge_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets('returns selected target category from merge sheet', (
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

    final future = showCategoryMergeSheet(
      context,
      sourceCategory: const FinanceCategory(
        id: 'category-source',
        name: 'Spozywcze',
        type: TransactionType.expense,
      ),
      candidateCategories: const [
        FinanceCategory(
          id: 'category-target-1',
          name: 'Jedzenie',
          type: TransactionType.expense,
        ),
        FinanceCategory(
          id: 'category-target-2',
          name: 'Dom',
          type: TransactionType.expense,
        ),
      ],
      transactionCount: 4,
      budgetCount: 1,
      subscriptionCount: 2,
      recurringIncomeCount: 0,
    );

    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dom').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scal i przepnij dane'));
    await tester.pumpAndSettle();

    final result = await future;

    expect(result, isNotNull);
    expect(result!.id, 'category-target-2');
  });
}
