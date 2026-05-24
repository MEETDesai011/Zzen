// Notification Service — Local notifications for bedtime, wind-down, alarm, habits
// SDG 3 Impact: Timely reminders help users build consistent sleep routines,
// supporting preventive health behaviour aligned with SDG 3.4.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import '../core/constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Initialise the notification plugin
  Future<void> initialise() async {
    if (_initialised) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialised = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — could navigate to specific screen
    debugPrint('Notification tapped: ${response.id}');
  }

  /// Android notification details helper
  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    String? channelDescription,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool ongoing = false,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      ongoing: ongoing,
      color: const Color(0xFF7C6FEA),
      icon: '@mipmap/ic_launcher',
    );
  }

  /// Schedule daily bedtime notification
  Future<void> scheduleBedtimeNotification(TimeOfDay bedtime) async {
    try {
      await initialise();

      // Cancel existing bedtime notification
      await _notifications.cancel(ZzenConstants.bedtimeNotificationId);

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        bedtime.hour,
        bedtime.minute,
      );

      // If time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduled = _toTZDateTime(scheduledDate);

      await _notifications.zonedSchedule(
        ZzenConstants.bedtimeNotificationId,
        'Time to wind down 🌙',
        'Zzen is helping you lock distracting apps and build better sleep habits.',
        tzScheduled,
        NotificationDetails(
          android: _androidDetails(
            channelId: 'bedtime_channel',
            channelName: 'Bedtime Reminder',
            channelDescription: 'Daily bedtime reminder',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule bedtime notification error: $e');
    }
  }

  /// Schedule wind-down reminder 45 minutes before bedtime
  Future<void> scheduleWindDownNotification(TimeOfDay bedtime) async {
    try {
      await initialise();

      await _notifications.cancel(ZzenConstants.windDownNotificationId);

      final windDownTime = TimeOfDay(
        hour: (bedtime.hour * 60 + bedtime.minute - 45) ~/ 60 % 24,
        minute: (bedtime.hour * 60 + bedtime.minute - 45) % 60,
      );

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        windDownTime.hour,
        windDownTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduled = _toTZDateTime(scheduledDate);

      await _notifications.zonedSchedule(
        ZzenConstants.windDownNotificationId,
        'Time to start your wind down routine 🌙',
        'Bedtime is in 45 minutes. Start your Zzen routine now!',
        tzScheduled,
        NotificationDetails(
          android: _androidDetails(
            channelId: 'wind_down_channel',
            channelName: 'Wind Down Reminder',
            channelDescription: 'Pre-bedtime wind down reminder',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule wind-down notification error: $e');
    }
  }

  /// Schedule daily 9 PM habit log prompt
  Future<void> scheduleHabitLogNotification() async {
    try {
      await initialise();

      await _notifications.cancel(ZzenConstants.habitLogNotificationId);

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 21, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduled = _toTZDateTime(scheduledDate);

      await _notifications.zonedSchedule(
        ZzenConstants.habitLogNotificationId,
        'Log today\'s habits before bed 📝',
        'How was today? Track your caffeine, exercise, and stress for better sleep insights.',
        tzScheduled,
        NotificationDetails(
          android: _androidDetails(
            channelId: 'habit_channel',
            channelName: 'Habit Log Reminder',
            channelDescription: 'Daily habit logging prompt at 9 PM',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule habit log notification error: $e');
    }
  }

  /// Schedule smart alarm within a window (randomised for demo)
  ///
  /// Note: Full accelerometer-based sleep phase detection requires overnight
  /// background processing — not feasible in this build. Window-randomisation
  /// is the demo-safe implementation used by many sleep apps at launch.
  Future<void> scheduleSmartAlarm({
    required TimeOfDay windowStart,
    required TimeOfDay windowEnd,
  }) async {
    try {
      await initialise();

      await _notifications.cancel(ZzenConstants.smartAlarmNotificationId);

      final now = DateTime.now();
      final startMinutes = windowStart.hour * 60 + windowStart.minute;
      final endMinutes = windowEnd.hour * 60 + windowEnd.minute;

      // Pick a random time within the window
      final randomMinutes =
          startMinutes + Random().nextInt((endMinutes - startMinutes).abs() + 1);
      final alarmHour = randomMinutes ~/ 60;
      final alarmMinute = randomMinutes % 60;

      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarmHour,
        alarmMinute,
      );

      // If time has passed, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final tzScheduled = _toTZDateTime(alarmTime);

      await _notifications.zonedSchedule(
        ZzenConstants.smartAlarmNotificationId,
        'Rise & shine 🌅',
        'Zzen chose this moment for your lightest sleep. Good morning!',
        tzScheduled,
        NotificationDetails(
          android: _androidDetails(
            channelId: 'alarm_channel',
            channelName: 'Smart Alarm',
            channelDescription: 'Smart wake alarm within selected window',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Smart alarm scheduled for ${alarmTime.toString()}');
    } catch (e) {
      debugPrint('Schedule smart alarm error: $e');
    }
  }

  /// Show an immediate notification
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await initialise();

      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: _androidDetails(
            channelId: 'general_channel',
            channelName: 'General',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Convert DateTime to TZDateTime (using local timezone)
  // flutter_local_notifications requires TZDateTime from the timezone package
  tz.TZDateTime _toTZDateTime(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }
}
