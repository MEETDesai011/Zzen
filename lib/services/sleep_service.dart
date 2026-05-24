// Sleep Service — CRUD for sleep entries and score calculation
// SDG 3 Impact: Accurate sleep tracking and scoring motivates users to improve
// sleep hygiene, directly contributing to physical and mental wellbeing (SDG 3.4).
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_service.dart';
import '../core/constants.dart';
import '../models/sleep_entry.dart';

class SleepService {
  SleepService._();
  static final SleepService instance = SleepService._();

  final _db = FirebaseService.instance;

  /// Calculate sleep score (0–100) based on duration and consistency
  ///
  /// Algorithm:
  /// - Base: 8hrs = 100 points
  /// - Each 30min below 8hrs: -10 points
  /// - Each 30min above 8hrs: -5 points
  /// - Consistency bonus: same bedtime ±30min as yesterday = +10
  int calculateScore({
    required double durationHours,
    DateTime? sleepTime,
    DateTime? previousSleepTime,
  }) {
    // Start at 100 and adjust for duration
    double score = 100.0;
    final diff = durationHours - ZzenConstants.targetSleepHours;

    if (diff < 0) {
      // Under target: -10 per 30min below
      final halfHoursBelow = (-diff * 2).ceil();
      score -= halfHoursBelow * ZzenConstants.pointsPerHalfHourBelow;
    } else if (diff > 0) {
      // Over target: -5 per 30min above
      final halfHoursAbove = (diff * 2).ceil();
      score -= halfHoursAbove * ZzenConstants.pointsPerHalfHourAbove;
    }

    // Consistency bonus: same bedtime ±30min as yesterday
    if (sleepTime != null && previousSleepTime != null) {
      final minuteDiff = (sleepTime.hour * 60 + sleepTime.minute) -
          (previousSleepTime.hour * 60 + previousSleepTime.minute);
      if (minuteDiff.abs() <= ZzenConstants.consistencyWindowMinutes) {
        score += ZzenConstants.consistencyBonusPoints;
      }
    }

    // Clamp to 0–100
    return score.clamp(0, 100).round();
  }

  /// Save a new sleep entry to Firestore
  Future<SleepEntry> logSleep({
    required DateTime sleepTime,
    required DateTime wakeTime,
  }) async {
    try {
      // Calculate duration
      var duration = wakeTime.difference(sleepTime);
      // Handle case where wake time is next day
      if (duration.isNegative) {
        duration = wakeTime.add(const Duration(days: 1)).difference(sleepTime);
      }
      final durationHours = duration.inMinutes / 60.0;

      // Get yesterday's sleep entry for consistency bonus
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SleepEntry? previousEntry;
      try {
        final entries = await getLast7Days();
        for (final entry in entries) {
          if (entry.date.year == yesterday.year &&
              entry.date.month == yesterday.month &&
              entry.date.day == yesterday.day) {
            previousEntry = entry;
            break;
          }
        }
      } catch (_) {}

      final score = calculateScore(
        durationHours: durationHours,
        sleepTime: sleepTime,
        previousSleepTime: previousEntry?.sleepTime,
      );

      final now = DateTime.now();
      final dateOnly = DateTime(now.year, now.month, now.day);

      final entry = SleepEntry(
        id: '',
        sleepTime: sleepTime,
        wakeTime: wakeTime,
        durationHours: durationHours,
        score: score,
        date: dateOnly,
      );

      final docRef = await _db
          .userCollection(ZzenConstants.sleepEntriesCollection)
          .add(entry.toFirestore());

      return entry.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Log sleep error: $e');
      rethrow;
    }
  }

  /// Fetch the last 7 days of sleep entries, ordered by date descending
  Future<List<SleepEntry>> getLast7Days() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _db
          .userCollection(ZzenConstants.sleepEntriesCollection)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      return snapshot.docs
          .map((doc) => SleepEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Get last 7 days error: $e');
      return [];
    }
  }

  /// Get today's sleep entry if it exists
  Future<SleepEntry?> getTodayEntry() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _db
          .userCollection(ZzenConstants.sleepEntriesCollection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(tomorrow))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return SleepEntry.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('Get today entry error: $e');
      return null;
    }
  }

  /// Calculate total sleep debt for the last 7 days
  /// Debt = sum of (8 - actual hours) per day, minimum 0 per day
  Future<double> getSleepDebt() async {
    try {
      final entries = await getLast7Days();
      double debt = 0;
      for (final entry in entries) {
        final deficit = ZzenConstants.targetSleepHours - entry.durationHours;
        if (deficit > 0) debt += deficit;
      }
      return debt.clamp(0, ZzenConstants.maxSleepDebtHours);
    } catch (e) {
      debugPrint('Get sleep debt error: $e');
      return 0;
    }
  }

  /// Delete a sleep entry by ID
  Future<void> deleteEntry(String id) async {
    try {
      await _db
          .userCollection(ZzenConstants.sleepEntriesCollection)
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Delete entry error: $e');
    }
  }

  /// Calculate and update streak based on consecutive nights with all habits done
  Future<int> calculateAndUpdateStreak(
      List<bool> habitCompletionHistory) async {
    int streak = 0;
    for (final completed in habitCompletionHistory) {
      if (completed) {
        streak++;
      } else {
        break;
      }
    }
    await _db.updateStreak(streak);
    return streak;
  }
}
