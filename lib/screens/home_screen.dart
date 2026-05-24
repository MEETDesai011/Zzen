// Home Screen — Sleep Score Dashboard
// SDG 3 Impact: This screen gives users immediate feedback on their sleep quality,
// motivating daily engagement with sleep health tracking (SDG 3.4: reduce
// premature mortality from non-communicable diseases linked to poor sleep).
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/sleep_entry.dart';
import '../services/sleep_service.dart';
import '../core/firebase_service.dart';
import '../widgets/sleep_score_ring.dart';
import '../widgets/trend_chart.dart';
import '../widgets/risk_badge.dart';
import 'settings_screen.dart';
import 'alarm_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SleepEntry> _entries = [];
  double _sleepDebt = 0;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final entries = await SleepService.instance.getLast7Days();
      final debt = await SleepService.instance.getSleepDebt();
      final streak = await FirebaseService.instance.getStreak();
      setState(() {
        _entries = entries;
        _sleepDebt = debt;
        _streak = streak;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  SleepEntry? get _lastEntry => _entries.isNotEmpty ? _entries.first : null;
  int get _currentScore => _lastEntry?.score ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: ZzenTheme.primary,
        backgroundColor: ZzenTheme.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildScoreSection(),
                  const SizedBox(height: 24),
                  _buildStreakAndBadge(),
                  const SizedBox(height: 24),
                  _buildTrendSection(),
                  const SizedBox(height: 24),
                  _buildSleepDebtSection(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      backgroundColor: ZzenTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ZzenTheme.primary, ZzenTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Z', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Zzen', style: TextStyle(color: ZzenTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlarmScreen()),
                  ),
                  icon: const Icon(Icons.alarm_rounded, color: ZzenTheme.textSecondary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.settings_rounded, color: ZzenTheme.textSecondary, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          _lastEntry != null ? 'last night' : 'no data yet',
          style: const TextStyle(
            color: ZzenTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: ZzenTheme.primary),
            ),
          )
        else
          Center(
            child: SleepScoreRing(
              score: _currentScore,
              size: 200,
            ),
          ),
        if (_lastEntry != null) ...[
          const SizedBox(height: 16),
          Text(
            '${_lastEntry!.durationHours.toStringAsFixed(1)} hours of sleep',
            style: const TextStyle(
              color: ZzenTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStreakAndBadge() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            value: '$_streak',
            label: 'day streak',
            color: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '⭐',
            value: _entries.isNotEmpty
                ? (_entries.map((e) => e.score).reduce((a, b) => a + b) ~/ _entries.length).toString()
                : '—',
            label: 'avg score',
            color: ZzenTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: ZzenTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZzenTheme.border),
            ),
            child: Column(
              children: [
                if (_currentScore > 0)
                  RiskBadge.fromScore(_currentScore),
                if (_currentScore == 0)
                  const Text('—', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 18)),
                const SizedBox(height: 6),
                const Text('quality', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '7-day trend',
          style: TextStyle(
            color: ZzenTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ZzenTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZzenTheme.border),
          ),
          child: TrendChart(entries: _entries),
        ),
      ],
    );
  }

  Widget _buildSleepDebtSection() {
    // Sleep Debt Calculator (Feature 9)
    final debtColor = ZzenTheme.debtColor(_sleepDebt);
    final debtProgress = (_sleepDebt / 14.0).clamp(0.0, 1.0);
    final debtText = _sleepDebt == 0
        ? "You're fully rested this week! 🎉"
        : "You owe your body ${_sleepDebt.toStringAsFixed(1)} hours of sleep 😴";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'sleep debt',
          style: TextStyle(
            color: ZzenTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ZzenTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZzenTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debtText,
                style: const TextStyle(
                  color: ZzenTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: debtProgress,
                  minHeight: 10,
                  backgroundColor: ZzenTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(debtColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0h', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
                  const Text('14h max', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Weekly Report',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: _loadData,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZzenTheme.border),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: ZzenTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ZzenTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZzenTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ZzenTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: ZzenTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
