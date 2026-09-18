import '../../../models/finance_models.dart';

class InvestmentMarketHistorySnapshot {
  const InvestmentMarketHistorySnapshot({required this.prices});

  final List<RemoteInvestmentPricePoint> prices;

  RemoteInvestmentPricePoint get latest => prices.first;
}

class RemoteInvestmentPricePoint {
  const RemoteInvestmentPricePoint({
    required this.priceDate,
    required this.closePrice,
  });

  final DateTime priceDate;
  final double closePrice;
}

abstract class InvestmentQuoteService {
  const InvestmentQuoteService();

  Future<InvestmentMarketHistorySnapshot> fetchDailyHistory({
    required InvestmentAssetType assetType,
    required String symbol,
    int maxPoints = 30,
  });
}

class InvestmentQuoteException implements Exception {
  const InvestmentQuoteException(this.message);

  final String message;

  @override
  String toString() => 'InvestmentQuoteException: $message';
}
