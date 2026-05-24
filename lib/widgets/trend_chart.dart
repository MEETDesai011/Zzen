// Trend Chart Widget — 7-day sleep score line chart
// Shows weekly sleep score trend using fl_chart package.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../models/sleep_entry.dart';

class TrendChart extends StatelessWidget {
  final List<SleepEntry> entries;
  final double height;

  const TrendChart({
    super.key,
    required this.entries,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Log sleep to see your trend 📈',
            style: TextStyle(color: ZzenTheme.textMuted),
          ),
        ),
      );
    }

    // Sort entries oldest to newest for the chart
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].score.toDouble()));
    }

    final minScore = spots.map((s) => s.y).reduce(min);
    final maxScore = spots.map((s) => s.y).reduce(max);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sorted.length - 1).toDouble().clamp(0, 6),
          minY: (minScore - 10).clamp(0, 100),
          maxY: (maxScore + 10).clamp(0, 100),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: ZzenTheme.border,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sorted[idx].date;
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[date.weekday - 1],
                      style: const TextStyle(
                        color: ZzenTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: ZzenTheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: ZzenTheme.primary,
                    strokeWidth: 2,
                    strokeColor: ZzenTheme.background,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    ZzenTheme.primary.withOpacity(0.2),
                    ZzenTheme.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => ZzenTheme.surfaceVariant,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.round()}',
                    const TextStyle(
                      color: ZzenTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Need to import min/max
double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;
