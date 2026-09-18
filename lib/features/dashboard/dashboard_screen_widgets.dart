part of 'dashboard_screen.dart';

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.startingAmount,
    required this.contributionTransactions,
    required this.contributionPlans,
    required this.nextContributionDate,
    required this.monthlyContributionPlanTotal,
    required this.onViewDetails,
    required this.onAddContribution,
    required this.onManageContributionPlans,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final double startingAmount;
  final List<FinanceTransaction> contributionTransactions;
  final List<GoalContributionPlan> contributionPlans;
  final DateTime? nextContributionDate;
  final double monthlyContributionPlanTotal;
  final VoidCallback onViewDetails;
  final VoidCallback onAddContribution;
  final VoidCallback onManageContributionPlans;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = _mutedTextColor(context);
    final contributionTotal = contributionTransactions.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final remaining =
        (goal.targetAmount - goal.savedAmount).clamp(0, double.infinity)
            as double;
    final isOverdue =
        goal.deadline.isBefore(DateTime.now()) && goal.progress < 1;
    final progressColor = isOverdue
        ? _dangerColor(context)
        : goal.progress >= 0.75
        ? _successColor(context)
        : _infoColor(context);
    final activePlanCount = contributionPlans
        .where((plan) => plan.isActive)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usun')),
                ],
              ),
            ],
          ),
          Text(
            '${_currency(goal.savedAmount)} / ${_currency(goal.targetAmount)}',
            style: TextStyle(color: mutedTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Stan poczatkowy ${_currency(startingAmount)} | wplaty ${_currency(contributionTotal)}',
            style: TextStyle(color: mutedTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Pozostalo ${_currency(remaining)} | termin ${_date(goal.deadline)}',
            style: TextStyle(color: mutedTextColor),
          ),
          const SizedBox(height: 4),
          Text(
            activePlanCount == 0
                ? 'Brak aktywnego planu wplat.'
                : 'Plany $activePlanCount | tempo ${_currency(monthlyContributionPlanTotal)} / mies. | nastepna ${nextContributionDate == null ? 'Brak' : _date(nextContributionDate!)}',
            style: TextStyle(color: mutedTextColor),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: goal.progress,
            minHeight: 10,
            backgroundColor: _softSurfaceMutedColor(context),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.timeline),
                label: const Text('Szczegoly'),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddContribution,
                icon: const Icon(Icons.savings),
                label: const Text('Dodaj wplate'),
              ),
              OutlinedButton.icon(
                onPressed: onManageContributionPlans,
                icon: const Icon(Icons.repeat),
                label: const Text('Plan wplat'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (contributionTransactions.isEmpty)
            Text(
              'Brak jeszcze wplat powiazanych z tym celem.',
              style: TextStyle(color: mutedTextColor, height: 1.5),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ostatnie wplaty (${contributionTransactions.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _successColor(context),
                  ),
                ),
                const SizedBox(height: 10),
                ...contributionTransactions
                    .take(3)
                    .map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _date(transaction.date),
                                    style: TextStyle(color: mutedTextColor),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${_currency(transaction.amount)}',
                              style: TextStyle(
                                color: _successColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({
    required this.investment,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final InvestmentHolding investment;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = _mutedTextColor(context);
    final hasReliableMarketQuote = investment.lastPriceDate != null;
    final displayedValue =
        hasReliableMarketQuote || !investment.supportsMarketData
        ? investment.currentValue
        : investment.investedValue;
    final valueChange = displayedValue - investment.investedValue;
    final hasChangePercent =
        investment.investedValue > 0 &&
        (hasReliableMarketQuote || !investment.supportsMarketData);
    final changePercent = hasChangePercent
        ? valueChange / investment.investedValue
        : null;
    final changeColor = valueChange >= 0
        ? _successColor(context)
        : _dangerColor(context);
    final valueLabel = hasReliableMarketQuote
        ? 'Wartosc rynkowa'
        : investment.supportsMarketData
        ? 'Kapital wg zakupu'
        : 'Wartosc';

    return Material(
      color: _softSurfaceColor(context),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.displaySymbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          investment.name,
                          style: TextStyle(color: mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                      PopupMenuItem(value: 'delete', child: Text('Usun')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InvestmentMetricRow(
                label: 'Jednostki',
                value: _number(investment.units),
              ),
              _InvestmentMetricRow(
                label: 'Cena zakupu',
                value: '${_currency(investment.buyPrice)} / jedn.',
              ),
              _InvestmentMetricRow(
                label: valueLabel,
                value: _currency(displayedValue),
                valueStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              _InvestmentMetricRow(
                label: 'Zmiana',
                value: changePercent == null
                    ? 'Brak kursu'
                    : '${_signedCurrency(valueChange)} | ${_signedPercent(changePercent)}',
                valueStyle: TextStyle(
                  color: changePercent == null ? mutedTextColor : changeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (investment.lastPriceDate != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Cena z ${_date(investment.lastPriceDate!)}',
                  style: TextStyle(color: mutedTextColor),
                ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.timeline),
                label: const Text('Szczegoly'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestmentMetricRow extends StatelessWidget {
  const _InvestmentMetricRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = _mutedTextColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: mutedTextColor)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentGroupHeader extends StatelessWidget {
  const _InvestmentGroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: _mutedTextColor(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _softSurfaceColor(context),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsStatChip extends StatelessWidget {
  const _AnalyticsStatChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(color: _mutedTextColor(context))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _mutedTextColor(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[action!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TrendMonthsToggleGroup extends StatelessWidget {
  const _TrendMonthsToggleGroup({
    required this.selectedMonths,
    required this.onMonthsChanged,
  });

  final int selectedMonths;
  final ValueChanged<int> onMonthsChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 3, label: Text('3M')),
        ButtonSegment(value: 6, label: Text('6M')),
        ButtonSegment(value: 12, label: Text('12M')),
      ],
      selected: {selectedMonths},
      onSelectionChanged: (selection) {
        onMonthsChanged(selection.first);
      },
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({required this.points, required this.hasData});

  final List<MonthlyCashflowPoint> points;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return Text(
        'Brak danych transakcyjnych do wygenerowania trendu.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    final maxValue = points.fold<double>(
      1,
      (currentMax, point) => math.max(
        currentMax,
        math.max(point.income, math.max(point.expenses, point.transfers)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final singlePoint = points.length == 1;
        final compactLayout =
            singlePoint || points.length >= 10 || constraints.maxWidth < 720;
        final pointWidth = singlePoint
            ? math.min(constraints.maxWidth, 176.0)
            : compactLayout
            ? 44.0
            : 72.0;
        final chartWidth = singlePoint
            ? pointWidth
            : math.max(constraints.maxWidth, points.length * pointWidth);
        final chartHeight = singlePoint ? 176.0 : 220.0;
        final horizontalPadding = singlePoint
            ? 2.0
            : compactLayout
            ? 3.0
            : 6.0;
        final barSpacing = singlePoint
            ? 4.0
            : compactLayout
            ? 4.0
            : 6.0;
        final labelFontSize = singlePoint
            ? 11.0
            : compactLayout
            ? 11.0
            : 12.0;

        final chart = SizedBox(
          width: chartWidth,
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points
                .map(
                  (point) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _ChartBar(
                                    value: point.income,
                                    maxValue: maxValue,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                                SizedBox(width: barSpacing),
                                Expanded(
                                  child: _ChartBar(
                                    value: point.expenses,
                                    maxValue: maxValue,
                                    color: const Color(0xFFB91C1C),
                                  ),
                                ),
                                SizedBox(width: barSpacing),
                                Expanded(
                                  child: _ChartBar(
                                    value: point.transfers,
                                    maxValue: maxValue,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            point.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _signedCurrency(point.net),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              color: point.net >= 0
                                  ? _successColor(context)
                                  : _dangerColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ChartLegend(label: 'Przychody', color: _successColor(context)),
                _ChartLegend(label: 'Wydatki', color: _dangerColor(context)),
                _ChartLegend(label: 'Transfery', color: _warningColor(context)),
              ],
            ),
            const SizedBox(height: 16),
            chartWidth > constraints.maxWidth + 1
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: chart,
                  )
                : singlePoint
                ? Align(alignment: Alignment.center, child: chart)
                : chart,
          ],
        );
      },
    );
  }
}

class TransactionExpenseTrendPoint {
  const TransactionExpenseTrendPoint({
    required this.day,
    required this.axisLabel,
    required this.expenseTotal,
  });

  final DateTime day;
  final String axisLabel;
  final double expenseTotal;
}

class _TransactionExpenseTrendChart extends StatelessWidget {
  const _TransactionExpenseTrendChart({required this.points});

  final List<TransactionExpenseTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text(
        'Brak dziennych wydatkow do narysowania trendu.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    final maxValue = points.fold<double>(
      1,
      (currentMax, point) => math.max(currentMax, point.expenseTotal),
    );
    final scaleMax = _portfolioTrendScaleMax(maxValue);
    const yAxisTickCount = 4;
    final yAxisValues = List<double>.generate(
      yAxisTickCount,
      (index) => scaleMax * (1 - (index / (yAxisTickCount - 1))),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const yAxisWidth = 86.0;
        const chartHeight = 236.0;
        const plotTop = 14.0;
        const plotBottom = 56.0;
        const plotHorizontalPadding = 20.0;
        final plotHeight = chartHeight - plotTop - plotBottom;
        final pointSpacing = switch (points.length) {
          <= 10 => 54.0,
          <= 21 => 40.0,
          _ => 32.0,
        };
        final barWidth = switch (points.length) {
          <= 10 => 18.0,
          <= 21 => 14.0,
          _ => 10.0,
        };
        final availableChartWidth = math.max(
          0.0,
          constraints.maxWidth - yAxisWidth - 8,
        );
        final chartWidth = math.max(
          availableChartWidth,
          plotHorizontalPadding * 2 +
              math.max(0, points.length - 1) * pointSpacing,
        );
        final step = points.length <= 1
            ? 0.0
            : (chartWidth - plotHorizontalPadding * 2) / (points.length - 1);
        double xForIndex(int index) => points.length <= 1
            ? chartWidth / 2
            : plotHorizontalPadding + (step * index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChartLegend(
              label: 'Dzienne wydatki',
              color: _dangerColor(context),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: yAxisWidth,
                  height: chartHeight,
                  child: Stack(
                    children: [
                      for (var index = 0; index < yAxisValues.length; index++)
                        Positioned(
                          right: 10,
                          top:
                              plotTop +
                              (plotHeight *
                                  (index / (yAxisValues.length - 1))) -
                              10,
                          child: Text(
                            _axisCurrency(yAxisValues[index]),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _mutedTextColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      height: chartHeight,
                      child: Stack(
                        children: [
                          for (var i = 0; i < yAxisTickCount; i++)
                            Positioned(
                              left: plotHorizontalPadding,
                              right: plotHorizontalPadding,
                              top:
                                  plotTop +
                                  (plotHeight * (i / (yAxisTickCount - 1))),
                              child: Container(
                                height: 1,
                                color: _softSurfaceMutedColor(context),
                              ),
                            ),
                          Positioned(
                            left: plotHorizontalPadding,
                            top: plotTop,
                            bottom: plotBottom,
                            child: Container(
                              width: 1,
                              color: _softSurfaceMutedColor(context),
                            ),
                          ),
                          Positioned(
                            left: plotHorizontalPadding,
                            right: plotHorizontalPadding,
                            top: plotTop + plotHeight,
                            child: Container(
                              height: 1,
                              color: _softSurfaceMutedColor(context),
                            ),
                          ),
                          for (
                            var index = 0;
                            index < points.length;
                            index++
                          ) ...[
                            if (points[index].expenseTotal > 0)
                              Positioned(
                                left: xForIndex(index) - (barWidth / 2),
                                top:
                                    plotTop +
                                    plotHeight -
                                    math.max(
                                      4.0,
                                      plotHeight *
                                          (points[index].expenseTotal /
                                              scaleMax),
                                    ),
                                child: Container(
                                  width: barWidth,
                                  height: math.max(
                                    4.0,
                                    plotHeight *
                                        (points[index].expenseTotal / scaleMax),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dangerColor(context),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: xForIndex(index) - 30,
                              top: chartHeight - 42,
                              width: 60,
                              child: Text(
                                points[index].axisLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _mutedTextColor(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class PortfolioValueTrendPoint {
  const PortfolioValueTrendPoint({
    required this.periodStart,
    required this.label,
    required this.axisLabel,
    this.axisSecondaryLabel,
    required this.detailLabel,
    required this.value,
    required this.isCurrent,
  });

  final DateTime periodStart;
  final String label;
  final String axisLabel;
  final String? axisSecondaryLabel;
  final String detailLabel;
  final double? value;
  final bool isCurrent;

  bool get hasValue => value != null;
}

class _PortfolioValueTrendChart extends StatefulWidget {
  const _PortfolioValueTrendChart({required this.points});

  final List<PortfolioValueTrendPoint> points;

  @override
  State<_PortfolioValueTrendChart> createState() =>
      _PortfolioValueTrendChartState();
}

class _PortfolioValueTrendChartState extends State<_PortfolioValueTrendChart> {
  int? _activeIndex;
  static const _currentPointColor = Color(0xFF0F766E);

  void _setActiveIndex(int? value) {
    if (_activeIndex == value) {
      return;
    }

    setState(() {
      _activeIndex = value;
    });
  }

  @override
  void didUpdateWidget(covariant _PortfolioValueTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_activeIndex != null && _activeIndex! >= widget.points.length) {
      _activeIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return Text(
        'Brak historii portfela do narysowania trendu wartosci.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    if (_activeIndex != null && _activeIndex! >= points.length) {
      _activeIndex = null;
    }

    final maxValue = points
        .where((point) => point.hasValue)
        .fold<double>(
          1,
          (currentMax, point) => math.max(currentMax, point.value ?? 0),
        );
    final scaleMax = _portfolioTrendScaleMax(maxValue);
    const yAxisTickCount = 5;
    final yAxisValues = List<double>.generate(
      yAxisTickCount,
      (index) => scaleMax * (1 - (index / (yAxisTickCount - 1))),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const yAxisWidth = 104.0;
        const chartHeight = 264.0;
        const plotTop = 18.0;
        const plotBottom = 72.0;
        const plotHorizontalPadding = 24.0;
        const tooltipWidth = 184.0;
        final plotHeight = chartHeight - plotTop - plotBottom;
        final pointSpacing = switch (points.length) {
          <= 12 => 92.0,
          <= 32 => 64.0,
          <= 90 => 34.0,
          _ => 24.0,
        };
        final availableChartWidth = math.max(
          0.0,
          constraints.maxWidth - yAxisWidth - 8,
        );
        final chartWidth = math.max(
          availableChartWidth,
          plotHorizontalPadding * 2 +
              math.max(0, points.length - 1) * pointSpacing,
        );
        final step = points.length <= 1
            ? 0.0
            : (chartWidth - plotHorizontalPadding * 2) / (points.length - 1);
        double xForIndex(int index) => points.length <= 1
            ? chartWidth / 2
            : plotHorizontalPadding + (step * index);
        double? yForPoint(PortfolioValueTrendPoint point) {
          if (!point.hasValue) {
            return null;
          }
          final ratio = scaleMax <= 0
              ? 0.0
              : (point.value! / scaleMax).clamp(0.0, 1.0);
          return plotTop + (plotHeight * (1 - ratio));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ChartLegend(
                  label: 'Wartosc portfela',
                  color: _infoColor(context),
                ),
                _ChartLegend(label: 'Biezacy punkt', color: _currentPointColor),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: yAxisWidth,
                  height: chartHeight,
                  child: Stack(
                    children: [
                      for (var index = 0; index < yAxisValues.length; index++)
                        Positioned(
                          right: 10,
                          top:
                              plotTop +
                              (plotHeight *
                                  (index / (yAxisValues.length - 1))) -
                              10,
                          child: Text(
                            _axisCurrency(yAxisValues[index]),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _mutedTextColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      height: chartHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PortfolioTrendLinePainter(
                                points: points,
                                scaleMax: scaleMax,
                                infoColor: _infoColor(context),
                                currentColor: _currentPointColor,
                                gridColor: _softSurfaceMutedColor(context),
                                plotTop: plotTop,
                                plotHeight: plotHeight,
                                horizontalPadding: plotHorizontalPadding,
                                yAxisTickCount: yAxisTickCount,
                              ),
                            ),
                          ),
                          if (_activeIndex != null)
                            Builder(
                              builder: (context) {
                                final activePoint = points[_activeIndex!];
                                final activeX = xForIndex(_activeIndex!);
                                final bubbleColor = activePoint.isCurrent
                                    ? _currentPointColor
                                    : _infoColor(context);

                                return Positioned(
                                  left: activeX - 0.5,
                                  top: plotTop,
                                  child: Container(
                                    width: 1,
                                    height: plotHeight,
                                    color: bubbleColor.withValues(alpha: 0.24),
                                  ),
                                );
                              },
                            ),
                          for (
                            var index = 0;
                            index < points.length;
                            index++
                          ) ...[
                            if (points[index].hasValue)
                              Positioned(
                                left: xForIndex(index) - 16,
                                top:
                                    (yForPoint(points[index]) ??
                                        (plotTop + plotHeight)) -
                                    16,
                                child: MouseRegion(
                                  onEnter: (_) => _setActiveIndex(index),
                                  onExit: (_) => _setActiveIndex(null),
                                  child: GestureDetector(
                                    onTap: () {
                                      _setActiveIndex(
                                        _activeIndex == index ? null : index,
                                      );
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      color: Colors.transparent,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: _activeIndex == index ? 18 : 14,
                                        height: _activeIndex == index ? 18 : 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: points[index].isCurrent
                                                ? _currentPointColor
                                                : _infoColor(context),
                                            width: 2.4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: points[index].isCurrent
                                                  ? _currentPointColor
                                                  : _infoColor(context),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: xForIndex(index) - 42,
                              top: chartHeight - 52,
                              width: 84,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _setActiveIndex(
                                    _activeIndex == index ? null : index,
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      points[index].axisLabel,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: points[index].isCurrent
                                            ? _successColor(context)
                                            : _mutedTextColor(context),
                                      ),
                                    ),
                                    if (points[index].axisSecondaryLabel !=
                                        null)
                                      Text(
                                        points[index].axisSecondaryLabel!,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _mutedTextColor(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_activeIndex != null)
                            Builder(
                              builder: (context) {
                                final activePoint = points[_activeIndex!];
                                final activeX = xForIndex(_activeIndex!);
                                final activeY =
                                    yForPoint(activePoint) ??
                                    (plotTop + plotHeight);
                                final bubbleLeft =
                                    (activeX - (tooltipWidth / 2))
                                        .clamp(
                                          8.0,
                                          math.max(
                                            8.0,
                                            chartWidth - tooltipWidth - 8,
                                          ),
                                        )
                                        .toDouble();
                                final bubbleColor = activePoint.isCurrent
                                    ? _currentPointColor
                                    : _infoColor(context);

                                return Positioned(
                                  left: bubbleLeft,
                                  top: math.max(0, activeY - 84),
                                  child: IgnorePointer(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        width: tooltipWidth,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: bubbleColor.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              activePoint.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activePoint.detailLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _mutedTextColor(context),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              activePoint.hasValue
                                                  ? _currency(
                                                      activePoint.value!,
                                                    )
                                                  : 'Brak danych',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: !activePoint.hasValue
                                                    ? _mutedTextColor(context)
                                                    : activePoint.isCurrent
                                                    ? _successColor(context)
                                                    : _infoColor(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PortfolioTrendLinePainter extends CustomPainter {
  const _PortfolioTrendLinePainter({
    required this.points,
    required this.scaleMax,
    required this.infoColor,
    required this.currentColor,
    required this.gridColor,
    required this.plotTop,
    required this.plotHeight,
    required this.horizontalPadding,
    required this.yAxisTickCount,
  });

  final List<PortfolioValueTrendPoint> points;
  final double scaleMax;
  final Color infoColor;
  final Color currentColor;
  final Color gridColor;
  final double plotTop;
  final double plotHeight;
  final double horizontalPadding;
  final int yAxisTickCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || points.where((point) => point.hasValue).isEmpty) {
      return;
    }

    final chartWidth = size.width;
    final step = points.length <= 1
        ? 0.0
        : (chartWidth - horizontalPadding * 2) / (points.length - 1);
    final positions = <Offset?>[
      for (var index = 0; index < points.length; index++)
        points[index].hasValue
            ? Offset(
                points.length <= 1
                    ? chartWidth / 2
                    : horizontalPadding + (step * index),
                plotTop +
                    (plotHeight *
                        (1 -
                            ((scaleMax <= 0
                                    ? 0.0
                                    : ((points[index].value ?? 0) / scaleMax))
                                .clamp(0.0, 1.0)))),
              )
            : null,
    ];

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < yAxisTickCount; i++) {
      final y = plotTop + (plotHeight * (i / (yAxisTickCount - 1)));
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(chartWidth - horizontalPadding, y),
        gridPaint,
      );
    }
    canvas.drawLine(
      Offset(horizontalPadding, plotTop),
      Offset(horizontalPadding, plotTop + plotHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(horizontalPadding, plotTop + plotHeight),
      Offset(chartWidth - horizontalPadding, plotTop + plotHeight),
      gridPaint,
    );

    final linePath = Path();
    var hasStarted = false;
    for (final position in positions) {
      if (position == null) {
        continue;
      }
      if (!hasStarted) {
        linePath.moveTo(position.dx, position.dy);
        hasStarted = true;
      } else {
        linePath.lineTo(position.dx, position.dy);
      }
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: [infoColor, currentColor]).createShader(
        Rect.fromLTWH(
          horizontalPadding,
          plotTop,
          chartWidth - horizontalPadding * 2,
          plotHeight,
        ),
      );
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PortfolioTrendLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.scaleMax != scaleMax ||
        oldDelegate.infoColor != infoColor ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.plotTop != plotTop ||
        oldDelegate.plotHeight != plotHeight ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.yAxisTickCount != yAxisTickCount;
  }
}

double _portfolioTrendScaleMax(double rawMax) {
  if (rawMax <= 0) {
    return 100;
  }

  final exponent = (math.log(rawMax) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  const factors = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 7.5, 10.0];
  for (final factor in factors) {
    final candidate = magnitude * factor;
    if (rawMax <= candidate) {
      return candidate;
    }
  }

  return magnitude * 10;
}

String _axisCurrency(double amount) {
  final normalizedAmount = amount.abs() < 0.000001 ? 0 : amount;
  return '${formatDisplayDecimal(normalizedAmount, fractionDigits: 0)} zl';
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: _mutedTextColor(context))),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: _softSurfaceMutedColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ratio == 0
            ? const SizedBox.shrink()
            : FractionallySizedBox(
                heightFactor: ratio,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ExpenseBreakdownList extends StatelessWidget {
  const _ExpenseBreakdownList({required this.points});

  final List<CategoryExpensePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text(
        'Brak wydatkow w wybranym miesiacu.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        return Column(
          children: points
              .map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (narrow) ...[
                        Text(
                          point.category,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currency(point.amount)} | ${_percent(point.share)}',
                          style: TextStyle(color: _mutedTextColor(context)),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                point.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_currency(point.amount)} | ${_percent(point.share)}',
                              style: TextStyle(color: _mutedTextColor(context)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: point.share,
                        minHeight: 10,
                        backgroundColor: _softSurfaceMutedColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _warningColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PortfolioAllocationList extends StatelessWidget {
  const _PortfolioAllocationList({required this.points});

  final List<PortfolioAllocationPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text(
        'Brak pozycji inwestycyjnych do analizy.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        return Column(
          children: points
              .map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (narrow) ...[
                        Text(
                          '${point.symbol} - ${point.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currency(point.currentValue),
                          style: TextStyle(color: _mutedTextColor(context)),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${point.symbol} - ${point.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _currency(point.currentValue),
                              style: TextStyle(color: _mutedTextColor(context)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Udzial ${_percent(point.share)} | wynik ${_signedCurrency(point.profit)}',
                        style: TextStyle(
                          color: point.profit >= 0
                              ? _successColor(context)
                              : _dangerColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: point.share,
                        minHeight: 10,
                        backgroundColor: _softSurfaceMutedColor(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _infoColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.accent);

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 32),
            Text(title, style: TextStyle(color: _mutedTextColor(context))),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: _mutedTextColor(context))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle = '',
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final titleWidth = math.min(constraints.maxWidth, 420.0);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: titleWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: compact ? 22 : 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: _mutedTextColor(context),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ..._optionalWidget(action),
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InlineModuleCard extends StatelessWidget {
  const _InlineModuleCard({
    required this.title,
    required this.child,
    this.subtitle = '',
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _mutedTextColor(context),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ..._optionalWidget(action),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width, this.radius = 16});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _softSurfaceMutedColor(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SimpleListSectionSkeleton extends StatelessWidget {
  const _SimpleListSectionSkeleton({
    this.itemCount = 3,
    this.showHeaderChips = false,
    this.showIntroLines = false,
  });

  final int itemCount;
  final bool showHeaderChips;
  final bool showIntroLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIntroLines) ...[
          const _SkeletonBlock(height: 18, width: 220, radius: 12),
          const SizedBox(height: 8),
          const _SkeletonBlock(height: 16, width: 160, radius: 12),
          const SizedBox(height: 18),
        ],
        if (showHeaderChips) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(
              3,
              (_) => const _SkeletonBlock(height: 40, width: 110, radius: 18),
            ),
          ),
          const SizedBox(height: 18),
        ],
        ...List<Widget>.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
            child: const _SectionListItemSkeleton(),
          ),
        ),
      ],
    );
  }
}

class _SectionListItemSkeleton extends StatelessWidget {
  const _SectionListItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBlock(height: 18, width: 180, radius: 12),
          SizedBox(height: 10),
          _SkeletonBlock(height: 14, width: 140, radius: 12),
          SizedBox(height: 12),
          _SkeletonBlock(height: 10, radius: 999),
        ],
      ),
    );
  }
}

class _TransactionSectionSkeleton extends StatelessWidget {
  const _TransactionSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionListItemSkeleton(),
        SizedBox(height: 12),
        _SectionListItemSkeleton(),
        SizedBox(height: 12),
        _SectionListItemSkeleton(),
      ],
    );
  }
}

class _ProfileSectionSkeleton extends StatelessWidget {
  const _ProfileSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBlock(height: 24, width: 180, radius: 12),
        const SizedBox(height: 8),
        const _SkeletonBlock(height: 16, width: 220, radius: 12),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(
            4,
            (_) => const _SkeletonBlock(height: 58, width: 132, radius: 18),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SkeletonBlock(height: 42, width: 140, radius: 16),
            _SkeletonBlock(height: 42, width: 140, radius: 16),
          ],
        ),
      ],
    );
  }
}

class _ReportsSectionSkeleton extends StatelessWidget {
  const _ReportsSectionSkeleton({this.showPreview = true});

  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPreview) ...[
          const _SectionListItemSkeleton(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SkeletonBlock(height: 42, width: 150, radius: 16),
              _SkeletonBlock(height: 42, width: 150, radius: 16),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const _SectionListItemSkeleton(),
        const SizedBox(height: 12),
        const _SectionListItemSkeleton(),
      ],
    );
  }
}

class _MonthlyReportPreviewTile extends StatelessWidget {
  const _MonthlyReportPreviewTile({
    required this.periodStart,
    required this.report,
    required this.savedReport,
  });

  final DateTime periodStart;
  final MonthlyReport report;
  final MonthlyReport? savedReport;

  @override
  Widget build(BuildContext context) {
    final accent = savedReport == null
        ? _infoColor(context)
        : savedReport!.isClosed
        ? _warningColor(context)
        : _successColor(context);
    final statusLabel = savedReport == null
        ? 'Brak zapisu'
        : savedReport!.isClosed
        ? 'Miesiac zamkniety'
        : 'Szkic zapisany';
    final statusMessage = savedReport == null
        ? 'Ten miesiac nie ma jeszcze zapisanego raportu.'
        : savedReport!.isClosed
        ? 'Zamknieto ${_dateTime(savedReport!.closedAt ?? savedReport!.generatedAt)}. To jest finalna wersja raportu za ten miesiac.'
        : 'Ostatni zapis szkicu ${_dateTime(savedReport!.generatedAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Szkic raportu ${_periodLabel(periodStart)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusMessage,
            style: TextStyle(color: accent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailChip(
                label: 'Saldo',
                value: _signedCurrency(report.netCashflow),
              ),
              _DetailChip(
                label: 'Transakcje',
                value: '${report.transactionCount}',
              ),
              _DetailChip(
                label: 'Budzety',
                value:
                    '${report.overspentBudgetCount}/${report.budgetCount} przekr.',
              ),
              _DetailChip(
                label: 'Top wydatek',
                value: report.topExpenseCategory ?? 'Brak danych',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyReportComparisonTile extends StatelessWidget {
  const _MonthlyReportComparisonTile({required this.comparison});

  final MonthlyReportComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Porownanie do ${_periodLabel(comparison.previous.periodStart)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Zmiana wzgledem poprzedniego miesiaca dla wybranego okresu.',
            style: TextStyle(color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailChip(
                label: 'Saldo',
                value: _signedCurrency(comparison.netCashflowDelta),
              ),
              _DetailChip(
                label: 'Przychody',
                value: _signedCurrency(comparison.incomeDelta),
              ),
              _DetailChip(
                label: 'Wydatki',
                value: _signedCurrency(comparison.expenseDelta),
              ),
              _DetailChip(
                label: 'Transfery',
                value: _signedCurrency(comparison.transferDelta),
              ),
              _DetailChip(
                label: 'Transakcje',
                value: _signedInt(comparison.transactionCountDelta),
              ),
              _DetailChip(
                label: 'Wynik portfela',
                value: _signedCurrency(comparison.investmentProfitDelta),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyReportTile extends StatelessWidget {
  const _MonthlyReportTile({
    required this.report,
    required this.isSelectedPeriod,
    required this.onDelete,
  });

  final MonthlyReport report;
  final bool isSelectedPeriod;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = report.netCashflow >= 0
        ? _successColor(context)
        : _dangerColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Raport ${_periodLabel(report.periodStart)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (isSelectedPeriod)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _successColor(context).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Biezacy okres',
                          style: TextStyle(
                            color: _successColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (report.isClosed
                                    ? _warningColor(context)
                                    : _infoColor(context))
                                .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        report.isClosed ? 'Zamkniety' : 'Otwarty',
                        style: TextStyle(
                          color: report.isClosed
                              ? _warningColor(context)
                              : _infoColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Usun')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.isClosed
                ? 'Zamknieto ${_dateTime(report.closedAt ?? report.generatedAt)}'
                : 'Wygenerowano ${_dateTime(report.generatedAt)}',
            style: TextStyle(color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailChip(
                label: 'Saldo',
                value: _signedCurrency(report.netCashflow),
              ),
              _DetailChip(
                label: 'Transfery',
                value:
                    '${_currency(report.transferTotal)} | ${_percent(report.transferRate)}',
              ),
              _DetailChip(
                label: 'Budzety',
                value:
                    '${report.overspentBudgetCount}/${report.budgetCount} przekr.',
              ),
              _DetailChip(
                label: 'Portfel',
                value: _currency(report.investmentValue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                'Przychody ${_currency(report.incomeTotal)}',
                style: TextStyle(color: _successColor(context)),
              ),
              Text(
                'Wydatki ${_currency(report.expenseTotal)}',
                style: TextStyle(color: _dangerColor(context)),
              ),
              Text(
                'Wynik portfela ${_signedCurrency(report.investmentProfit)}',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
              Text(
                'Top kategoria ${report.topExpenseCategory ?? 'Brak danych'}',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final DashboardAlertItem alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      DashboardAlertSeverity.critical => _dangerColor(context),
      DashboardAlertSeverity.warning => _warningColor(context),
      DashboardAlertSeverity.info => _infoColor(context),
    };
    final background = switch (alert.severity) {
      DashboardAlertSeverity.critical => color.withValues(alpha: 0.14),
      DashboardAlertSeverity.warning => color.withValues(alpha: 0.14),
      DashboardAlertSeverity.info => color.withValues(alpha: 0.14),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.message,
            style: TextStyle(color: _mutedTextColor(context), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InvestmentAnalyticsPanel extends StatelessWidget {
  const _InvestmentAnalyticsPanel({required this.analytics});

  final InvestmentAnalyticsSnapshot analytics;

  @override
  Widget build(BuildContext context) {
    if (!analytics.hasData) {
      return Text(
        'Brak danych portfela do poglobionej analizy.',
        style: TextStyle(color: _mutedTextColor(context), height: 1.5),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DetailChip(
                  label: 'Zwrot wazony',
                  value: _percent(analytics.weightedReturnRate),
                ),
                _DetailChip(
                  label: 'Najwieksza pozycja',
                  value: _percent(analytics.largestHoldingShare),
                ),
                _DetailChip(
                  label: 'Pozycji',
                  value: '${analytics.holdingCount}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (analytics.bestHolding != null)
              Text(
                'Najmocniejsza pozycja ${analytics.bestHolding!.symbol} ${_percent(analytics.bestHolding!.returnRate)}',
                style: TextStyle(
                  color: _successColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (analytics.worstHolding != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Najslabsza pozycja ${analytics.worstHolding!.symbol} ${_percent(analytics.worstHolding!.returnRate)}',
                  style: TextStyle(
                    color: _dangerColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ...analytics.holdings
                .take(4)
                .map(
                  (holding) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: narrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${holding.symbol} - ${holding.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_currency(holding.currentValue)} | ${_percent(holding.returnRate)}',
                                style: TextStyle(
                                  color: holding.returnRate >= 0
                                      ? _successColor(context)
                                      : _dangerColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${holding.symbol} - ${holding.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${_currency(holding.currentValue)} | ${_percent(holding.returnRate)}',
                                style: TextStyle(
                                  color: holding.returnRate >= 0
                                      ? _successColor(context)
                                      : _dangerColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ReportArchiveTile extends StatelessWidget {
  const _ReportArchiveTile({
    required this.archive,
    required this.onOpen,
    required this.onDelete,
  });

  final ReportArchiveEntry archive;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = archive.format == ReportArchiveFormat.pdf
        ? _dangerColor(context)
        : _infoColor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _softSurfaceColor(context),
            borderRadius: BorderRadius.circular(22),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _archiveInfo(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.download),
                          label: const Text('Pobierz'),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          tooltip: 'Usun archiwum',
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _archiveInfo(context)),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.download),
                      label: const Text('Pobierz'),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Usun')),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _archiveInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          archive.filename,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '${archive.format.name.toUpperCase()} | ${_periodLabel(archive.periodStart)} | ${_fileSize(archive.sizeBytes)}',
          style: TextStyle(color: _mutedTextColor(context)),
        ),
        const SizedBox(height: 4),
        Text(
          'Wgrano ${_dateTime(archive.uploadedAt)}',
          style: TextStyle(color: _mutedTextColor(context)),
        ),
      ],
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionPlan subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = _mutedTextColor(context);
    final isSoon =
        subscription.nextBillingDate.difference(DateTime.now()).inDays <= 7;
    final accent = !subscription.isActive
        ? const Color(0xFF64748B)
        : isSoon
        ? _warningColor(context)
        : _successColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subscription.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usun')),
                ],
              ),
            ],
          ),
          Text(
            _subscriptionCycle(subscription.billingCycle),
            style: TextStyle(color: mutedTextColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Text(
                _currency(subscription.amount),
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
              Text(
                'Kolejne obciazenie ${_date(subscription.nextBillingDate)}',
                style: TextStyle(color: mutedTextColor),
              ),
              Text(
                'Miesiecznie ~ ${_currency(subscription.monthlyCost)}',
                style: TextStyle(color: mutedTextColor),
              ),
              Text(
                subscription.isActive ? 'Aktywna' : 'Wstrzymana',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (subscription.note?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                subscription.note!,
                style: TextStyle(color: mutedTextColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    this.goalName,
    required this.onEdit,
    required this.onDelete,
  });

  final FinanceTransaction transaction;
  final String? goalName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? _successColor(context)
        : isTransfer
        ? _warningColor(context)
        : _dangerColor(context);
    final amountPrefix = isIncome
        ? '+'
        : isTransfer
        ? '->'
        : '-';
    final typeLabel = isTransfer ? 'Transfer' : transaction.category;
    final mutedTextColor = _mutedTextColor(context);
    final isRecurringIncome = transaction.recurringIncomeId != null;
    final isGoalContributionPlan = transaction.goalContributionPlanId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
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
                  '$typeLabel - ${_date(transaction.date)}',
                  style: TextStyle(color: mutedTextColor),
                ),
                if (isRecurringIncome)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Staly dochod',
                      style: TextStyle(
                        color: _infoColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (goalName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Cel: $goalName',
                      style: TextStyle(
                        color: _successColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isGoalContributionPlan)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Auto plan celu',
                      style: TextStyle(
                        color: _infoColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (transaction.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.note!,
                      style: TextStyle(color: mutedTextColor),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$amountPrefix${_currency(transaction.amount)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edytuj')),
              PopupMenuItem(value: 'delete', child: Text('Usun')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionDayHeader extends StatelessWidget {
  const _TransactionDayHeader({
    required this.day,
    required this.count,
    required this.netImpact,
  });

  final DateTime day;
  final int count;
  final double netImpact;

  @override
  Widget build(BuildContext context) {
    final accent = netImpact >= 0
        ? _successColor(context)
        : _dangerColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _softSurfaceMutedColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _date(day),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'ruch' : 'ruchy'}',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ],
          ),
          Text(
            'Bilans dnia ${_signedCurrency(netImpact)}',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RecurringIncomeTile extends StatelessWidget {
  const _RecurringIncomeTile({
    required this.plan,
    required this.nextPayoutDate,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringIncomePlan plan;
  final DateTime? nextPayoutDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = plan.isActive
        ? _successColor(context)
        : _mutedTextColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceMutedColor(context),
        borderRadius: BorderRadius.circular(22),
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
                  '${plan.category} - co miesiac ${plan.payday}. dnia',
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Text(
                      _currency(plan.amount),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.isActive ? 'Aktywny' : 'Wstrzymany',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      nextPayoutDate == null
                          ? 'Brak kolejnej wyplaty'
                          : 'Nastepna wyplata ${_date(nextPayoutDate!)}',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ],
                ),
                if (plan.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      plan.note!,
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edytuj')),
              PopupMenuItem(value: 'delete', child: Text('Usun')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryBudget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progressColor = budget.progress > 0.85
        ? _dangerColor(context)
        : _successColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budget.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usun')),
                ],
              ),
            ],
          ),
          Text(
            '${_currency(budget.spent)} / ${_currency(budget.limit)}',
            style: TextStyle(color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: budget.progress,
            minHeight: 10,
            backgroundColor: _softSurfaceMutedColor(context),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.canMerge,
    required this.usageSummary,
    required this.onEdit,
    required this.onMerge,
    required this.onDelete,
  });

  final FinanceCategory category;
  final bool canMerge;
  final String usageSummary;
  final VoidCallback onEdit;
  final VoidCallback onMerge;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = switch (category.type) {
      TransactionType.income => _successColor(context),
      TransactionType.transfer => _warningColor(context),
      TransactionType.expense => _infoColor(context),
    };
    final typeLabel = switch (category.type) {
      TransactionType.income => 'Przychod',
      TransactionType.transfer => 'Transfer',
      TransactionType.expense => 'Wydatek',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  typeLabel,
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  usageSummary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _mutedTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'merge') {
                onMerge();
              } else {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
              PopupMenuItem<String>(
                value: 'merge',
                enabled: canMerge,
                child: Text(
                  canMerge ? 'Scal z inna' : 'Scal z inna (brak celu)',
                ),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Usun')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({
    required this.controller,
    required this.searchController,
    required this.availableCategories,
    required this.availableGoals,
  });

  final TransactionsController controller;
  final TextEditingController searchController;
  final List<String> availableCategories;
  final List<SavingsGoal> availableGoals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final fieldWidth = narrow ? constraints.maxWidth : 220.0;
        final rangeFilterSelector = SegmentedButton<TransactionRangeFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: TransactionRangeFilter.currentMonth,
              label: Text('Miesiac'),
            ),
            ButtonSegment(
              value: TransactionRangeFilter.last30Days,
              label: Text('30 dni'),
            ),
            ButtonSegment(
              value: TransactionRangeFilter.all,
              label: Text('Calosc'),
            ),
          ],
          selected: {controller.rangeFilter},
          onSelectionChanged: (selection) {
            controller.setRangeFilter(selection.first);
          },
        );
        final typeFilterSelector = SegmentedButton<TransactionTypeFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: TransactionTypeFilter.all,
              label: Text('Wszystkie'),
            ),
            ButtonSegment(
              value: TransactionTypeFilter.income,
              label: Text('Przychody'),
            ),
            ButtonSegment(
              value: TransactionTypeFilter.expense,
              label: Text('Wydatki'),
            ),
            ButtonSegment(
              value: TransactionTypeFilter.transfer,
              label: Text('Transfery'),
            ),
          ],
          selected: {controller.typeFilter},
          onSelectionChanged: (selection) {
            controller.setTypeFilter(selection.first);
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                labelText: 'Szukaj po nazwie, kategorii albo opisie',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          controller.setSearchQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Zakres',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            if (narrow)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: rangeFilterSelector,
              )
            else
              rangeFilterSelector,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Typ',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            if (narrow)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: typeFilterSelector,
              )
            else
              typeFilterSelector,
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: controller.categoryFilter,
                    decoration: const InputDecoration(labelText: 'Kategoria'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Wszystkie kategorie'),
                      ),
                      ...availableCategories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: controller.setCategoryFilter,
                  ),
                ),
                if (availableGoals.isNotEmpty)
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.goalFilter,
                      decoration: const InputDecoration(labelText: 'Cel'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Wszystkie cele'),
                        ),
                        ...availableGoals.map(
                          (goal) => DropdownMenuItem<String>(
                            value: goal.id,
                            child: Text(goal.name),
                          ),
                        ),
                      ],
                      onChanged: controller.setGoalFilter,
                    ),
                  ),
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<TransactionSortOption>(
                    isExpanded: true,
                    initialValue: controller.sortOption,
                    decoration: const InputDecoration(labelText: 'Sortowanie'),
                    items: const [
                      DropdownMenuItem(
                        value: TransactionSortOption.newest,
                        child: Text('Najnowsze'),
                      ),
                      DropdownMenuItem(
                        value: TransactionSortOption.oldest,
                        child: Text('Najstarsze'),
                      ),
                      DropdownMenuItem(
                        value: TransactionSortOption.highestAmount,
                        child: Text('Kwota malejaco'),
                      ),
                      DropdownMenuItem(
                        value: TransactionSortOption.lowestAmount,
                        child: Text('Kwota rosnaco'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      controller.setSortOption(value);
                    },
                  ),
                ),
                if (controller.hasActiveFilters)
                  TextButton.icon(
                    onPressed: () {
                      searchController.clear();
                      controller.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Wyczysc'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ContentTopBar extends StatelessWidget {
  const _ContentTopBar({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.visual,
    this.onMenuPressed,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final _SectionVisualSpec visual;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = visual.accent;
    final accentSoft = accent.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentSoft, theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.dashboard_customize_outlined),
              tooltip: 'Otworz sekcje',
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: compact ? 170 : 260,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.22
                              : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(visual.icon, size: 16, color: accent),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              visual.eyebrow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.72,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(visual.icon, color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactNavigationBar extends StatelessWidget {
  const _CompactNavigationBar({
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onMorePressed,
  });

  final DashboardSection selectedSection;
  final ValueChanged<DashboardSection> onSectionSelected;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _compactPrimarySections.indexOf(selectedSection);

    return NavigationBar(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 4,
      onDestinationSelected: (index) {
        if (index == 4) {
          onMorePressed();
          return;
        }

        onSectionSelected(_compactPrimarySections[index]);
      },
      destinations: [
        for (final section in _compactPrimarySections)
          NavigationDestination(
            icon: Icon(_sectionIcon(section)),
            selectedIcon: Icon(_sectionIcon(section)),
            label: _sectionNavLabel(section),
          ),
        const NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Wiecej',
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.displayName,
    required this.size,
    required this.borderRadius,
  });

  final String displayName;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? 'U'
        : displayName.trim()[0].toUpperCase();
    final gradientColors = Theme.of(context).brightness == Brightness.dark
        ? const [Color(0xFF12302C), Color(0xFF25665D)]
        : const [Color(0xFF12372A), Color(0xFF1F6E62)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: _AvatarInitial(initial: initial, size: size),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: TextStyle(
        color: Colors.white,
        fontSize: size < 50 ? 18 : 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SettingsTileCard extends StatelessWidget {
  const _SettingsTileCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _mutedTextColor(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AccountWorkspaceNavigationCard extends StatelessWidget {
  const _AccountWorkspaceNavigationCard({
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final _AccountWorkspaceSection selectedSection;
  final ValueChanged<_AccountWorkspaceSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _infoColor(context).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.manage_accounts_outlined,
                color: _infoColor(context),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Panel konta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Pod headerem masz osobny panel do danych konta, dostepu, plikow i wygladu aplikacji.',
              style: TextStyle(color: _mutedTextColor(context), height: 1.45),
            ),
            const SizedBox(height: 18),
            ..._AccountWorkspaceSection.values.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AccountWorkspaceNavTile(
                  section: section,
                  selected: section == selectedSection,
                  onTap: () => onSectionSelected(section),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountWorkspaceNavTile extends StatelessWidget {
  const _AccountWorkspaceNavTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _AccountWorkspaceSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _infoColor(context);
    final background = selected
        ? accent.withValues(alpha: 0.12)
        : _softSurfaceColor(context);
    final borderColor = selected
        ? accent.withValues(alpha: 0.22)
        : Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final textColor = selected ? accent : null;

    return InkWell(
      key: ValueKey('account-workspace-${section.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : _softSurfaceMutedColor(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _accountWorkspaceSectionIcon(section),
                color: selected ? accent : _mutedTextColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _accountWorkspaceSectionLabel(section),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _accountWorkspaceSectionDescription(section),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: selected
                          ? accent.withValues(alpha: 0.92)
                          : _mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CompactSectionsSheet extends StatelessWidget {
  const _CompactSectionsSheet({
    required this.displayName,
    required this.email,
    required this.selectedSection,
    required this.themeMode,
    required this.onSectionSelected,
    required this.onThemeModeChanged,
    this.onSignOut,
  });

  final String displayName;
  final String email;
  final DashboardSection selectedSection;
  final ThemeMode themeMode;
  final ValueChanged<DashboardSection> onSectionSelected;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBottomSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UserAvatar(displayName: displayName, size: 48, borderRadius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _mutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Menu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dolna nawigacja trzyma szybkie moduly. Tu masz pelny dostep do wszystkich funkcji.',
            style: appBottomSheetDescriptionStyle(context),
          ),
          const SizedBox(height: 16),
          _ThemeModeToggleGroup(
            themeMode: themeMode,
            isCollapsed: false,
            onThemeModeChanged: onThemeModeChanged,
          ),
          const SizedBox(height: 18),
          ..._dashboardSectionGroups.expand(
            (group) => [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  group.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              ...group.sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SidebarMenuTile(
                    tileKey: ValueKey('sidebar-section-${section.name}'),
                    icon: _sectionIcon(section),
                    label: _sectionNavLabel(section),
                    isCollapsed: false,
                    selected: selectedSection == section,
                    onTap: () => onSectionSelected(section),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onSignOut!.call();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Wyloguj'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  const _SidebarNavigation({
    required this.displayName,
    required this.email,
    required this.isCollapsed,
    required this.selectedSection,
    required this.themeMode,
    required this.onSectionSelected,
    required this.onThemeModeChanged,
    this.onToggleCollapsed,
    this.onSignOut,
  });

  final String displayName;
  final String email;
  final bool isCollapsed;
  final DashboardSection selectedSection;
  final ThemeMode themeMode;
  final ValueChanged<DashboardSection> onSectionSelected;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onToggleCollapsed;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCollapsed ? 12 : 18),
        child: Column(
          crossAxisAlignment: isCollapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (isCollapsed) ...[
              _UserAvatar(displayName: displayName, size: 52, borderRadius: 18),
              ..._optionalWidget(
                onToggleCollapsed == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          onPressed: onToggleCollapsed,
                          tooltip: isCollapsed ? 'Rozwin menu' : 'Zwin menu',
                          icon: Icon(
                            isCollapsed
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                          ),
                        ),
                      ),
              ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _UserAvatar(
                    displayName: displayName,
                    size: 52,
                    borderRadius: 18,
                  ),
                  ..._optionalWidget(
                    onToggleCollapsed == null
                        ? null
                        : IconButton(
                            onPressed: onToggleCollapsed,
                            tooltip: isCollapsed ? 'Rozwin menu' : 'Zwin menu',
                            icon: Icon(
                              isCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                            ),
                          ),
                  ),
                ],
              ),
            if (!isCollapsed) ...[
              const SizedBox(height: 16),
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ] else
              const SizedBox(height: 12),
            _ThemeModeToggleGroup(
              themeMode: themeMode,
              isCollapsed: isCollapsed,
              onThemeModeChanged: onThemeModeChanged,
            ),
            SizedBox(height: isCollapsed ? 18 : 24),
            if (!isCollapsed) ...[const SizedBox(height: 12)],
            Expanded(
              child: SingleChildScrollView(
                child: isCollapsed
                    ? Column(
                        children: _dashboardSectionGroups
                            .expand(
                              (group) => [
                                ...group.sections.map(
                                  (section) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SidebarMenuTile(
                                      tileKey: ValueKey(
                                        'sidebar-section-${section.name}',
                                      ),
                                      icon: _sectionIcon(section),
                                      label: _sectionNavLabel(section),
                                      isCollapsed: true,
                                      selected: selectedSection == section,
                                      onTap: () => onSectionSelected(section),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            )
                            .toList(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _dashboardSectionGroups
                            .expand(
                              (group) => [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    group.title,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.68),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                ...group.sections.map(
                                  (section) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SidebarMenuTile(
                                      tileKey: ValueKey(
                                        'sidebar-section-${section.name}',
                                      ),
                                      icon: _sectionIcon(section),
                                      label: _sectionNavLabel(section),
                                      isCollapsed: false,
                                      selected: selectedSection == section,
                                      onTap: () => onSectionSelected(section),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            )
                            .toList(),
                      ),
              ),
            ),
            if (onSignOut != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isCollapsed
                    ? IconButton(
                        onPressed: onSignOut,
                        tooltip: 'Wyloguj',
                        icon: const Icon(Icons.logout),
                      )
                    : OutlinedButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Wyloguj'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeModeToggleGroup extends StatelessWidget {
  const _ThemeModeToggleGroup({
    required this.themeMode,
    required this.isCollapsed,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final bool isCollapsed;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Column(
        children: [
          IconButton.filledTonal(
            onPressed: () => onThemeModeChanged(ThemeMode.light),
            tooltip: 'Jasny motyw',
            icon: Icon(
              Icons.light_mode_outlined,
              color: themeMode == ThemeMode.light
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          IconButton.filledTonal(
            onPressed: () => onThemeModeChanged(ThemeMode.dark),
            tooltip: 'Ciemny motyw',
            icon: Icon(
              Icons.dark_mode_outlined,
              color: themeMode == ThemeMode.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ],
      );
    }

    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Jasny'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Ciemny'),
        ),
      ],
      selected: {themeMode},
      onSelectionChanged: (selection) {
        onThemeModeChanged(selection.first);
      },
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    this.tileKey,
    required this.icon,
    required this.label,
    required this.isCollapsed,
    required this.selected,
    required this.onTap,
  });

  final Key? tileKey;
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        child: Material(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: tileKey,
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Icon(icon, color: selected ? colorScheme.primary : null),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: tileKey,
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? colorScheme.primary : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionSurfaceFrame extends StatelessWidget {
  const _SectionSurfaceFrame({required this.visual, required this.child});

  final _SectionVisualSpec visual;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentSoft = visual.secondaryAccent.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentSoft, theme.cardColor.withValues(alpha: 0.96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: visual.accent.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _SectionVisualSpec {
  const _SectionVisualSpec({
    required this.icon,
    required this.eyebrow,
    required this.accent,
    required this.secondaryAccent,
  });

  final IconData icon;
  final String eyebrow;
  final Color accent;
  final Color secondaryAccent;
}

IconData _sectionIcon(DashboardSection section) {
  switch (section) {
    case DashboardSection.overview:
      return Icons.dashboard_outlined;
    case DashboardSection.transactions:
      return Icons.receipt_long_outlined;
    case DashboardSection.budgets:
      return Icons.pie_chart_outline;
    case DashboardSection.goals:
      return Icons.flag_outlined;
    case DashboardSection.investments:
      return Icons.trending_up;
    case DashboardSection.subscriptions:
      return Icons.subscriptions_outlined;
    case DashboardSection.reports:
      return Icons.inventory_2_outlined;
    case DashboardSection.categories:
      return Icons.category_outlined;
    case DashboardSection.account:
      return Icons.manage_accounts_outlined;
  }
}

String _sectionNavLabel(DashboardSection section) {
  switch (section) {
    case DashboardSection.overview:
      return 'Przeglad';
    case DashboardSection.transactions:
      return 'Transakcje';
    case DashboardSection.budgets:
      return 'Budzety';
    case DashboardSection.goals:
      return 'Cele';
    case DashboardSection.investments:
      return 'Inwestycje';
    case DashboardSection.subscriptions:
      return 'Subskrypcje';
    case DashboardSection.reports:
      return 'Raporty';
    case DashboardSection.categories:
      return 'Kategorie';
    case DashboardSection.account:
      return 'Konto';
  }
}

IconData _accountWorkspaceSectionIcon(_AccountWorkspaceSection section) {
  switch (section) {
    case _AccountWorkspaceSection.profile:
      return Icons.badge_outlined;
    case _AccountWorkspaceSection.access:
      return Icons.shield_outlined;
    case _AccountWorkspaceSection.data:
      return Icons.folder_open_outlined;
    case _AccountWorkspaceSection.appearance:
      return Icons.palette_outlined;
  }
}

String _accountWorkspaceSectionLabel(_AccountWorkspaceSection section) {
  switch (section) {
    case _AccountWorkspaceSection.profile:
      return 'Konto';
    case _AccountWorkspaceSection.access:
      return 'Dostep';
    case _AccountWorkspaceSection.data:
      return 'Dane';
    case _AccountWorkspaceSection.appearance:
      return 'Wyglad';
  }
}

String _accountWorkspaceSectionDescription(_AccountWorkspaceSection section) {
  switch (section) {
    case _AccountWorkspaceSection.profile:
      return 'Nick i podstawowe dane.';
    case _AccountWorkspaceSection.access:
      return 'E-mail, haslo i reset.';
    case _AccountWorkspaceSection.data:
      return 'Import i eksport plikow.';
    case _AccountWorkspaceSection.appearance:
      return 'Motyw i biezaca sesja.';
  }
}

_SectionVisualSpec _sectionVisual(DashboardSection section) {
  switch (section) {
    case DashboardSection.overview:
      return const _SectionVisualSpec(
        icon: Icons.dashboard_outlined,
        eyebrow: 'Status dnia',
        accent: Color(0xFF0F766E),
        secondaryAccent: Color(0xFFE8A44C),
      );
    case DashboardSection.transactions:
      return const _SectionVisualSpec(
        icon: Icons.receipt_long_outlined,
        eyebrow: 'Ruch gotowki',
        accent: Color(0xFF1D4ED8),
        secondaryAccent: Color(0xFF60A5FA),
      );
    case DashboardSection.budgets:
      return const _SectionVisualSpec(
        icon: Icons.pie_chart_outline,
        eyebrow: 'Kontrola limitow',
        accent: Color(0xFFB45309),
        secondaryAccent: Color(0xFFF59E0B),
      );
    case DashboardSection.goals:
      return const _SectionVisualSpec(
        icon: Icons.flag_outlined,
        eyebrow: 'Postep oszczedzania',
        accent: Color(0xFF7C3AED),
        secondaryAccent: Color(0xFFC084FC),
      );
    case DashboardSection.investments:
      return const _SectionVisualSpec(
        icon: Icons.trending_up,
        eyebrow: 'Portfel rynku',
        accent: Color(0xFF0891B2),
        secondaryAccent: Color(0xFF67E8F9),
      );
    case DashboardSection.subscriptions:
      return const _SectionVisualSpec(
        icon: Icons.subscriptions_outlined,
        eyebrow: 'Stale obciazenia',
        accent: Color(0xFFBE123C),
        secondaryAccent: Color(0xFFFB7185),
      );
    case DashboardSection.reports:
      return const _SectionVisualSpec(
        icon: Icons.inventory_2_outlined,
        eyebrow: 'Archiwum miesiaca',
        accent: Color(0xFF4F46E5),
        secondaryAccent: Color(0xFFA5B4FC),
      );
    case DashboardSection.categories:
      return const _SectionVisualSpec(
        icon: Icons.category_outlined,
        eyebrow: 'Slownik danych',
        accent: Color(0xFF15803D),
        secondaryAccent: Color(0xFF86EFAC),
      );
    case DashboardSection.account:
      return const _SectionVisualSpec(
        icon: Icons.manage_accounts_outlined,
        eyebrow: 'Tozsamosc i preferencje',
        accent: Color(0xFF0F766E),
        secondaryAccent: Color(0xFFEAB308),
      );
  }
}

enum _SectionStateTone { neutral, success, danger }

class _SectionStateCard extends StatelessWidget {
  const _SectionStateCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tone = _SectionStateTone.neutral,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final _SectionStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tone) {
      _SectionStateTone.neutral => theme.colorScheme.primary,
      _SectionStateTone.success => const Color(0xFF0F766E),
      _SectionStateTone.danger => theme.colorScheme.error,
    };
    final isDark = theme.brightness == Brightness.dark;
    final surface = accent.withValues(alpha: isDark ? 0.18 : 0.08);
    final border = accent.withValues(alpha: isDark ? 0.26 : 0.14);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.76,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestructiveConfirmationDialog extends StatelessWidget {
  const _DestructiveConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.delete_outline, color: error),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _transactionError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do transakcji.';
    }
    return error.message ?? 'Nie udalo sie pobrac danych transakcji.';
  }

  return 'Nie udalo sie pobrac danych transakcji.';
}

String _signedInt(int value) {
  if (value > 0) {
    return '+$value';
  }

  return '$value';
}

String _budgetError(Object? error) {
  if (error is InputValidationException) {
    return error.message;
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do budzetow.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych budzetow.';
  }

  return 'Nie udalo sie pobrac danych budzetow.';
}

String _categoryError(Object? error) {
  if (error is CategoryMutationException) {
    return error.message;
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do kategorii.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych kategorii.';
  }

  return 'Nie udalo sie pobrac danych kategorii.';
}

String _profileError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do profilu uzytkownika.';
    }

    return error.message ?? 'Nie udalo sie pobrac profilu uzytkownika.';
  }

  return 'Nie udalo sie pobrac profilu uzytkownika.';
}

String _goalError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do celow.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych celow.';
  }

  return 'Nie udalo sie pobrac danych celow.';
}

String _goalContributionPlanError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do planow wplat.';
    }

    return error.message ?? 'Nie udalo sie pobrac planow wplat.';
  }

  return 'Nie udalo sie pobrac planow wplat.';
}

String _investmentError(Object? error) {
  if (error is InvestmentQuoteException) {
    return error.message;
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do portfela.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych portfela.';
  }

  return 'Nie udalo sie pobrac danych portfela.';
}

String _monthlyReportError(Object? error) {
  if (error is MonthlyReportMutationException) {
    return error.message;
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do raportow miesiecznych.';
    }

    return error.message ?? 'Nie udalo sie pobrac raportow miesiecznych.';
  }

  return 'Nie udalo sie pobrac raportow miesiecznych.';
}

String _reportArchiveError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do archiwow raportow.';
    }

    return error.message ?? 'Nie udalo sie obsluzyc archiwum raportow.';
  }

  return 'Nie udalo sie obsluzyc archiwum raportow.';
}

String _subscriptionError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do subskrypcji.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych subskrypcji.';
  }

  return 'Nie udalo sie pobrac danych subskrypcji.';
}

String _recurringIncomeError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Brak dostepu do stalych dochodow.';
    }

    return error.message ?? 'Nie udalo sie pobrac danych stalych dochodow.';
  }

  return 'Nie udalo sie pobrac danych stalych dochodow.';
}

String _currency(double amount) {
  return formatDisplayCurrency(amount);
}

String _signedCurrency(double amount) {
  final prefix = amount >= 0 ? '+' : '-';
  return '$prefix${_currency(amount.abs())}';
}

String _signedPercent(double value) {
  final prefix = value >= 0 ? '+' : '-';
  return '$prefix${_percent(value.abs())}';
}

String _percent(double value) {
  final percent = formatDisplayDecimal(
    value * 100,
    fractionDigits: value.abs() < 0.1 ? 1 : 0,
  );
  return '$percent%';
}

String _number(double value) {
  return formatDisplayNumber(value);
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _dateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_date(date)} $hour:$minute';
}

String _periodLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '$month.${date.year}';
}

String _fileSize(int sizeBytes) {
  if (sizeBytes < 1024) {
    return '$sizeBytes B';
  }

  final sizeKb = sizeBytes / 1024;
  if (sizeKb < 1024) {
    return '${sizeKb.toStringAsFixed(1).replaceAll('.', ',')} KB';
  }

  final sizeMb = sizeKb / 1024;
  return '${sizeMb.toStringAsFixed(1).replaceAll('.', ',')} MB';
}

String _subscriptionCycle(SubscriptionBillingCycle cycle) {
  switch (cycle) {
    case SubscriptionBillingCycle.monthly:
      return 'Miesiecznie';
    case SubscriptionBillingCycle.quarterly:
      return 'Kwartalnie';
    case SubscriptionBillingCycle.yearly:
      return 'Rocznie';
  }
}

List<Widget> _optionalWidget(Widget? child) {
  if (child == null) {
    return const [];
  }

  return [child];
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

Color _warningColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFFD7BA73)
      : const Color(0xFFB45309);
}

Color _infoColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF8FBEF5)
      : const Color(0xFF1D4ED8);
}
