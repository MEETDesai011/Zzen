// Insights Screen — Feature 7: Screen Time vs Sleep Correlation
// SDG 3 Impact: Showing users how screen time affects sleep empowers healthier
// digital habits, reducing sleep deprivation risk (SDG 3.4).
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../services/screen_time_service.dart';
import '../services/sleep_service.dart';
import '../models/sleep_entry.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<ScreenDayData> _screenData = [];
  List<SleepEntry> _sleepEntries = [];
  bool _loading = true;
  bool _hasPermission = false;
  String _correlationInsight = '';

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    setState(() => _loading = true);
    try {
      final hasPerm = await ScreenTimeService.instance.hasPermission();
      setState(() => _hasPermission = hasPerm);

      if (hasPerm) {
        final screenData = await ScreenTimeService.instance.getLast7DaysScreenTime();
        final sleepData = await SleepService.instance.getLast7Days();
        final insight = ScreenTimeService.instance.analyseCorrelation(
          screenData: screenData,
          sleepEntries: sleepData,
        );
        setState(() {
          _screenData = screenData;
          _sleepEntries = sleepData;
          _correlationInsight = insight;
        });
      }
    } catch (e) {
      setState(() => _hasPermission = false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Insights'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ZzenTheme.primary))
          : !_hasPermission
              ? _buildPermissionPrompt()
              : _buildInsightsContent(),
    );
  }

  Widget _buildPermissionPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: ZzenTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('📱', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 24),
          const Text('Screen Time Insights', style: TextStyle(
              color: ZzenTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text(
            'Enable Usage Access to see how your screen time affects your sleep score.',
            style: TextStyle(color: ZzenTheme.textSecondary, fontSize: 15, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Settings → Apps → Special App Access → Usage Access → Zzen',
            style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ScreenTimeService.instance.requestPermission();
              // Re-check after returning from Settings
              await Future.delayed(const Duration(seconds: 1));
              _checkAndLoad();
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Open Settings'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _checkAndLoad,
            child: const Text('I\'ve enabled it, retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insight card
          _buildInsightCard(),
          const SizedBox(height: 24),
          const Text('Screen Time vs Sleep Score', style: TextStyle(
              color: ZzenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Dual axis bar chart
          Container(
            padding: const EdgeInsets.all(16),
            height: 240,
            decoration: BoxDecoration(
              color: ZzenTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZzenTheme.border),
            ),
            child: _buildDualAxisChart(),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _LegendDot(color: ZzenTheme.primary, label: 'Sleep Score'),
              const SizedBox(width: 20),
              _LegendDot(color: ZzenTheme.secondary, label: 'Screen Time (h)'),
            ],
          ),
          const SizedBox(height: 24),
          // Per day breakdown
          const Text('Daily Breakdown', style: TextStyle(
              color: ZzenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._buildDayBreakdown(),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    final isNegative = _correlationInsight.contains('hurting');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegative
            ? ZzenTheme.error.withOpacity(0.1)
            : ZzenTheme.scoreGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNegative ? ZzenTheme.error.withOpacity(0.3) : ZzenTheme.scoreGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(isNegative ? '⚠️' : '✅', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_correlationInsight.isEmpty ? 'Analysing your data...' : _correlationInsight,
                style: TextStyle(
                  color: isNegative ? ZzenTheme.error : ZzenTheme.scoreGreen,
                  fontWeight: FontWeight.w600, fontSize: 14,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildDualAxisChart() {
    if (_screenData.isEmpty || _sleepEntries.isEmpty) {
      return const Center(
        child: Text('Log sleep and enable screen time to see chart', style: TextStyle(color: ZzenTheme.textMuted)),
      );
    }

    final screenGroups = <BarChartGroupData>[];

    for (int i = 0; i < _screenData.length && i < 7; i++) {
      final screen = _screenData[i];
      final sleepScore = _findSleepScore(screen.date);

      screenGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sleepScore.toDouble(),
              color: ZzenTheme.primary.withOpacity(0.8),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: screen.hoursUsed * 10, // Scale to 0-100 for same axis
              color: ZzenTheme.secondary.withOpacity(0.8),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          barsSpace: 4,
        ),
      );
    }

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: screenGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: ZzenTheme.border, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= _screenData.length) return const SizedBox.shrink();
                final date = _screenData[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(days[date.weekday - 1],
                      style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ZzenTheme.surfaceVariant,
          ),
        ),
      ),
    );
  }

  int _findSleepScore(DateTime date) {
    for (final entry in _sleepEntries) {
      if (entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day) {
        return entry.score;
      }
    }
    return 0;
  }

  List<Widget> _buildDayBreakdown() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _screenData.map((screen) {
      final score = _findSleepScore(screen.date);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ZzenTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZzenTheme.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(days[screen.date.weekday - 1],
                  style: const TextStyle(color: ZzenTheme.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('📱 ${screen.hoursUsed.toStringAsFixed(1)}h screen',
                          style: const TextStyle(color: ZzenTheme.textSecondary, fontSize: 12)),
                      Text('😴 $score/100 sleep',
                          style: TextStyle(
                            color: score >= 70 ? ZzenTheme.scoreGreen : score >= 40 ? ZzenTheme.scoreYellow : ZzenTheme.scoreRed,
                            fontWeight: FontWeight.w600, fontSize: 12,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
      ],
    );
  }
}
