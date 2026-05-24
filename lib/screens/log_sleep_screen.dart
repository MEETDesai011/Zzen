// Log Sleep Screen — Feature 1: Sleep Score Tracker
// SDG 3 Impact: Daily sleep logging creates awareness of sleep duration and
// consistency, directly supporting physical health improvement (SDG 3.4).
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/sleep_service.dart';

class LogSleepScreen extends StatefulWidget {
  const LogSleepScreen({super.key});

  @override
  State<LogSleepScreen> createState() => _LogSleepScreenState();
}

class _LogSleepScreenState extends State<LogSleepScreen> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  bool _saving = false;
  int? _previewScore;
  double? _previewHours;

  @override
  void initState() {
    super.initState();
    _updatePreview();
  }

  void _updatePreview() {
    final now = DateTime.now();
    final sleep = DateTime(now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
    var wake = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wake.isBefore(sleep)) wake = wake.add(const Duration(days: 1));
    final hours = wake.difference(sleep).inMinutes / 60.0;
    final score = SleepService.instance.calculateScore(durationHours: hours);
    setState(() {
      _previewScore = score;
      _previewHours = hours;
    });
  }

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
        ),
        child: child!,
      ),
    );
    if (picked != null) { setState(() => _sleepTime = picked); _updatePreview(); }
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
        ),
        child: child!,
      ),
    );
    if (picked != null) { setState(() => _wakeTime = picked); _updatePreview(); }
  }

  Future<void> _saveSleep() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final sleep = DateTime(now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
      var wake = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
      if (wake.isBefore(sleep)) wake = wake.add(const Duration(days: 1));

      final entry = await SleepService.instance.logSleep(sleepTime: sleep, wakeTime: wake);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sleep logged! Score: ${entry.score}/100 🌙'),
          backgroundColor: ZzenTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to save. Try again.'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _previewScore ?? 0;
    final scoreColor = ZzenTheme.scoreColor(score);

    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Log Sleep'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/habits'),
            child: const Text('Habits →', style: TextStyle(color: ZzenTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score preview card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ZzenTheme.primary.withOpacity(0.15), ZzenTheme.secondary.withOpacity(0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ZzenTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preview Score', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('$score', style: TextStyle(color: scoreColor, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
                        Text('${_previewHours?.toStringAsFixed(1) ?? '0.0'} hours',
                            style: const TextStyle(color: ZzenTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                  Text(score >= 70 ? '😌' : score >= 40 ? '😐' : '😫',
                      style: const TextStyle(fontSize: 48)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('When did you sleep?',
                style: TextStyle(color: ZzenTheme.textMuted, fontSize: 13, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            // Sleep time picker
            _TimeTile(
              icon: Icons.bedtime_rounded,
              label: 'Fell Asleep',
              time: _sleepTime.format(context),
              onTap: _pickSleepTime,
            ),
            const SizedBox(height: 12),
            // Wake time picker
            _TimeTile(
              icon: Icons.wb_sunny_rounded,
              label: 'Woke Up',
              time: _wakeTime.format(context),
              onTap: _pickWakeTime,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSleep,
                child: _saving
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Sleep Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            // Score guide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZzenTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ZzenTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Score formula', style: TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  _row('8 hours of sleep', '100 pts'),
                  _row('Each 30min below 8h', '-10 pts'),
                  _row('Each 30min above 8h', '-5 pts'),
                  _row('Same bedtime ±30min', '+10 bonus'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: ZzenTheme.textSecondary, fontSize: 12)),
        Text(r, style: const TextStyle(color: ZzenTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({required this.icon, required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZzenTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ZzenTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: ZzenTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: ZzenTheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
                  Text(time, style: const TextStyle(color: ZzenTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ZzenTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
