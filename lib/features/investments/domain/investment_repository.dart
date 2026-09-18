import '../../../models/finance_models.dart';

abstract class InvestmentRepository {
  Stream<List<InvestmentHolding>> watchInvestments(String userId);

  Stream<List<InvestmentPricePoint>> watchPriceHistory({
    required String userId,
    required String investmentId,
  });

  Future<void> createInvestment({
    required String userId,
    required InvestmentHolding investment,
  });

  Future<void> updateInvestment({
    required String userId,
    required InvestmentHolding investment,
  });

  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  });

  Future<void> clearPriceHistory({
    required String userId,
    required String investmentId,
  });

  Future<void> upsertPriceHistoryPoints({
    required String userId,
    required String investmentId,
    required List<InvestmentPricePoint> pricePoints,
  });
}
