import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatting/display_number_formatter.dart';
import '../../../models/finance_models.dart';
import '../domain/investment_repository.dart';

class InvestmentDetailsScreen extends StatelessWidget {
  const InvestmentDetailsScreen({
    super.key,
    required this.userId,
    required this.investmentId,
    required this.investmentRepository,
    required this.listenable,
    required this.investmentById,
  });

  final String userId;
  final String investmentId;
  final InvestmentRepository investmentRepository;
  final Listenable listenable;
  final InvestmentHolding? Function(String investmentId) investmentById;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final investment = investmentById(investmentId);
        if (investment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Szczegoly inwestycji')),
            body: Center(
              child: Text(
                'Pozycja nie jest juz dostepna.',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${investment.displaySymbol} - ${investment.name}'),
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
                      _InvestmentSummaryCard(investment: investment),
                      const SizedBox(height: 20),
                      StreamBuilder<List<InvestmentPricePoint>>(
                        stream: investmentRepository.watchPriceHistory(
                          userId: userId,
                          investmentId: investment.id,
                        ),
                        builder: (context, snapshot) {
                          final priceHistory =
                              snapshot.data ?? const <InvestmentPricePoint>[];
                          return _PriceHistoryCard(
                            investment: investment,
                            priceHistory: priceHistory,
                            isLoading: !snapshot.hasData,
                          );
                        },
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

class _InvestmentSummaryCard extends StatelessWidget {
  const _InvestmentSummaryCard({required this.investment});

  final InvestmentHolding investment;

  @override
  Widget build(BuildContext context) {
    final hasMarketQuote = investment.lastPriceDate != null;
    final profitColor = investment.profit >= 0
        ? _successColor(context)
        : _dangerColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pozycja i aktualna wycena',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              investment.supportsMarketData
                  ? hasMarketQuote
                        ? 'Aktualna wartosc bazuje na ostatniej cenie krypto albo recznej wycenie.'
                        : 'Dla tej pozycji nie ma jeszcze aktualnej ceny krypto. Na razie widzisz kapital wg zakupu.'
                  : 'Dla tego typu aktywa pokazujemy reczna wycene pozycji.',
              style: TextStyle(color: _mutedTextColor(context), height: 1.5),
            ),
            const SizedBox(height: 18),
            Text(
              hasMarketQuote
                  ? 'Wartosc rynkowa ${_currency(investment.currentValue)}'
                  : investment.supportsMarketData
                  ? 'Kapital wg zakupu ${_currency(investment.investedValue)}'
                  : 'Wartosc ${_currency(investment.currentValue)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            if (hasMarketQuote || !investment.supportsMarketData) ...[
              const SizedBox(height: 6),
              Text(
                'Wynik ${_signedCurrency(investment.profit)}',
                style: TextStyle(
                  color: profitColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(label: 'Typ aktywa', value: investment.assetType.label),
                _Metric(
                  label: 'Ticker / symbol',
                  value: investment.hasSymbol ? investment.symbol : 'Brak',
                ),
                _Metric(label: 'Jednostki', value: _number(investment.units)),
                _Metric(
                  label: 'Cena zakupu',
                  value: _currency(investment.buyPrice),
                ),
                _Metric(
                  label: investment.supportsMarketData && !hasMarketQuote
                      ? 'Cena krypto'
                      : 'Cena biezaca',
                  value: investment.supportsMarketData && !hasMarketQuote
                      ? 'Brak'
                      : _currency(investment.currentPrice),
                ),
                _Metric(
                  label: 'Data kursu',
                  value: investment.lastPriceDate == null
                      ? 'Brak'
                      : _date(investment.lastPriceDate!),
                ),
                _Metric(
                  label: 'Ostatnia aktualizacja',
                  value: investment.lastPriceUpdateAt == null
                      ? 'Brak'
                      : _dateTime(investment.lastPriceUpdateAt!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({
    required this.investment,
    required this.priceHistory,
    required this.isLoading,
  });

  final InvestmentHolding investment;
  final List<InvestmentPricePoint> priceHistory;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historia cen zamkniecia',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              investment.supportsMarketData
                  ? 'Wykres pokazuje zapisana historie cen tej pozycji.'
                  : 'Dla tego typu aktywa historia cen nie jest dostepna.',
              style: TextStyle(color: _mutedTextColor(context), height: 1.4),
            ),
            const SizedBox(height: 20),
            if (!investment.supportsMarketData)
              Text(
                'Brak historii cen dla tej klasy aktywa.',
                style: TextStyle(color: _mutedTextColor(context), height: 1.5),
              )
            else if (isLoading)
              const LinearProgressIndicator(minHeight: 6)
            else if (priceHistory.isEmpty)
              Text(
                'Nie ma jeszcze historii cen dla ${investment.displaySymbol}.',
                style: TextStyle(color: _mutedTextColor(context), height: 1.5),
              )
            else ...[
              SizedBox(
                height: 220,
                width: double.infinity,
                child: _PriceHistoryChart(points: priceHistory),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(
                    label: 'Punktow historii',
                    value: '${priceHistory.length}',
                  ),
                  _Metric(
                    label: 'Najnowsze zamkniecie',
                    value: _currency(priceHistory.last.closePrice),
                  ),
                  _Metric(
                    label: 'Najstarszy punkt',
                    value: _date(priceHistory.first.priceDate),
                  ),
                  _Metric(
                    label: 'Najnowszy punkt',
                    value: _date(priceHistory.last.priceDate),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  const _PriceHistoryChart({required this.points});

  final List<InvestmentPricePoint> points;

  @override
  Widget build(BuildContext context) {
    final sortedPoints = List<InvestmentPricePoint>.from(points)
      ..sort((left, right) => left.priceDate.compareTo(right.priceDate));

    return CustomPaint(
      painter: _PriceHistoryChartPainter(
        points: sortedPoints,
        lineColor: Theme.of(context).colorScheme.primary,
        guideColor: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
        textColor: Theme.of(
          context,
        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
      ),
    );
  }
}

class _PriceHistoryChartPainter extends CustomPainter {
  _PriceHistoryChartPainter({
    required this.points,
    required this.lineColor,
    required this.guideColor,
    required this.textColor,
  });

  final List<InvestmentPricePoint> points;
  final Color lineColor;
  final Color guideColor;
  final Color? textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const chartPadding = EdgeInsets.fromLTRB(8, 12, 8, 28);
    final chartRect = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      math.max(0, size.width - chartPadding.horizontal),
      math.max(0, size.height - chartPadding.vertical),
    );
    if (chartRect.width <= 0 || chartRect.height <= 0) {
      return;
    }

    final minPrice = points.map((point) => point.closePrice).reduce(math.min);
    final maxPrice = points.map((point) => point.closePrice).reduce(math.max);
    final priceRange = math.max(0.01, maxPrice - minPrice);

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final dy = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        guidePaint,
      );
    }

    final path = Path();
    final pointOffsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final dx = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + (chartRect.width * index / (points.length - 1));
      final normalizedPrice = (point.closePrice - minPrice) / priceRange;
      final dy = chartRect.bottom - (normalizedPrice * chartRect.height);
      final offset = Offset(dx, dy);
      pointOffsets.add(offset);
      if (index == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withValues(alpha: 0.22), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    final fillPath = Path.from(path)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()..color = lineColor;
    for (final offset in pointOffsets) {
      canvas.drawCircle(offset, 3.5, dotPaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    void paintLabel(String text, Offset offset) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(canvas, offset);
    }

    paintLabel(
      _currency(points.first.closePrice),
      Offset(chartRect.left, chartRect.top - 2),
    );
    paintLabel(
      _currency(points.last.closePrice),
      Offset(
        math.max(chartRect.left, chartRect.right - textPainter.width),
        chartRect.top - 2,
      ),
    );

    final firstLabel = _shortDate(points.first.priceDate);
    final lastLabel = _shortDate(points.last.priceDate);
    paintLabel(firstLabel, Offset(chartRect.left, chartRect.bottom + 6));
    textPainter.text = TextSpan(
      text: lastLabel,
      style: TextStyle(color: textColor, fontSize: 11),
    );
    textPainter.layout();
    paintLabel(
      lastLabel,
      Offset(chartRect.right - textPainter.width, chartRect.bottom + 6),
    );
  }

  @override
  bool shouldRepaint(covariant _PriceHistoryChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.textColor != textColor;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
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

String _currency(double amount) {
  return formatDisplayCurrency(amount);
}

String _signedCurrency(double amount) {
  final prefix = amount >= 0 ? '+' : '-';
  return '$prefix${_currency(amount.abs())}';
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String _dateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_date(date)} $hour:$minute';
}

String _number(double value) {
  return formatDisplayDecimal(value, fractionDigits: 4);
}
