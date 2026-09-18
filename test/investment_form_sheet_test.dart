import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/investments/presentation/investment_form_sheet.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  testWidgets(
    'bond form uses preset market and series without manual name field',
    (tester) async {
      InvestmentHolding? submittedInvestment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
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

      await tester.tap(find.text('Krypto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obligacje').last);
      await tester.pumpAndSettle();

      expect(find.text('Rynek obligacji'), findsOneWidget);
      expect(find.text('Nazwa aktywa'), findsNothing);

      await tester.enterText(find.byType(TextFormField).at(0), '2');
      await tester.enterText(find.byType(TextFormField).at(1), '100');
      await tester.tap(find.text('Dodaj pozycje').last);
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.assetType, InvestmentAssetType.bond);
      expect(submittedInvestment!.symbol, 'OTS');
      expect(submittedInvestment!.name, 'Obligacje Skarbowe 3M');
    },
  );

  testWidgets('etf form allows saving without optional ticker', (tester) async {
    InvestmentHolding? submittedInvestment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  submittedInvestment = await showInvestmentFormSheet(context);
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

    await tester.tap(find.text('Krypto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ETF').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'Globalny ETF');
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.enterText(find.byType(TextFormField).at(3), '100');
    await tester.tap(find.text('Dodaj pozycje').last);
    await tester.pumpAndSettle();

    expect(submittedInvestment, isNotNull);
    expect(submittedInvestment!.assetType, InvestmentAssetType.etf);
    expect(submittedInvestment!.symbol, isEmpty);
    expect(submittedInvestment!.currentPrice, 100);
    expect(submittedInvestment!.lastPriceUpdateAt, isNull);
    expect(submittedInvestment!.lastPriceDate, isNull);
  });

  testWidgets('crypto form normalizes slash separated PLN pair', (
    tester,
  ) async {
    InvestmentHolding? submittedInvestment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  submittedInvestment = await showInvestmentFormSheet(context);
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

    await tester.enterText(find.byType(TextFormField).at(0), 'btc/pln');
    await tester.enterText(find.byType(TextFormField).at(1), 'Bitcoin');
    await tester.enterText(find.byType(TextFormField).at(2), '1');
    await tester.enterText(find.byType(TextFormField).at(3), '250000');
    await tester.tap(find.text('Dodaj pozycje').last);
    await tester.pumpAndSettle();

    expect(submittedInvestment, isNotNull);
    expect(submittedInvestment!.assetType, InvestmentAssetType.crypto);
    expect(submittedInvestment!.symbol, 'BTCPLN');
    expect(submittedInvestment!.currentPrice, 250000);
  });

  testWidgets(
    'editing market asset without fetched quote syncs current price to updated buy price',
    (tester) async {
      InvestmentHolding? submittedInvestment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
                      context,
                      initialInvestment: const InvestmentHolding(
                        id: 'investment-1',
                        assetType: InvestmentAssetType.crypto,
                        symbol: 'BTCUSDT',
                        name: 'Bitcoin',
                        units: 100,
                        buyPrice: 135,
                        currentPrice: 135,
                      ),
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

      await tester.enterText(find.byType(TextFormField).at(3), '139');
      await tester.tap(find.text('Zapisz pozycje'));
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.buyPrice, 139);
      expect(submittedInvestment!.currentPrice, 139);
      expect(submittedInvestment!.lastPriceUpdateAt, isNull);
      expect(submittedInvestment!.lastPriceDate, isNull);
    },
  );

  testWidgets(
    'editing market asset with fetched quote preserves current market price',
    (tester) async {
      InvestmentHolding? submittedInvestment;
      final lastUpdateAt = DateTime(2026, 6, 7, 10, 30);
      final lastPriceDate = DateTime(2026, 6, 6);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
                      context,
                      initialInvestment: InvestmentHolding(
                        id: 'investment-1',
                        assetType: InvestmentAssetType.crypto,
                        symbol: 'BTCUSDT',
                        name: 'Bitcoin',
                        units: 100,
                        buyPrice: 135,
                        currentPrice: 150,
                        lastPriceUpdateAt: lastUpdateAt,
                        lastPriceDate: lastPriceDate,
                      ),
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

      await tester.enterText(find.byType(TextFormField).at(3), '139');
      await tester.tap(find.text('Zapisz pozycje'));
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.buyPrice, 139);
      expect(submittedInvestment!.currentPrice, 150);
      expect(submittedInvestment!.lastPriceUpdateAt, lastUpdateAt);
      expect(submittedInvestment!.lastPriceDate, lastPriceDate);
    },
  );

  testWidgets('editing current price records manual valuation', (tester) async {
    InvestmentHolding? submittedInvestment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  submittedInvestment = await showInvestmentFormSheet(
                    context,
                    initialInvestment: const InvestmentHolding(
                      id: 'investment-1',
                      assetType: InvestmentAssetType.crypto,
                      symbol: 'BTCUSDT',
                      name: 'Bitcoin',
                      units: 1,
                      buyPrice: 100000,
                      currentPrice: 101000,
                    ),
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

    await tester.enterText(find.byType(TextFormField).at(4), '106500');
    await tester.tap(find.text('Zapisz pozycje'));
    await tester.pumpAndSettle();

    expect(submittedInvestment, isNotNull);
    expect(submittedInvestment!.currentPrice, 106500);
    expect(submittedInvestment!.lastPriceUpdateAt, isNotNull);
    expect(submittedInvestment!.lastPriceDate, isNotNull);
  });

  testWidgets(
    'editing asset resets stale mirrored market snapshot when current price matches old buy price',
    (tester) async {
      InvestmentHolding? submittedInvestment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
                      context,
                      initialInvestment: InvestmentHolding(
                        id: 'investment-1',
                        assetType: InvestmentAssetType.crypto,
                        symbol: 'BTCUSDT',
                        name: 'Bitcoin',
                        units: 1000,
                        buyPrice: 135,
                        currentPrice: 135,
                        lastPriceUpdateAt: DateTime(2026, 6, 7, 10, 30),
                        lastPriceDate: DateTime(2026, 6, 6),
                      ),
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

      await tester.enterText(find.byType(TextFormField).at(3), '139');
      await tester.tap(find.text('Zapisz pozycje'));
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.buyPrice, 139);
      expect(submittedInvestment!.currentPrice, 139);
      expect(submittedInvestment!.lastPriceUpdateAt, isNull);
      expect(submittedInvestment!.lastPriceDate, isNull);
    },
  );

  testWidgets(
    'editing asset resets incomplete market snapshot when price date is missing',
    (tester) async {
      InvestmentHolding? submittedInvestment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
                      context,
                      initialInvestment: InvestmentHolding(
                        id: 'investment-1',
                        assetType: InvestmentAssetType.crypto,
                        symbol: 'BTCUSDT',
                        name: 'Bitcoin',
                        units: 1000,
                        buyPrice: 135,
                        currentPrice: 135,
                        lastPriceUpdateAt: DateTime(2026, 6, 7, 10, 30),
                      ),
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

      await tester.enterText(find.byType(TextFormField).at(3), '139');
      await tester.tap(find.text('Zapisz pozycje'));
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.buyPrice, 139);
      expect(submittedInvestment!.currentPrice, 139);
      expect(submittedInvestment!.lastPriceUpdateAt, isNull);
      expect(submittedInvestment!.lastPriceDate, isNull);
    },
  );

  testWidgets(
    'changing ticker resets stale market snapshot to edited buy price',
    (tester) async {
      InvestmentHolding? submittedInvestment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () async {
                    submittedInvestment = await showInvestmentFormSheet(
                      context,
                      initialInvestment: InvestmentHolding(
                        id: 'investment-1',
                        assetType: InvestmentAssetType.crypto,
                        symbol: 'BTCUSDT',
                        name: 'Bitcoin',
                        units: 100,
                        buyPrice: 135,
                        currentPrice: 150,
                        lastPriceUpdateAt: DateTime(2026, 6, 7, 10, 30),
                        lastPriceDate: DateTime(2026, 6, 6),
                      ),
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

      await tester.enterText(find.byType(TextFormField).first, 'ETHUSDT');
      await tester.enterText(find.byType(TextFormField).at(3), '139');
      await tester.tap(find.text('Zapisz pozycje'));
      await tester.pumpAndSettle();

      expect(submittedInvestment, isNotNull);
      expect(submittedInvestment!.symbol, 'ETHUSDT');
      expect(submittedInvestment!.buyPrice, 139);
      expect(submittedInvestment!.currentPrice, 139);
      expect(submittedInvestment!.lastPriceUpdateAt, isNull);
      expect(submittedInvestment!.lastPriceDate, isNull);
    },
  );
}
