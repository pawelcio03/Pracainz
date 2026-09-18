import '../../../models/finance_models.dart';

class GoalForecastSnapshot {
  const GoalForecastSnapshot({
    required this.remainingAmount,
    required this.contributionCount,
    required this.activeMonths,
    required this.averageContribution,
    required this.averageMonthlyContribution,
    required this.requiredMonthlyContribution,
    required this.monthsUntilDeadline,
    required this.projectedMonthsToGoal,
    required this.projectedCompletionDate,
    required this.isOnTrack,
    required this.isCompleted,
  });

  factory GoalForecastSnapshot.fromData({
    required SavingsGoal goal,
    required List<FinanceTransaction> contributions,
    DateTime? referenceDate,
  }) {
    final effectiveReferenceDate = referenceDate ?? DateTime.now();
    final normalizedReferenceDate = DateTime(
      effectiveReferenceDate.year,
      effectiveReferenceDate.month,
      effectiveReferenceDate.day,
    );
    final remainingAmount =
        (goal.targetAmount - goal.savedAmount).clamp(0, double.infinity)
            as double;
    final contributionCount = contributions.length;
    final contributionTotal = contributions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final activeMonthKeys = contributions
        .map(
          (transaction) => '${transaction.date.year}-${transaction.date.month}',
        )
        .toSet();
    final activeMonths = activeMonthKeys.length;
    final averageContribution = contributionCount == 0
        ? 0.0
        : contributionTotal / contributionCount;
    final averageMonthlyContribution = activeMonths == 0
        ? 0.0
        : contributionTotal / activeMonths;
    final monthsUntilDeadline = _monthsUntilDeadline(
      normalizedReferenceDate,
      goal.deadline,
    );
    final requiredMonthlyContribution =
        monthsUntilDeadline == 0 || remainingAmount == 0
        ? 0.0
        : remainingAmount / monthsUntilDeadline;
    final isCompleted = remainingAmount == 0;

    if (isCompleted) {
      return GoalForecastSnapshot(
        remainingAmount: remainingAmount,
        contributionCount: contributionCount,
        activeMonths: activeMonths,
        averageContribution: averageContribution,
        averageMonthlyContribution: averageMonthlyContribution,
        requiredMonthlyContribution: requiredMonthlyContribution,
        monthsUntilDeadline: monthsUntilDeadline,
        projectedMonthsToGoal: 0,
        projectedCompletionDate: normalizedReferenceDate,
        isOnTrack: true,
        isCompleted: true,
      );
    }

    if (averageMonthlyContribution <= 0) {
      return GoalForecastSnapshot(
        remainingAmount: remainingAmount,
        contributionCount: contributionCount,
        activeMonths: activeMonths,
        averageContribution: averageContribution,
        averageMonthlyContribution: averageMonthlyContribution,
        requiredMonthlyContribution: requiredMonthlyContribution,
        monthsUntilDeadline: monthsUntilDeadline,
        projectedMonthsToGoal: null,
        projectedCompletionDate: null,
        isOnTrack: false,
        isCompleted: false,
      );
    }

    final projectedMonthsToGoal = (remainingAmount / averageMonthlyContribution)
        .ceil();
    final projectedCompletionDate = DateTime(
      normalizedReferenceDate.year,
      normalizedReferenceDate.month + projectedMonthsToGoal - 1,
      goal.deadline.day,
    );

    return GoalForecastSnapshot(
      remainingAmount: remainingAmount,
      contributionCount: contributionCount,
      activeMonths: activeMonths,
      averageContribution: averageContribution,
      averageMonthlyContribution: averageMonthlyContribution,
      requiredMonthlyContribution: requiredMonthlyContribution,
      monthsUntilDeadline: monthsUntilDeadline,
      projectedMonthsToGoal: projectedMonthsToGoal,
      projectedCompletionDate: projectedCompletionDate,
      isOnTrack: !projectedCompletionDate.isAfter(goal.deadline),
      isCompleted: false,
    );
  }

  final double remainingAmount;
  final int contributionCount;
  final int activeMonths;
  final double averageContribution;
  final double averageMonthlyContribution;
  final double requiredMonthlyContribution;
  final int monthsUntilDeadline;
  final int? projectedMonthsToGoal;
  final DateTime? projectedCompletionDate;
  final bool isOnTrack;
  final bool isCompleted;

  bool get hasHistory => contributionCount > 0;

  bool get needsCatchUp =>
      !isCompleted &&
      requiredMonthlyContribution > 0 &&
      averageMonthlyContribution < requiredMonthlyContribution;
}

int _monthsUntilDeadline(DateTime referenceDate, DateTime deadline) {
  final normalizedDeadline = DateTime(
    deadline.year,
    deadline.month,
    deadline.day,
  );
  if (normalizedDeadline.isBefore(referenceDate)) {
    return 0;
  }

  final monthsDifference =
      (normalizedDeadline.year - referenceDate.year) * 12 +
      normalizedDeadline.month -
      referenceDate.month;

  return monthsDifference + 1;
}
