import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/core/validation/finance_input_sanitizer.dart';
import 'package:finovo/core/validation/input_validation_exception.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('sanitizes transaction text fields and optional values', () {
    final transaction = FinanceInputSanitizer.sanitizeTransaction(
      FinanceTransaction(
        id: '',
        title: '  Zakupy   domowe  ',
        category: '  Dom   i  rachunki ',
        amount: 149.99,
        date: DateTime(2026, 6, 4),
        type: TransactionType.expense,
        goalId: '   ',
        note: '  Kupic mleko.  ',
      ),
    );

    expect(transaction.title, 'Zakupy domowe');
    expect(transaction.category, 'Dom i rachunki');
    expect(transaction.goalId, isNull);
    expect(transaction.note, 'Kupic mleko.');
  });

  test('normalizes slash separated investment ticker', () {
    final investment = FinanceInputSanitizer.sanitizeInvestment(
      const InvestmentHolding(
        id: '',
        symbol: 'btc/pln',
        name: 'Bitcoin',
        units: 1,
        buyPrice: 100,
        currentPrice: 150,
      ),
    );

    expect(investment.symbol, 'BTCPLN');
  });

  test('rejects invalid investment ticker format', () {
    expect(
      () => FinanceInputSanitizer.sanitizeInvestment(
        const InvestmentHolding(
          id: '',
          symbol: 'BTC@USDT',
          name: 'Bitcoin',
          units: 1,
          buyPrice: 100,
          currentPrice: 150,
        ),
      ),
      throwsA(isA<InputValidationException>()),
    );
  });

  test('allows bond investment without ticker', () {
    final investment = FinanceInputSanitizer.sanitizeInvestment(
      const InvestmentHolding(
        id: '',
        assetType: InvestmentAssetType.bond,
        symbol: '',
        name: 'COI 2030',
        units: 10,
        buyPrice: 100,
        currentPrice: 100,
      ),
    );

    expect(investment.symbol, isEmpty);
    expect(investment.assetType, InvestmentAssetType.bond);
  });

  test('allows etf investment without ticker', () {
    final investment = FinanceInputSanitizer.sanitizeInvestment(
      const InvestmentHolding(
        id: '',
        assetType: InvestmentAssetType.etf,
        symbol: '',
        name: 'Globalny ETF',
        units: 10,
        buyPrice: 100,
        currentPrice: 105,
      ),
    );

    expect(investment.symbol, isEmpty);
    expect(investment.assetType, InvestmentAssetType.etf);
  });

  test('rejects invalid profile email and avatar url', () {
    expect(
      () => FinanceInputSanitizer.sanitizeUserProfile(
        UserProfile(
          userId: 'user-1',
          displayName: 'Pawel',
          email: 'nie-poprawny-email',
          photoUrl: 'ftp://avatar.example.com/a.png',
          createdAt: DateTime(2026, 1, 1),
          lastSignInAt: DateTime(2026, 6, 4),
          updatedAt: DateTime(2026, 6, 4),
        ),
      ),
      throwsA(isA<InputValidationException>()),
    );
  });
}
