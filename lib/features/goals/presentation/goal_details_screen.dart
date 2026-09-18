import 'package:flutter/material.dart';

import '../application/goal_forecast.dart';
import '../../../core/formatting/display_number_formatter.dart';
import '../../../models/finance_models.dart';

class GoalDetailsScreen extends StatelessWidget {
  const GoalDetailsScreen({
    super.key,
    required this.goalId,
    required this.listenable,
    required this.goalById,
    required this.startingAmountByGoalId,
    required this.contributionHistoryByGoalId,
    required this.contributionPlansByGoalId,
    required this.nextContributionDateForPlan,
    this.onAddContribution,
    this.onAddContributionPlan,
    this.onEditContribution,
    this.onEditContributionPlan,
    this.onDeleteContribution,
    this.onDeleteContributionPlan,
  });

  final String goalId;
  final Listenable listenable;
  final SavingsGoal? Function(String goalId) goalById;
  final double Function(String goalId) startingAmountByGoalId;
  final List<FinanceTransaction> Function(String goalId)
  contributionHistoryByGoalId;
  final List<GoalContributionPlan> Function(String goalId)
  contributionPlansByGoalId;
  final DateTime? Function(GoalContributionPlan plan)
  nextContributionDateForPlan;
  final Future<void> Function()? onAddContribution;
  final Future<void> Function()? onAddContributionPlan;
  final Future<void> Function(FinanceTransaction transaction)?
  onEditContribution;
  final Future<void> Function(GoalContributionPlan plan)?
  onEditContributionPlan;
  final Future<void> Function(FinanceTransaction transaction)?
  onDeleteContribution;
  final Future<void> Function(GoalContributionPlan plan)?
  onDeleteContributionPlan;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final goal = goalById(goalId);
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Szczegoly celu')),
            body: Center(
              child: Text(
                'Cel nie jest juz dostepny.',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ),
          );
        }

        final contributions = contributionHistoryByGoalId(goalId);
        final contributionPlans = contributionPlansByGoalId(goalId);
        final startingAmount = startingAmountByGoalId(goalId);
        final contributionTotal = contributions.fold<double>(
          0,
          (total, transaction) => total + transaction.amount,
        );
        final remaining =
            (goal.targetAmount - goal.savedAmount).clamp(0, double.infinity)
                as double;
        final latestContribution = contributions.isEmpty
            ? null
            : contributions.first;
        final averageContribution = contributions.isEmpty
            ? 0.0
            : contributionTotal / contributions.length;
        final forecast = GoalForecastSnapshot.fromData(
          goal: goal,
          contributions: contributions,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              if (onAddContribution != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.icon(
                    onPressed: onAddContribution,
                    icon: const Icon(Icons.add),
                    label: const Text('Wplata'),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryCard(
                        goal: goal,
                        startingAmount: startingAmount,
                        contributionTotal: contributionTotal,
                        averageContribution: averageContribution,
                        remaining: remaining,
                        contributionCount: contributions.length,
                        latestContribution: latestContribution,
                      ),
                      const SizedBox(height: 20),
                      _ForecastCard(
                        forecast: forecast,
                        deadline: goal.deadline,
                      ),
                      const SizedBox(height: 20),
                      _ContributionPlansCard(
                        plans: contributionPlans,
                        nextContributionDateForPlan:
                            nextContributionDateForPlan,
                        onAddContributionPlan: onAddContributionPlan,
                        onEditContributionPlan: onEditContributionPlan,
                        onDeleteContributionPlan: onDeleteContributionPlan,
                      ),
                      const SizedBox(height: 20),
                      _TimelineCard(
                        contributions: contributions,
                        onAddContribution: onAddContribution,
                        onEditContribution: onEditContribution,
                        onDeleteContribution: onDeleteContribution,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContributionPlansCard extends StatelessWidget {
  const _ContributionPlansCard({
    required this.plans,
    required this.nextContributionDateForPlan,
    this.onAddContributionPlan,
    this.onEditContributionPlan,
    this.onDeleteContributionPlan,
  });

  final List<GoalContributionPlan> plans;
  final DateTime? Function(GoalContributionPlan plan)
  nextContributionDateForPlan;
  final Future<void> Function()? onAddContributionPlan;
  final Future<void> Function(GoalContributionPlan plan)?
  onEditContributionPlan;
  final Future<void> Function(GoalContributionPlan plan)?
  onDeleteContributionPlan;

  @override
  Widget build(BuildContext context) {
    final activePlans = plans.where((plan) => plan.isActive).toList();
    final monthlyEquivalentTotal = activePlans.fold<double>(
      0,
      (total, plan) => total + plan.monthlyEquivalentAmount,
    );
    final nextContributionDate = activePlans
        .map(nextContributionDateForPlan)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, candidate) =>
              earliest == null || candidate.isBefore(earliest)
              ? candidate
              : earliest,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plany cyklicznych wplat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onAddContributionPlan != null)
                  TextButton.icon(
                    onPressed: onAddContributionPlan,
                    icon: const Icon(Icons.repeat),
                    label: const Text('Dodaj plan'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Plan automatycznie dopisuje kolejne transfery do celu po dacie zaplanowanej wplaty.',
              style: TextStyle(color: _mutedTextColor(context), height: 1.4),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DetailMetric(
                  label: 'Plany aktywne',
                  value: '${activePlans.length}',
                ),
                _DetailMetric(
                  label: 'Tempo miesieczne',
                  value: activePlans.isEmpty
                      ? 'Brak'
                      : _currency(monthlyEquivalentTotal),
                ),
                _DetailMetric(
                  label: 'Nastepna wplata',
                  value: nextContributionDate == null
                      ? 'Brak'
                      : _date(nextContributionDate),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (plans.isEmpty)
              Text(
                'Brak jeszcze planow wplat dla tego celu.',
                style: TextStyle(color: _mutedTextColor(context), height: 1.5),
              )
            else
              Column(
                children: plans
                    .map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ContributionPlanItem(
                          plan: plan,
                          nextContributionDate: nextContributionDateForPlan(
                            plan,
                          ),
                          onEdit: onEditContributionPlan == null
                              ? null
                              : () => onEditContributionPlan!(plan),
                          onDelete: onDeleteContributionPlan == null
                              ? null
                              : () => onDeleteContributionPlan!(plan),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast, required this.deadline});

  final GoalForecastSnapshot forecast;
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final statusLabel = forecast.isCompleted
        ? 'Cel zrealizowany'
        : forecast.projectedCompletionDate == null
        ? 'Brak wystarczajacych danych'
        : forecast.isOnTrack
        ? 'Tempo wystarczy na czas'
        : 'Obecne tempo nie domknie celu na czas';
    final statusColor = forecast.isCompleted
        ? _successColor(context)
        : forecast.projectedCompletionDate == null
        ? _mutedTextColor(context)
        : forecast.isOnTrack
        ? _successColor(context)
        : _dangerColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prognoza dojscia do celu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _forecastSummary(forecast, deadline),
              style: TextStyle(color: _mutedTextColor(context), height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DetailMetric(
                  label: 'Tempo miesieczne',
                  value: forecast.hasHistory
                      ? _currency(forecast.averageMonthlyContribution)
                      : 'Brak',
                ),
                _DetailMetric(
                  label: 'Wymagane tempo',
                  value: forecast.requiredMonthlyContribution <= 0
                      ? '0,00 zl'
                      : _currency(forecast.requiredMonthlyContribution),
                ),
                _DetailMetric(
                  label: 'Szacowany finisz',
                  value: forecast.projectedCompletionDate == null
                      ? 'Brak'
                      : _monthYear(forecast.projectedCompletionDate!),
                ),
                _DetailMetric(
                  label: 'Miesiace do celu',
                  value: forecast.projectedMonthsToGoal?.toString() ?? 'Brak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionPlanItem extends StatelessWidget {
  const _ContributionPlanItem({
    required this.plan,
    required this.nextContributionDate,
    this.onEdit,
    this.onDelete,
  });

  final GoalContributionPlan plan;
  final DateTime? nextContributionDate;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = plan.isActive
        ? _successColor(context)
        : _mutedTextColor(context);
    final statusLabel = plan.isActive ? 'Aktywny' : 'Wstrzymany';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currency(plan.amount)} | ${_intervalLabel(plan.interval)} | dzien ${plan.dayOfMonth}',
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$statusLabel | start ${_date(plan.startDate)} | nastepna ${nextContributionDate == null ? 'Brak' : _date(nextContributionDate!)}',
                  style: TextStyle(color: statusColor),
                ),
                if (plan.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      plan.note!,
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    onPressed: () => onEdit!.call(),
                    tooltip: 'Edytuj plan',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (onDelete != null)
                  IconButton(
                    onPressed: () => onDelete!.call(),
                    tooltip: 'Usun plan',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.goal,
    required this.startingAmount,
    required this.contributionTotal,
    required this.averageContribution,
    required this.remaining,
    required this.contributionCount,
    required this.latestContribution,
  });

  final SavingsGoal goal;
  final double startingAmount;
  final double contributionTotal;
  final double averageContribution;
  final double remaining;
  final int contributionCount;
  final FinanceTransaction? latestContribution;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        goal.deadline.isBefore(DateTime.now()) && goal.progress < 1;
    final progressColor = isOverdue
        ? _dangerColor(context)
        : goal.progress >= 0.75
        ? _successColor(context)
        : _infoColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Postep celu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currency(goal.savedAmount)} z ${_currency(goal.targetAmount)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Pozostalo ${_currency(remaining)} | termin ${_date(goal.deadline)}',
              style: TextStyle(color: _mutedTextColor(context)),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 12,
              backgroundColor: _softSurfaceMutedColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DetailMetric(
                  label: 'Stan poczatkowy',
                  value: _currency(startingAmount),
                ),
                _DetailMetric(
                  label: 'Suma wplat',
                  value: _currency(contributionTotal),
                ),
                _DetailMetric(
                  label: 'Srednia wplata',
                  value: contributionCount == 0
                      ? 'Brak'
                      : _currency(averageContribution),
                ),
                _DetailMetric(
                  label: 'Liczba wplat',
                  value: '$contributionCount',
                ),
                _DetailMetric(
                  label: 'Ostatnia wplata',
                  value: latestContribution == null
                      ? 'Brak'
                      : _date(latestContribution!.date),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.contributions,
    this.onAddContribution,
    this.onEditContribution,
    this.onDeleteContribution,
  });

  final List<FinanceTransaction> contributions;
  final Future<void> Function()? onAddContribution;
  final Future<void> Function(FinanceTransaction transaction)?
  onEditContribution;
  final Future<void> Function(FinanceTransaction transaction)?
  onDeleteContribution;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pelna os czasu wplat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onAddContribution != null)
                  TextButton.icon(
                    onPressed: onAddContribution,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj wplate'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Historia wszystkich transferow podpietych do tego celu.',
              style: TextStyle(color: _mutedTextColor(context), height: 1.4),
            ),
            const SizedBox(height: 20),
            if (contributions.isEmpty)
              Text(
                'Brak jeszcze wplat dla tego celu.',
                style: TextStyle(color: _mutedTextColor(context), height: 1.5),
              )
            else
              Column(
                children: contributions
                    .map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TimelineItem(
                          transaction: transaction,
                          onEdit: onEditContribution == null
                              ? null
                              : () => onEditContribution!(transaction),
                          onDelete: onDeleteContribution == null
                              ? null
                              : () => onDeleteContribution!(transaction),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.transaction, this.onEdit, this.onDelete});

  final FinanceTransaction transaction;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _successColor(context),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _date(transaction.date),
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
                if (transaction.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.note!,
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${_currency(transaction.amount)}',
                style: TextStyle(
                  color: _successColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: () => onEdit!.call(),
                        tooltip: 'Edytuj wplate',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: () => onDelete!.call(),
                        tooltip: 'Usun wplate',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _mutedTextColor(context))),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

String _currency(double amount) {
  return formatDisplayCurrency(amount);
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _monthYear(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '$month.${date.year}';
}

String _intervalLabel(GoalContributionInterval interval) {
  return switch (interval) {
    GoalContributionInterval.monthly => 'Co miesiac',
    GoalContributionInterval.quarterly => 'Co kwartal',
    GoalContributionInterval.yearly => 'Co rok',
  };
}

Color _mutedTextColor(BuildContext context) {
  final baseColor = Theme.of(context).textTheme.bodyMedium?.color;
  return (baseColor ?? const Color(0xFF5B6470)).withValues(alpha: 0.72);
}

Color _softSurfaceColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHigh
      : const Color(0xFFF8F7F3);
}

Color _softSurfaceMutedColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHighest
      : const Color(0xFFE7E1D6);
}

Color _successColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF66D6A5)
      : const Color(0xFF166534);
}

Color _dangerColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFFF19791)
      : const Color(0xFFB91C1C);
}

