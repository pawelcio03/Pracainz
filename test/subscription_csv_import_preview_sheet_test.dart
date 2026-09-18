import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/subscription_import/domain/subscription_csv_import_preview.dart';
import 'package:finovo/features/subscription_import/presentation/subscription_csv_import_preview_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets('returns edited subscription categories from preview sheet', (
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

    final future = showSubscriptionCsvImportPreviewSheet(
      context,
      preview: SubscriptionCsvImportPreview(
        formatLabel: 'CSV z mapowaniem kolumn',
        subscriptionsToImport: [
          SubscriptionPlan(
            id: '',
            name: 'Netflix',
            category: 'Rozrywka',
            amount: 29.0,
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime(2026, 6, 10),
            isActive: true,
          ),
        ],
        duplicateCount: 0,
        issues: const [],
      ),
      availableCategories: const ['Rozrywka', 'Dom'],
    );

    await tester.pumpAndSettle();

    final categoryField = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(categoryField);
    await tester.pumpAndSettle();
    await tester.tap(categoryField, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dom').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importuj 1'));
    await tester.pumpAndSettle();

    final result = await future;

    expect(result, isNotNull);
    expect(result, hasLength(1));
    expect(result!.single.category, 'Dom');
  });
}
