import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/goals/application/goal_forecast.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  test('goal forecast calculates projected completion and required pace', () {
    final snapshot = GoalForecastSnapshot.fromData(
      goal: SavingsGoal(
        id: 'goal-1',
        name: 'Poduszka',
        targetAmount: 5000,
        savedAmount: 1700,
        deadline: DateTime(2026, 12, 31),
      ),
      contributions: [
        FinanceTransaction(
          id: 'tx-1',
          title: 'Wplata maj',
          category: 'Oszczednosci',
          amount: 300,
          date: DateTime(2026, 5, 10),
          type: TransactionType.transfer,
          goalId: 'goal-1',
        ),
        FinanceTransaction(
          id: 'tx-2',
          title: 'Wplata czerwiec',
          category: 'Oszczednosci',
          amount: 400,
          date: DateTime(2026, 6, 10),
          type: TransactionType.transfer,
          goalId: 'goal-1',
        ),
      ],
      referenceDate: DateTime(2026, 6, 15),
    );

    expect(snapshot.remainingAmount, 3300);
    expect(snapshot.averageMonthlyContribution, 350);
    expect(snapshot.requiredMonthlyContribution, closeTo(471.43, 0.01));
    expect(snapshot.projectedMonthsToGoal, 10);
    expect(snapshot.projectedCompletionDate, DateTime(2027, 3, 31));
    expect(snapshot.isOnTrack, isFalse);
    expect(snapshot.needsCatchUp, isTrue);
  });
}
