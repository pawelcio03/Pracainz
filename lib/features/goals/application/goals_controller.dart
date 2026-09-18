import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../models/finance_models.dart';
import '../domain/goal_repository.dart';

class GoalsController extends ChangeNotifier {
  GoalsController({required this.repository, required this.userId}) {
    _subscription = repository
        .watchGoals(userId)
        .listen(
          (goals) {
            _goals = goals;
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

  final GoalRepository repository;
  final String userId;
  late final StreamSubscription<List<SavingsGoal>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<SavingsGoal> _goals = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<SavingsGoal> get goals => _goals;

  Future<void> save(SavingsGoal goal) async {
    final sanitizedGoal = FinanceInputSanitizer.sanitizeGoal(goal);

    if (sanitizedGoal.isPersisted) {
      await repository.updateGoal(userId: userId, goal: sanitizedGoal);
      return;
    }

    await repository.createGoal(userId: userId, goal: sanitizedGoal);
  }

  Future<void> delete(SavingsGoal goal) {
    return repository.deleteGoal(userId: userId, goalId: goal.id);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
