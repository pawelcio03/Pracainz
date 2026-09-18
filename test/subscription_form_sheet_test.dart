import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/subscriptions/presentation/subscription_form_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets(
    'subscription form hides category picker and saves fixed category',
    (tester) async {
      SubscriptionPlan? submittedSubscription;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedSubscription = await showSubscriptionFormSheet(
                      context,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Kategoria'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa'),
        'Netflix',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kwota obciazenia'),
        '39,99',
      );

    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj subskrypcje'));
      await tester.pumpAndSettle();

      expect(submittedSubscription, isNotNull);
      expect(submittedSubscription!.category, 'Subskrypcje');
    },
  );
}
