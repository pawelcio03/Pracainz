import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/investment_repository.dart';

class FirestoreInvestmentRepository implements InvestmentRepository {
  const FirestoreInvestmentRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<InvestmentHolding>> watchInvestments(String userId) {
    return _investments(userId).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(_fromDocument).toList();
    });
  }

  @override
  Stream<List<InvestmentPricePoint>> watchPriceHistory({
    required String userId,
    required String investmentId,
  }) {
    return _priceHistory(
      userId,
      investmentId,
    ).orderBy('priceDate').snapshots().map((snapshot) {
      return snapshot.docs.map(_pricePointFromDocument).toList();
    });
  }

  @override
  Future<void> createInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {
    await _investments(userId).add(_toDocument(investment, isCreate: true));
  }

  @override
  Future<void> updateInvestment({
    required String userId,
    required InvestmentHolding investment,
  }) async {
    await _investments(
      userId,
    ).doc(investment.id).update(_toDocument(investment, isCreate: false));
  }

  @override
  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  }) async {
    await clearPriceHistory(userId: userId, investmentId: investmentId);
    await _investments(userId).doc(investmentId).delete();
  }

  @override
  Future<void> clearPriceHistory({
    required String userId,
    required String investmentId,
  }) async {
    final historySnapshot = await _priceHistory(userId, investmentId).get();
    if (historySnapshot.docs.isEmpty) {
      return;
    }

    final deleteBatch = _firestore.batch();
    for (final document in historySnapshot.docs) {
      deleteBatch.delete(document.reference);
    }
    await deleteBatch.commit();
  }

  @override
  Future<void> upsertPriceHistoryPoints({
    required String userId,
    required String investmentId,
    required List<InvestmentPricePoint> pricePoints,
  }) async {
    if (pricePoints.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final point in pricePoints) {
      batch.set(
        _priceHistory(userId, investmentId).doc(point.id),
        _pricePointToDocument(point),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _investments(String userId) {
    return _firestore.collection('users').doc(userId).collection('investments');
  }

  CollectionReference<Map<String, dynamic>> _priceHistory(
    String userId,
    String investmentId,
  ) {
    return _investments(userId).doc(investmentId).collection('priceHistory');
  }

  InvestmentHolding _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return InvestmentHolding(
      id: document.id,
      assetType: _assetTypeFromValue(data['assetType'] as String?),
      symbol: data['symbol'] as String? ?? '',
      name: data['name'] as String? ?? 'Aktyw',
      units: (data['units'] as num?)?.toDouble() ?? 0,
      buyPrice: (data['buyPrice'] as num?)?.toDouble() ?? 0,
      currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0,
      lastPriceUpdateAt: _timestampToDate(data['lastPriceUpdateAt']),
      lastPriceDate: _timestampToDate(data['lastPriceDate']),
    );
  }

  Map<String, dynamic> _toDocument(
    InvestmentHolding investment, {
    required bool isCreate,
  }) {
    return {
      'assetType': investment.assetType.name,
      'symbol': investment.symbol.trim().toUpperCase(),
      'name': investment.name.trim(),
      'units': investment.units,
      'buyPrice': investment.buyPrice,
      'currentPrice': investment.currentPrice,
      'lastPriceUpdateAt': investment.lastPriceUpdateAt == null
          ? null
          : Timestamp.fromDate(investment.lastPriceUpdateAt!),
      'lastPriceDate': investment.lastPriceDate == null
          ? null
          : Timestamp.fromDate(investment.lastPriceDate!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InvestmentPricePoint _pricePointFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return InvestmentPricePoint(
      id: document.id,
      investmentId: data['investmentId'] as String? ?? '',
      closePrice: (data['closePrice'] as num?)?.toDouble() ?? 0,
      priceDate:
          _timestampToDate(data['priceDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      recordedAt:
          _timestampToDate(data['recordedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> _pricePointToDocument(InvestmentPricePoint point) {
    return {
      'investmentId': point.investmentId,
      'closePrice': point.closePrice,
      'priceDate': Timestamp.fromDate(point.priceDate),
      'recordedAt': Timestamp.fromDate(point.recordedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  InvestmentAssetType _assetTypeFromValue(String? value) {
    return InvestmentAssetType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => InvestmentAssetType.other,
    );
  }
}
