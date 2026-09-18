import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/investment_repository.dart';
import '../domain/investment_quote_service.dart';

class InvestmentsController extends ChangeNotifier {
  InvestmentsController({
    required this.repository,
    required this.userId,
    required this.quoteService,
  }) {
    _subscription = repository
        .watchInvestments(userId)
        .listen(
          (investments) {
            _investments = investments;
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  final InvestmentRepository repository;
  final String userId;
  final InvestmentQuoteService quoteService;
  late final StreamSubscription<List<InvestmentHolding>> _subscription;

  bool _isLoading = true;
  bool _isRefreshingMarketData = false;
  Object? _error;
  DateTime? _lastSuccessfulRefreshAt;
  List<InvestmentHolding> _investments = const [];

  bool get isLoading => _isLoading;

  bool get isRefreshingMarketData => _isRefreshingMarketData;

  Object? get error => _error;

  DateTime? get lastSuccessfulRefreshAt => _lastSuccessfulRefreshAt;

  List<InvestmentHolding> get investments => _investments;

  Future<void> save(InvestmentHolding investment) async {
    final sanitizedInvestment = FinanceInputSanitizer.sanitizeInvestment(
      investment,
    );

    if (sanitizedInvestment.isPersisted) {
      final existingInvestment = _findInvestmentById(sanitizedInvestment.id);
      if (_shouldClearPriceHistory(existingInvestment, sanitizedInvestment)) {
        await repository.clearPriceHistory(
          userId: userId,
          investmentId: sanitizedInvestment.id,
        );
      }

      await repository.updateInvestment(
        userId: userId,
        investment: sanitizedInvestment,
      );
      _replaceLocalInvestment(sanitizedInvestment);
      return;
    }

    final matchingInvestment = _findMatchingInvestment(sanitizedInvestment);
    if (matchingInvestment != null) {
      final mergedInvestment = _mergeInvestments(
        existingInvestment: matchingInvestment,
        addedInvestment: sanitizedInvestment,
      );
      await repository.updateInvestment(
        userId: userId,
        investment: mergedInvestment,
      );
      _replaceLocalInvestment(mergedInvestment);
      return;
    }

    await repository.createInvestment(
      userId: userId,
      investment: sanitizedInvestment,
    );
  }

  Future<int> refreshMarketPrices({
    bool force = false,
    String? investmentId,
    Duration staleAfter = const Duration(days: 7),
    Duration providerSpacing = const Duration(milliseconds: 1200),
    bool rethrowErrors = true,
  }) async {
    if (_isRefreshingMarketData) {
      return 0;
    }

    final now = DateTime.now();
    final candidates = _investments.where((investment) {
      if (!investment.supportsMarketData) {
        return false;
      }
      if (investmentId != null && investment.id != investmentId) {
        return false;
      }

      if (force) {
        return true;
      }

      if (investment.lastPriceDate == null) {
        return true;
      }

      final lastUpdateAt = investment.lastPriceUpdateAt;
      if (lastUpdateAt == null) {
        return true;
      }

      return now.difference(lastUpdateAt) >= staleAfter;
    }).toList();

    if (candidates.isEmpty) {
      return 0;
    }

    _isRefreshingMarketData = true;
    notifyListeners();

    var refreshedCount = 0;
    try {
      for (var index = 0; index < candidates.length; index++) {
        final investment = candidates[index];
        final refreshedAt = DateTime.now();
        final history = await quoteService.fetchDailyHistory(
          assetType: investment.assetType,
          symbol: investment.symbol,
        );
        final latestPrice = history.latest;
        final updatedInvestment = investment.copyWith(
          currentPrice: latestPrice.closePrice,
          lastPriceUpdateAt: refreshedAt,
          lastPriceDate: latestPrice.priceDate,
        );

        await repository.updateInvestment(
          userId: userId,
          investment: updatedInvestment,
        );
        await repository.upsertPriceHistoryPoints(
          userId: userId,
          investmentId: investment.id,
          pricePoints: history.prices
              .map(
                (point) => InvestmentPricePoint(
                  id: _pricePointId(point.priceDate),
                  investmentId: investment.id,
                  closePrice: point.closePrice,
                  priceDate: point.priceDate,
                  recordedAt: refreshedAt,
                ),
              )
              .toList(),
        );
        refreshedCount++;

        if (index < candidates.length - 1) {
          await Future<void>.delayed(providerSpacing);
        }
      }

      _lastSuccessfulRefreshAt = now;
      _error = null;
      return refreshedCount;
    } catch (error) {
      if (rethrowErrors) {
        rethrow;
      }
      return refreshedCount;
    } finally {
      _isRefreshingMarketData = false;
      notifyListeners();
    }
  }

  Future<void> delete(InvestmentHolding investment) {
    return repository.deleteInvestment(
      userId: userId,
      investmentId: investment.id,
    );
  }

  InvestmentHolding? _findInvestmentById(String investmentId) {
    for (final investment in _investments) {
      if (investment.id == investmentId) {
        return investment;
      }
    }

    return null;
  }

  InvestmentHolding? _findMatchingInvestment(InvestmentHolding investment) {
    final identityKey = _investmentIdentityKey(investment);
    if (identityKey.isEmpty) {
      return null;
    }

    for (final existingInvestment in _investments) {
      if (existingInvestment.id == investment.id) {
        continue;
      }
      if (_investmentIdentityKey(existingInvestment) == identityKey) {
        return existingInvestment;
      }
    }

    return null;
  }

  InvestmentHolding _mergeInvestments({
    required InvestmentHolding existingInvestment,
    required InvestmentHolding addedInvestment,
  }) {
    final combinedUnits = existingInvestment.units + addedInvestment.units;
    final combinedBuyPrice = _weightedAverageBuyPrice(
      existingUnits: existingInvestment.units,
      existingBuyPrice: existingInvestment.buyPrice,
      addedUnits: addedInvestment.units,
      addedBuyPrice: addedInvestment.buyPrice,
    );
    final shouldUseAddedCurrentPrice =
        existingInvestment.currentPrice <= 0 ||
        addedInvestment.lastPriceUpdateAt != null ||
        addedInvestment.lastPriceDate != null;

    return existingInvestment.copyWith(
      name: existingInvestment.name.trim().isEmpty
          ? addedInvestment.name
          : existingInvestment.name,
      units: combinedUnits,
      buyPrice: combinedBuyPrice,
      currentPrice: shouldUseAddedCurrentPrice
          ? addedInvestment.currentPrice
          : existingInvestment.currentPrice,
      lastPriceUpdateAt: shouldUseAddedCurrentPrice
          ? addedInvestment.lastPriceUpdateAt
          : existingInvestment.lastPriceUpdateAt,
      lastPriceDate: shouldUseAddedCurrentPrice
          ? addedInvestment.lastPriceDate
          : existingInvestment.lastPriceDate,
    );
  }

  double _weightedAverageBuyPrice({
    required double existingUnits,
    required double existingBuyPrice,
    required double addedUnits,
    required double addedBuyPrice,
  }) {
    final combinedUnits = existingUnits + addedUnits;
    if (combinedUnits <= 0) {
      return 0;
    }

    final combinedCost =
        (existingUnits * existingBuyPrice) + (addedUnits * addedBuyPrice);
    return combinedCost / combinedUnits;
  }

  void _replaceLocalInvestment(InvestmentHolding investment) {
    _investments = _investments
        .map((current) => current.id == investment.id ? investment : current)
        .toList(growable: false);
    notifyListeners();
  }

  String _investmentIdentityKey(InvestmentHolding investment) {
    final normalizedSymbol = _normalizedSymbol(investment);
    if (normalizedSymbol.isNotEmpty) {
      return '${investment.assetType.name}:symbol:$normalizedSymbol';
    }

    final normalizedName = investment.name.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return '';
    }
    return '${investment.assetType.name}:name:$normalizedName';
  }

  bool _shouldClearPriceHistory(
    InvestmentHolding? existingInvestment,
    InvestmentHolding updatedInvestment,
  ) {
    if (existingInvestment == null) {
      return false;
    }

    if (!updatedInvestment.supportsMarketData) {
      return existingInvestment.supportsMarketData;
    }

    return existingInvestment.assetType != updatedInvestment.assetType ||
        _normalizedSymbol(existingInvestment) !=
            _normalizedSymbol(updatedInvestment);
  }

  String _normalizedSymbol(InvestmentHolding investment) {
    try {
      return FinanceInputSanitizer.normalizeInvestmentSymbolInput(
        investment.symbol,
        fieldLabel: investment.assetType.symbolFieldLabel,
        required: false,
      );
    } on Object {
      return investment.symbol.trim().toUpperCase();
    }
  }

  String _pricePointId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
