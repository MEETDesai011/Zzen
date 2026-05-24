// Screen Time Service — Fetch Android screen time via app_usage package
// SDG 3 Impact: Understanding screen time's impact on sleep empowers users to
// make healthier digital choices (SDG 3.4 mental health and wellbeing).
import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';

class ScreenTimeService {
  ScreenTimeService._();
  static final ScreenTimeService instance = ScreenTimeService._();

  /// Check if the PACKAGE_USAGE_STATS permission is granted.
  /// This requires the user to manually enable it in Settings > Digital Wellbeing.
  Future<bool> hasPermission() async {
    // app_usage checks this internally — we try a test fetch
    try {
      final now = DateTime.now();
      final testStart = now.subtract(const Duration(hours: 1));
      await AppUsage().getAppUsage(testStart, now);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request usage stats permission by opening the Settings page.
  /// Note: PACKAGE_USAGE_STATS cannot be granted programmatically —
  /// the user must enable it in Settings > Apps > Special App Access > Usage Access.
  Future<void> requestPermission() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Open settings error: $e');
    }
  }

  /// Fetch total screen time (in hours) for each of the last 7 days.
  /// Returns a list of [ScreenDayData] ordered from oldest to newest.
  Future<List<ScreenDayData>> getLast7DaysScreenTime() async {
    final result = <ScreenDayData>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

      try {
        final usageMap = await AppUsage().getAppUsage(start, end);

        // Sum all app usages (excluding system apps with very short usage)
        double totalHours = 0;
        for (final info in usageMap) {
          final minutes = info.usage.inMinutes;
          // Filter noise: only count apps used for more than 1 minute
          if (minutes > 1) {
            totalHours += minutes / 60.0;
          }
        }

        result.add(ScreenDayData(date: start, hoursUsed: totalHours));
      } catch (e) {
        // If permission denied or data unavailable, return 0 for that day
        result.add(ScreenDayData(date: start, hoursUsed: 0));
        debugPrint('Screen time fetch error for day $i: $e');
      }
    }

    return result;
  }

  /// Analyse correlation between screen time and sleep score.
  /// Returns an insight string for display.
  String analyseCorrelation({
    required List<ScreenDayData> screenData,
    required List<dynamic> sleepEntries, // List<SleepEntry>
  }) {
    if (screenData.isEmpty || sleepEntries.isEmpty) {
      return 'Log more data to see screen time insights! 📊';
    }

    // Find days with 6+ hours screen time and check their sleep scores
    int highScreenDays = 0;
    int highScreenLowSleepDays = 0;

    for (final screen in screenData) {
      if (screen.hoursUsed >= 6) {
        highScreenDays++;
        // Find matching sleep entry
        for (final entry in sleepEntries) {
          final entryDate = entry.date as DateTime;
          if (entryDate.year == screen.date.year &&
              entryDate.month == screen.date.month &&
              entryDate.day == screen.date.day) {
            if ((entry.score as int) < 60) {
              highScreenLowSleepDays++;
            }
            break;
          }
        }
      }
    }

    if (highScreenDays > 0 && highScreenLowSleepDays >= (highScreenDays * 0.6).round()) {
      return '📱 High screen time is hurting your sleep';
    }

    return 'Your screen habits look balanced this week 👍';
  }
}

/// Data class for a single day's screen time
class ScreenDayData {
  final DateTime date;
  final double hoursUsed;

  const ScreenDayData({required this.date, required this.hoursUsed});
}