Color _infoColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF8FBEF5)
      : const Color(0xFF1D4ED8);
}

String _forecastSummary(GoalForecastSnapshot forecast, DateTime deadline) {
  if (forecast.isCompleted) {
    return 'Cel jest juz domkniety. Kolejne wplaty zwieksza tylko nadwyzke ponad target.';
  }

  if (!forecast.hasHistory) {
    return 'Brak historii wplat. Aby zamknac cel do ${_monthYear(deadline)}, potrzebujesz srednio ${_currency(forecast.requiredMonthlyContribution)} miesiecznie.';
  }

  if (forecast.projectedCompletionDate == null) {
    return 'Historia wplat jest jeszcze zbyt mala, aby wyliczyc sensowny termin zamkniecia celu.';
  }

  if (forecast.isOnTrack) {
    return 'Przy obecnym tempie ${_currency(forecast.averageMonthlyContribution)} miesiecznie cel powinien zamknac sie okolo ${_monthYear(forecast.projectedCompletionDate!)}.';
  }

  return 'Przy obecnym tempie ${_currency(forecast.averageMonthlyContribution)} miesiecznie cel domknie sie dopiero okolo ${_monthYear(forecast.projectedCompletionDate!)}, wiec do terminu ${_monthYear(deadline)} potrzeba srednio ${_currency(forecast.requiredMonthlyContribution)} miesiecznie.';
}
