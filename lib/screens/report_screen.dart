// Report Screen — Feature 10: Weekly Wellbeing Report
// SDG 3 Impact: Weekly summaries provide users with actionable insights to
// improve long-term sleep health and prevent non-communicable diseases (SDG 3.4).
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/firebase_service.dart';
import '../services/sleep_service.dart';
import '../services/gemini_service.dart';
import '../models/weekly_report.dart';
import '../widgets/risk_badge.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  WeeklyReport? _report;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateReport();
  }

  Future<void> _loadOrGenerateReport() async {
    setState(() => _loading = true);
    try {
      // Try to load existing report for this week
      final weekId = WeeklyReport.weekId(DateTime.now());
      final doc = await FirebaseService.instance
          .userCollection(ZzenConstants.weeklyReportsCollection)
          .doc(weekId)
          .get();

      if (doc.exists) {
        setState(() {
          _report = WeeklyReport.fromFirestore(doc);
          _loading = false;
        });
      } else {
        // Generate new report
        await _generateReport();
      }
    } catch (e) {
      setState(() => _loading = false);
      await _generateReport();
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _generating = true;
      _loading = true;
    });
    try {
      final entries = await SleepService.instance.getLast7Days();
      final debt = await SleepService.instance.getSleepDebt();
      final streak = await FirebaseService.instance.getStreak();

      if (entries.isEmpty) {
        setState(() { _loading = false; _generating = false; });
        return;
      }

      // Calculate stats
      final scores = entries.map((e) => e.score).toList();
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      final bestEntry = entries.reduce((a, b) => a.score > b.score ? a : b);
      final worstEntry = entries.reduce((a, b) => a.score < b.score ? a : b);

      // Get AI insight
      final aiInsight = await GeminiService.instance.getWeeklyInsight(entries);

      final weekId = WeeklyReport.weekId(DateTime.now());
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final report = WeeklyReport(
        id: weekId,
        weekStart: weekStart,
        weekEnd: weekEnd,
        avgScore: avgScore,
        bestNightDate: bestEntry.date,
        bestNightScore: bestEntry.score,
        worstNightDate: worstEntry.date,
        worstNightScore: worstEntry.score,
        sleepDebtHours: debt,
        aiInsight: aiInsight,
        streakCount: streak,
        generatedAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseService.instance
          .userCollection(ZzenConstants.weeklyReportsCollection)
          .doc(weekId)
          .set(report.toFirestore());

      setState(() {
        _report = report;
        _loading = false;
        _generating = false;
      });
    } catch (e) {
      setState(() { _loading = false; _generating = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to generate report. Log more sleep!'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _shareReport() async {
    try {
      final image = await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/zzen_report.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My weekly sleep report from Zzen 🌙 Sleep score: ${_report?.avgScore.round()}/100',
        subject: 'Zzen Weekly Sleep Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to share report.'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Weekly Report'),
        leading: Navigator.canPop(context)
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          if (_report != null)
            IconButton(
              onPressed: _shareReport,
              icon: const Icon(Icons.share_rounded, color: ZzenTheme.primary),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: ZzenTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _generating ? 'Generating your report with AI... 🤖' : 'Loading report...',
                    style: const TextStyle(color: ZzenTheme.textMuted),
                  ),
                ],
              ),
            )
          : _report == null
              ? _buildEmptyState()
              : _buildReport(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('No Report Yet', style: TextStyle(color: ZzenTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Log sleep for at least 1 night to generate your weekly report.',
                style: TextStyle(color: ZzenTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateReport,
              child: const Text('Generate Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // The shareable report card
          Screenshot(
            controller: _screenshotController,
            child: _ReportCard(report: _report!),
          ),
          const SizedBox(height: 20),
          // Regenerate button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generating ? null : _generateReport,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Regenerate Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZzenTheme.primary,
                side: const BorderSide(color: ZzenTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareReport,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final WeeklyReport report;

  const _ReportCard({required this.report});

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final avgColor = ZzenTheme.scoreColor(report.avgScore.round());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZzenTheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weekly Report', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
                    const Text('Zzen', style: TextStyle(color: ZzenTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ZzenTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ZzenTheme.primary.withOpacity(0.4)),
                  ),
                  child: Text('SDG 3', style: TextStyle(color: ZzenTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Average score
            Center(
              child: Column(
                children: [
                  Text('${report.avgScore.round()}', style: TextStyle(
                    color: avgColor, fontSize: 72, fontWeight: FontWeight.w900, height: 1,
                  )),
                  Text('avg sleep score this week', style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  RiskBadge.fromScore(report.avgScore.round()),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                Expanded(child: _StatBox(
                  emoji: '🏆', label: 'Best Night',
                  value: '${report.bestNightScore}',
                  sub: _formatDate(report.bestNightDate),
                  color: ZzenTheme.scoreGreen,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(
                  emoji: '😴', label: 'Worst Night',
                  value: '${report.worstNightScore}',
                  sub: _formatDate(report.worstNightDate),
                  color: ZzenTheme.scoreRed,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatBox(
                  emoji: '😴', label: 'Sleep Debt',
                  value: '${report.sleepDebtHours.toStringAsFixed(1)}h',
                  sub: 'this week',
                  color: ZzenTheme.debtColor(report.sleepDebtHours),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(
                  emoji: '🔥', label: 'Streak',
                  value: '${report.streakCount}',
                  sub: 'days',
                  color: const Color(0xFFFF6B35),
                )),
              ],
            ),
            const SizedBox(height: 20),

            // AI insight
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZzenTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.aiInsight.isEmpty ? 'Log more sleep for AI insights!' : report.aiInsight,
                      style: const TextStyle(color: ZzenTheme.textPrimary, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Center(
              child: Text(
                'Generated ${_formatDate(report.generatedAt)} · sleep better. feel better.',
                style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatBox({required this.emoji, required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label', style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
