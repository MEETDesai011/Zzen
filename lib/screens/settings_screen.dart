// Settings Screen — Feature 3: Bedtime App Lock
// SDG 3 Impact: Scheduled bedtime reminders and Digital Wellbeing integration
// reduce harmful screen exposure before sleep, improving sleep health (SDG 3.4).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/firebase_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  bool _bedtimeNotificationsEnabled = false;
  bool _habitReminderEnabled = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZzenTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out? Your local preferences and settings will be reset.', style: TextStyle(color: ZzenTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: ZzenTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ZzenTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _saving = true);
      try {
        await FirebaseService.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: ZzenTheme.error,
          ));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt('bedtime_hour') ?? 23;
    final m = prefs.getInt('bedtime_minute') ?? 0;
    final notifEnabled = prefs.getBool('bedtime_notif') ?? false;
    final habitEnabled = prefs.getBool('habit_reminder') ?? true;
    setState(() {
      _bedtime = TimeOfDay(hour: h, minute: m);
      _bedtimeNotificationsEnabled = notifEnabled;
      _habitReminderEnabled = habitEnabled;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('bedtime_hour', _bedtime.hour);
      await prefs.setInt('bedtime_minute', _bedtime.minute);
      await prefs.setBool('bedtime_notif', _bedtimeNotificationsEnabled);
      await prefs.setBool('habit_reminder', _habitReminderEnabled);

      if (_bedtimeNotificationsEnabled) {
        await NotificationService.instance.scheduleBedtimeNotification(_bedtime);
        await NotificationService.instance.scheduleWindDownNotification(_bedtime);
      } else {
        await NotificationService.instance.cancel(ZzenConstants.bedtimeNotificationId);
        await NotificationService.instance.cancel(ZzenConstants.windDownNotificationId);
      }

      if (_habitReminderEnabled) {
        await NotificationService.instance.scheduleHabitLogNotification();
      } else {
        await NotificationService.instance.cancel(ZzenConstants.habitLogNotificationId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Settings saved! 🌙'),
          backgroundColor: ZzenTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to save settings.'),
          backgroundColor: ZzenTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  /// Open Android Digital Wellbeing settings for app focus mode.
  /// Note: Full programmatic app locking requires system-level permissions
  /// unavailable to user apps. This is the approach used by Calm and Headspace.
  Future<void> _openDigitalWellbeing() async {
    try {
      final uri = Uri.parse('android.settings.DIGITAL_WELLBEING_SETTINGS');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to general app settings
        final settingsUri = Uri.parse('package:com.android.settings');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          if (mounted) _showFocusModeInstructions();
        }
      }
    } catch (e) {
      if (mounted) _showFocusModeInstructions();
    }
  }

  void _showFocusModeInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZzenTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enable Focus Mode', style: TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
          'Go to Settings → Digital Wellbeing → Focus Mode to set app limits for bedtime.',
          style: TextStyle(color: ZzenTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: ZzenTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Navigator.canPop(context)
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bedtime section
            _sectionHeader('🌙 Bedtime'),
            const SizedBox(height: 12),
            _buildBedtimePicker(),
            const SizedBox(height: 16),
            _buildToggle(
              title: 'Bedtime Reminders',
              subtitle: 'Get notified 45 min before + at bedtime',
              value: _bedtimeNotificationsEnabled,
              onChanged: (v) => setState(() => _bedtimeNotificationsEnabled = v),
            ),
            const SizedBox(height: 24),

            // App Lock section
            _sectionHeader('🔒 App Lock'),
            const SizedBox(height: 8),
            const Text(
              'Full app locking requires system permissions. Zzen uses Android\'s built-in Digital Wellbeing Focus Mode — the same approach used by Calm and Headspace.',
              style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.do_not_disturb_on_rounded,
              title: 'Open Digital Wellbeing',
              subtitle: 'Set Focus Mode to limit distracting apps at bedtime',
              onTap: _openDigitalWellbeing,
            ),
            const SizedBox(height: 24),

            // Notifications section
            _sectionHeader('🔔 Notifications'),
            const SizedBox(height: 12),
            _buildToggle(
              title: 'Habit Log Reminder',
              subtitle: 'Daily reminder at 9 PM to log your habits',
              value: _habitReminderEnabled,
              onChanged: (v) => setState(() => _habitReminderEnabled = v),
            ),
            const SizedBox(height: 24),

            // Account section
            _sectionHeader('👤 Account'),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              onTap: _handleSignOut,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // About section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZzenTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZzenTheme.border),
              ),
              child: Column(
                children: [
                  const Text('Zzen v1.0.0', style: TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600)),
                  const Text('sleep better. feel better.', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('SDG 3 — Good Health and Well-being', style: TextStyle(color: ZzenTheme.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: ZzenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600));
  }

  Widget _buildBedtimePicker() {
    return InkWell(
      onTap: _pickBedtime,
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
              child: const Icon(Icons.bedtime_rounded, color: ZzenTheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Bedtime', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
                  Text(_bedtime.format(context), style: const TextStyle(
                      color: ZzenTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ZzenTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZzenTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
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
              decoration: BoxDecoration(color: ZzenTheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: ZzenTheme.secondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: ZzenTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
