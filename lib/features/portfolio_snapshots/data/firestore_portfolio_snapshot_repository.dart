import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/portfolio_snapshot_repository.dart';

class FirestorePortfolioSnapshotRepository
    implements PortfolioSnapshotRepository {
  const FirestorePortfolioSnapshotRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<PortfolioDailySnapshot>> watchSnapshots(String userId) {
    return _snapshots(userId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  CollectionReference<Map<String, dynamic>> _snapshots(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyPortfolioSnapshots');
  }

  PortfolioDailySnapshot _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final recordedAt =
        (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return PortfolioDailySnapshot(
      id: document.id,
      recordedAt: recordedAt,
      value: (data['value'] as num?)?.toDouble() ?? 0,
    );
  }
}
