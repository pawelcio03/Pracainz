import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/investments/application/investments_controller.dart';
import 'package:finovo/features/investments/domain/investment_quote_service.dart';
import 'package:finovo/features/investments/domain/investment_repository.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test(
    'controller merges duplicate investment instead of creating new holding',
    () async {
      final repository = _RecordingInvestmentRepository(
        investments: const [
          InvestmentHolding(
            id: 'investment-1',
            assetType: InvestmentAssetType.etf,
            symbol: 'VWCE',
            name: 'ETF globalny',
            units: 2,
            buyPrice: 100,
            currentPrice: 120,
          ),
        ],
      );
      final controller = InvestmentsController(
        repository: repository,
        userId: 'user-1',
        quoteService: const _FakeInvestmentQuoteService(),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      await controller.save(
        const InvestmentHolding(
          id: '',
          assetType: InvestmentAssetType.etf,
          symbol: ' vwce ',
          name: 'VWCE drugi zakup',
          units: 3,
          buyPrice: 160,
          currentPrice: 160,
        ),
      );

      expect(repository.createdInvestments, isEmpty);
      expect(repository.updatedInvestments, hasLength(1));
      expect(repository.lastUpdatedInvestment!.id, 'investment-1');
      expect(repository.lastUpdatedInvestment!.units, 5);
      expect(repository.lastUpdatedInvestment!.buyPrice, 136);
      expect(repository.lastUpdatedInvestment!.currentPrice, 120);
    },
  );

  test('controller clears price history when ticker changes', () async {
    final repository = _RecordingInvestmentRepository(
      investments: const [
        InvestmentHolding(
          id: 'investment-1',
          assetType: InvestmentAssetType.crypto,
          symbol: 'BTCUSDT',
          name: 'Bitcoin',
          units: 10,
          buyPrice: 100,
          currentPrice: 120,
          lastPriceDate: null,
          lastPriceUpdateAt: null,
        ),
      ],
    );
    final controller = InvestmentsController(
      repository: repository,
      userId: 'user-1',
      quoteService: const _FakeInvestmentQuoteService(),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(Duration.zero);

    await controller.save(
      const InvestmentHolding(
        id: 'investment-1',
        assetType: InvestmentAssetType.crypto,
        symbol: 'ETHUSDT',
        name: 'Ethereum',
        units: 10,
        buyPrice: 100,
        currentPrice: 100,
      ),
    );

    expect(repository.clearedInvestmentIds, ['investment-1']);
    expect(repository.lastUpdatedInvestment, isNotNull);
    expect(repository.lastUpdatedInvestment!.symbol, 'ETHUSDT');
  });

  test(
    'controller refreshes edited holding with latest local ticker',
    () async {
      final repository = _RecordingInvestmentRepository(
        investments: const [
          InvestmentHolding(
            id: 'investment-1',
            assetType: InvestmentAssetType.crypto,
            symbol: 'BTCUSD',
            name: 'Bitcoin',
            units: 1,
            buyPrice: 100000,
            currentPrice: 110000,
            lastPriceDate: null,
            lastPriceUpdateAt: null,
          ),
        ],
      );
      final quoteService = _RecordingInvestmentQuoteService(
        closePrice: 234000,
        priceDate: DateTime(2026, 6, 19),
      );
      final controller = InvestmentsController(
        repository: repository,
        userId: 'user-1',
        quoteService: quoteService,
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      await controller.save(
        const InvestmentHolding(
          id: 'investment-1',
          assetType: InvestmentAssetType.crypto,
          symbol: 'BTCPLN',
          name: 'Bitcoin',
          units: 1,
          buyPrice: 200000,
          currentPrice: 200000,
        ),
      );

      final refreshedCount = await controller.refreshMarketPrices(
        investmentId: 'investment-1',
        force: true,
      );

      expect(refreshedCount, 1);
      expect(quoteService.lastSymbol, 'BTCPLN');
      expect(repository.lastUpdatedInvestment!.symbol, 'BTCPLN');
      expect(repository.lastUpdatedInvestment!.currentPrice, 234000);
    },
  );

  test(
    'controller does not clear price history for buy price edit only',
    () async {
      final repository = _RecordingInvestmentRepository(
        investments: const [
          InvestmentHolding(
            id: 'investment-1',
            assetType: InvestmentAssetType.crypto,
            symbol: 'BTCUSDT',
            name: 'Bitcoin',
            units: 10,
            buyPrice: 100,
            currentPrice: 120,
            lastPriceDate: null,
            lastPriceUpdateAt: null,
          ),
        ],
      );
      final controller = InvestmentsController(
        repository: repository,
        userId: 'user-1',
        quoteService: const _FakeInvestmentQuoteService(),
      );
      addTearDown(controller.dispose);

      await Future<void>.delayed(Duration.zero);

      await controller.save(
        const InvestmentHolding(
          id: 'investment-1',
          assetType: InvestmentAssetType.crypto,
          symbol: 'BTCUSDT',
          name: 'Bitcoin',
          units: 10,
          buyPrice: 139,
          currentPrice: 139,
        ),
      );

      expect(repository.clearedInvestmentIds, isEmpty);
      expect(repository.lastUpdatedInvestment, isNotNull);
      expect(repository.lastUpdatedInvestment!.buyPrice, 139);
    },
  );
}

class _RecordingInvestmentRepository implements InvestmentRepository {
  _RecordingInvestmentRepository({required this._investments});

  final List<InvestmentHolding> _investments;
  final List<String> clearedInvestmentIds = <String>[];
  final List<InvestmentHolding> createdInvestments = <InvestmentHolding>[];
  final List<InvestmentHolding> updatedInvestments = <InvestmentHolding>[];
  InvestmentHolding? lastUpdatedInvestment;
  String? lastUpsertedInvestmentId;
  List<InvestmentPricePoint>? lastUpsertedPricePoints;

  @override
  Future<void> clearPriceHistory({
    required String userId,
    required String investmentId,
  }) async {
    clearedInvestmentIds.add(investmentId);
  }

  @override
  Future<void> createInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {
    createdInvestments.add(investment);
  }

  @override
  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  }) async {}

  @override
  Future<void> updateInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {
    updatedInvestments.add(investment);
    lastUpdatedInvestment = investment;
  }

  @override
  Future<void> upsertPriceHistoryPoints({
    required String userId,
    required String investmentId,
    required List<InvestmentPricePoint> pricePoints,
  }) async {
    lastUpsertedInvestmentId = investmentId;
    lastUpsertedPricePoints = pricePoints;
  }

  @override
  Stream<List<InvestmentHolding>> watchInvestments(String userId) {
    return Stream<List<InvestmentHolding>>.value(_investments);
  }

  @override
  Stream<List<InvestmentPricePoint>> watchPriceHistory({
    required String userId,
    required String investmentId,
  }) {
    return const Stream<List<InvestmentPricePoint>>.empty();
  }
}

class _FakeInvestmentQuoteService implements InvestmentQuoteService {
  const _FakeInvestmentQuoteService();

  @override
  Future<InvestmentMarketHistorySnapshot> fetchDailyHistory({
    required InvestmentAssetType assetType,
    required String symbol,
    int maxPoints = 30,
  }) {
    throw UnimplementedError();
  }
}

class _RecordingInvestmentQuoteService implements InvestmentQuoteService {
  _RecordingInvestmentQuoteService({
    required this.closePrice,
    required this.priceDate,
  });

  final double closePrice;
  final DateTime priceDate;
  String? lastSymbol;

  @override
  Future<InvestmentMarketHistorySnapshot> fetchDailyHistory({
    required InvestmentAssetType assetType,
    required String symbol,
    int maxPoints = 30,
  }) async {
    lastSymbol = symbol;
    return InvestmentMarketHistorySnapshot(
      prices: [
        RemoteInvestmentPricePoint(
          priceDate: priceDate,
          closePrice: closePrice,
        ),
      ],
    );
  }
}
