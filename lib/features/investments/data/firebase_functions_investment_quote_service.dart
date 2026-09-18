import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/finance_models.dart';
import '../domain/investment_quote_service.dart';

const _cryptoQuoteCurrencies = [
  'USDT',
  'USDC',
  'USD',
  'EUR',
  'PLN',
  'GBP',
  'BTC',
  'ETH',
];

class FirebaseFunctionsInvestmentQuoteService
    implements InvestmentQuoteService {
  const FirebaseFunctionsInvestmentQuoteService({
    this._functions,
    this._httpClient,
    this.region = 'europe-west1',
  });

  final FirebaseFunctions? _functions;
  final http.Client? _httpClient;
  final String region;

  FirebaseFunctions get functions =>
      _functions ?? FirebaseFunctions.instanceFor(region: region);

  http.Client get httpClient => _httpClient ?? http.Client();

  @override
  Future<InvestmentMarketHistorySnapshot> fetchDailyHistory({
    required InvestmentAssetType assetType,
    required String symbol,
    int maxPoints = 30,
  }) async {
    final normalizedSymbol = symbol.trim().toUpperCase().replaceAll(
      RegExp(r'[/\s]+'),
      '',
    );
    if (normalizedSymbol.isEmpty) {
      throw const InvestmentQuoteException(
        'Brakuje tickera do pobrania kursu.',
      );
    }

    try {
      if (_shouldUseHttpFallback) {
        try {
          return await _fetchViaHttp(
            assetType: assetType,
            symbol: normalizedSymbol,
            maxPoints: maxPoints,
          );
        } catch (error) {
          return _fetchViaDirectBinance(
            assetType: assetType,
            symbol: normalizedSymbol,
            maxPoints: maxPoints,
            backendError: error,
          );
        }
      }

      try {
        final callable = functions.httpsCallable('fetchInvestmentHistory');
        final result = await callable.call(<String, dynamic>{
          'assetType': assetType.name,
          'symbol': normalizedSymbol,
          'maxPoints': maxPoints,
        });
        final payload = Map<String, dynamic>.from(result.data as Map);
        return _historyFromPayload(payload, normalizedSymbol);
      } on FirebaseFunctionsException catch (error) {
        return _fetchViaDirectBinance(
          assetType: assetType,
          symbol: normalizedSymbol,
          maxPoints: maxPoints,
          backendError: error.message ?? _messageForCode(error.code),
        );
      }
    } on InvestmentQuoteException {
      rethrow;
    } catch (error) {
      return _fetchViaDirectBinance(
        assetType: assetType,
        symbol: normalizedSymbol,
        maxPoints: maxPoints,
        backendError: error,
      );
    }
  }

  bool get _shouldUseHttpFallback {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => true,
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  Future<InvestmentMarketHistorySnapshot> _fetchViaHttp({
    required InvestmentAssetType assetType,
    required String symbol,
    required int maxPoints,
  }) async {
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw const InvestmentQuoteException(
        'Brakuje identyfikatora projektu Firebase dla kursow.',
      );
    }

    final uri = Uri.parse(
      'https://$region-$projectId.cloudfunctions.net/fetchInvestmentHistoryHttp',
    );
    final response = await httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'assetType': assetType.name,
        'symbol': symbol,
        'maxPoints': maxPoints,
      }),
    );

    final payload = _tryDecodeJson(response.body);
    if (payload is! Map<String, dynamic>) {
      throw InvestmentQuoteException(
        'Backend kursow zwrocil niepoprawna odpowiedz dla $symbol.',
      );
    }

    final error = payload['error'];
    if (error is Map) {
      throw InvestmentQuoteException(
        (error['message'] as String?) ??
            'Nie udalo sie pobrac danych rynkowych.',
      );
    }

    return _historyFromPayload(payload, symbol);
  }

  InvestmentMarketHistorySnapshot _historyFromPayload(
    Map<String, dynamic> payload,
    String symbol,
  ) {
    final rawPrices = payload['prices'];
    if (rawPrices is! List || rawPrices.isEmpty) {
      throw InvestmentQuoteException(
        'Backend nie zwrocil historii cen dla $symbol.',
      );
    }

    final points = rawPrices
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (item) => RemoteInvestmentPricePoint(
            priceDate: DateTime.parse(item['priceDate'] as String),
            closePrice: (item['closePrice'] as num).toDouble(),
          ),
        )
        .toList();

    return InvestmentMarketHistorySnapshot(prices: points);
  }

  Future<InvestmentMarketHistorySnapshot> _fetchViaDirectBinance({
    required InvestmentAssetType assetType,
    required String symbol,
    required int maxPoints,
    required Object backendError,
  }) async {
    if (assetType != InvestmentAssetType.crypto) {
      throw _quoteExceptionFromBackendError(symbol, backendError);
    }

    try {
      final pair = _resolveCryptoPair(symbol);
      final historyUri = Uri.https('api.binance.com', '/api/v3/klines', {
        'symbol': pair,
        'interval': '1d',
        'limit': maxPoints.toString(),
      });
      final historyResponse = await httpClient.get(historyUri);
      final historyPayload = _tryDecodeJson(historyResponse.body);

      if (historyResponse.statusCode == 200 && historyPayload is List) {
        final points =
            historyPayload
                .map(_pricePointFromKline)
                .whereType<RemoteInvestmentPricePoint>()
                .toList()
              ..sort(
                (left, right) => right.priceDate.compareTo(left.priceDate),
              );
        if (points.isNotEmpty) {
          return InvestmentMarketHistorySnapshot(prices: points);
        }
      }

      final tickerUri = Uri.https('api.binance.com', '/api/v3/ticker/price', {
        'symbol': pair,
      });
      final tickerResponse = await httpClient.get(tickerUri);
      final tickerPayload = _tryDecodeJson(tickerResponse.body);
      final closePrice = tickerPayload is Map<String, dynamic>
          ? _asDouble(tickerPayload['price'])
          : null;
      if (tickerResponse.statusCode == 200 && closePrice != null) {
        final now = DateTime.now().toUtc();
        return InvestmentMarketHistorySnapshot(
          prices: [
            RemoteInvestmentPricePoint(
              priceDate: DateTime.utc(now.year, now.month, now.day),
              closePrice: closePrice,
            ),
          ],
        );
      }
    } catch (_) {
      throw _quoteExceptionFromBackendError(symbol, backendError);
    }

    throw _quoteExceptionFromBackendError(symbol, backendError);
  }

  RemoteInvestmentPricePoint? _pricePointFromKline(Object? item) {
    if (item is! List || item.length < 5) {
      return null;
    }

    final openTime = _asDouble(item[0]);
    final closePrice = _asDouble(item[4]);
    if (openTime == null || closePrice == null) {
      return null;
    }

    return RemoteInvestmentPricePoint(
      priceDate: DateTime.fromMillisecondsSinceEpoch(
        openTime.toInt(),
        isUtc: true,
      ),
      closePrice: closePrice,
    );
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _resolveCryptoPair(String symbol) {
    final compactSymbol = symbol.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (compactSymbol.isEmpty) {
      throw const InvestmentQuoteException('Brakuje tickera krypto.');
    }

    if (compactSymbol.length <= 5) {
      return '${compactSymbol}USDT';
    }

    for (final quoteCurrency in _cryptoQuoteCurrencies) {
      if (compactSymbol.endsWith(quoteCurrency) &&
          compactSymbol.length > quoteCurrency.length) {
        final baseSymbol = compactSymbol.substring(
          0,
          compactSymbol.length - quoteCurrency.length,
        );
        final marketSymbol = quoteCurrency == 'USD' ? 'USDT' : quoteCurrency;
        return '$baseSymbol$marketSymbol';
      }
    }

    return '${compactSymbol}USDT';
  }

  InvestmentQuoteException _quoteExceptionFromBackendError(
    String symbol,
    Object error,
  ) {
    if (error is InvestmentQuoteException) {
      return error;
    }
    if (error is FirebaseFunctionsException) {
      return InvestmentQuoteException(
        error.message ?? _messageForCode(error.code),
      );
    }
    if (error is String && error.trim().isNotEmpty) {
      return InvestmentQuoteException(error);
    }
    return InvestmentQuoteException(
      'Nie udalo sie pobrac danych rynkowych dla $symbol.',
    );
  }

  Object? _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _messageForCode(String code) {
    return switch (code) {
      'unauthenticated' =>
        'Odswiezanie kursow wymaga zalogowanego uzytkownika.',
      'failed-precondition' =>
        'Backend kursow odrzucil zapytanie. Sprawdz, czy podany symbol krypto jest obslugiwany.',
      'not-found' => 'Nie znaleziono danych dla podanego tickera.',
      'resource-exhausted' =>
        'Limit zapytan do zrodla kursow zostal chwilowo wyczerpany.',
      _ => 'Nie udalo sie pobrac danych rynkowych.',
    };
  }
}
