// Alarm Screen — Feature 5: Smart Alarm
// SDG 3 Impact: Smart alarm scheduling within light-sleep windows reduces
// sleep inertia, supporting better daily functioning and wellbeing (SDG 3.4).
// Note: Full accelerometer-based sleep phase detection requires overnight background
// processing — window-randomisation is the demo-safe hackathon implementation.
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/notification_service.dart';
import '../services/sleep_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay _windowStart = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _windowEnd = const TimeOfDay(hour: 7, minute: 30);
  bool _alarmSet = false;
  bool _saving = false;
  int? _lastScore;

  @override
  void initState() {
    super.initState();
    _loadLastScore();
  }

  Future<void> _loadLastScore() async {
    try {
      final entry = await SleepService.instance.getTodayEntry();
      if (entry != null) setState(() => _lastScore = entry.score);
    } catch (_) {}
  }

  Future<void> _pickWindowStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _windowStart,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _windowStart = picked;
        // Ensure end is 30min after start
        final endMinute = picked.hour * 60 + picked.minute + 30;
        _windowEnd = TimeOfDay(hour: endMinute ~/ 60 % 24, minute: endMinute % 60);
      });
    }
  }

  Future<void> _pickWindowEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _windowEnd,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _windowEnd = picked);
  }

  Future<void> _setAlarm() async {
    setState(() => _saving = true);
    try {
      await NotificationService.instance.scheduleSmartAlarm(
        windowStart: _windowStart,
        windowEnd: _windowEnd,
      );
      setState(() => _alarmSet = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Smart alarm set! Will wake you between ${_windowStart.format(context)} and ${_windowEnd.format(context)} 🌅'),
          backgroundColor: ZzenTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to set alarm. Grant notification permission.'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _cancelAlarm() async {
    await NotificationService.instance.cancel(ZzenConstants.smartAlarmNotificationId);
    setState(() => _alarmSet = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Alarm cancelled'),
        backgroundColor: ZzenTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Smart Alarm'),
        leading: Navigator.canPop(context)
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last night score card
            if (_lastScore != null) _buildLastScoreCard(),

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZzenTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZzenTheme.secondary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('🧠', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zzen picks the optimal wake moment within your window — when you\'re likely in lightest sleep.',
                      style: TextStyle(color: ZzenTheme.secondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Wake Window', style: TextStyle(color: ZzenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Zzen will wake you at the best moment in this range', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),

            // Window pickers
            Row(
              children: [
                Expanded(child: _WindowTile(label: 'Earliest', time: _windowStart.format(context), onTap: _pickWindowStart)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, color: ZzenTheme.textMuted),
                ),
                Expanded(child: _WindowTile(label: 'Latest', time: _windowEnd.format(context), onTap: _pickWindowEnd)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${_windowDurationMinutes()} minute window',
                style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            // Set/Cancel alarm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : (_alarmSet ? _cancelAlarm : _setAlarm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alarmSet ? ZzenTheme.error : ZzenTheme.primary,
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _alarmSet ? 'Cancel Alarm' : 'Set Smart Alarm 🌅',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            if (_alarmSet) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ZzenTheme.scoreGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ZzenTheme.scoreGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Alarm active! You\'ll be woken between ${_windowStart.format(context)} and ${_windowEnd.format(context)} tomorrow.',
                        style: const TextStyle(color: ZzenTheme.scoreGreen, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Developer note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ZzenTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ZzenTheme.border),
              ),
              child: const Text(
                'ℹ️ Dev note: This uses window-randomisation for the hackathon build. Full accelerometer-based sleep phase detection requires overnight background sensor processing and is planned for v2.',
                style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastScoreCard() {
    final color = ZzenTheme.scoreColor(_lastScore!);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('😴', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last night\'s score', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
              Text('$_lastScore / 100', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  int _windowDurationMinutes() {
    final startMin = _windowStart.hour * 60 + _windowStart.minute;
    final endMin = _windowEnd.hour * 60 + _windowEnd.minute;
    return (endMin - startMin).abs();
  }
}

class _WindowTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _WindowTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ZzenTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZzenTheme.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: ZzenTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
