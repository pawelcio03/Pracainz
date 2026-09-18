import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/finance_models.dart';
import '../domain/goal_repository.dart';

class FirestoreGoalRepository implements GoalRepository {
  const FirestoreGoalRepository({this.firestore});

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) {
    return _goals(userId).orderBy('deadline').snapshots().map((snapshot) {
      return snapshot.docs.map(_fromDocument).toList();
    });
  }

  @override
  Future<void> createGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {
    await _goals(userId).add(_toDocument(goal, isCreate: true));
  }

  @override
  Future<void> updateGoal({
    required String userId,
    required SavingsGoal goal,
  }) async {
    await _goals(
      userId,
    ).doc(goal.id).update(_toDocument(goal, isCreate: false));
  }

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    await _goals(userId).doc(goalId).delete();
  }

  CollectionReference<Map<String, dynamic>> _goals(String userId) {
    return _firestore.collection('users').doc(userId).collection('goals');
  }

  SavingsGoal _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return SavingsGoal(
      id: document.id,
      name: data['name'] as String? ?? 'Cel',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0,
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _toDocument(SavingsGoal goal, {required bool isCreate}) {
    return {
      'name': goal.name.trim(),
      'targetAmount': goal.targetAmount,
      'savedAmount': goal.savedAmount,
      'deadline': Timestamp.fromDate(goal.deadline),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
