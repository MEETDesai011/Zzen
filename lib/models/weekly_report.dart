// Weekly Report Data Model
// Represents the generated weekly wellbeing report card.
// SDG 3: Weekly summaries provide users with actionable insights to improve
// long-term sleep health and mental wellbeing (SDG 3.4).
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyReport {
  final String id; // week identifier e.g. "2024-W23"
  final DateTime weekStart;
  final DateTime weekEnd;
  final double avgScore;
  final DateTime? bestNightDate;
  final int bestNightScore;
  final DateTime? worstNightDate;
  final int worstNightScore;
  final double sleepDebtHours;
  final String aiInsight;
  final int streakCount;
  final DateTime generatedAt;

  const WeeklyReport({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.avgScore,
    this.bestNightDate,
    required this.bestNightScore,
    this.worstNightDate,
    required this.worstNightScore,
    required this.sleepDebtHours,
    required this.aiInsight,
    required this.streakCount,
    required this.generatedAt,
  });

  factory WeeklyReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WeeklyReport(
      id: doc.id,
      weekStart: (data['weekStart'] as Timestamp).toDate(),
      weekEnd: (data['weekEnd'] as Timestamp).toDate(),
      avgScore: (data['avgScore'] as num).toDouble(),
      bestNightDate: data['bestNightDate'] != null
          ? (data['bestNightDate'] as Timestamp).toDate()
          : null,
      bestNightScore: (data['bestNightScore'] as int?) ?? 0,
      worstNightDate: data['worstNightDate'] != null
          ? (data['worstNightDate'] as Timestamp).toDate()
          : null,
      worstNightScore: (data['worstNightScore'] as int?) ?? 0,
      sleepDebtHours: (data['sleepDebtHours'] as num).toDouble(),
      aiInsight: (data['aiInsight'] as String?) ?? '',
      streakCount: (data['streakCount'] as int?) ?? 0,
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weekStart': Timestamp.fromDate(weekStart),
      'weekEnd': Timestamp.fromDate(weekEnd),
      'avgScore': avgScore,
      'bestNightDate':
          bestNightDate != null ? Timestamp.fromDate(bestNightDate!) : null,
      'bestNightScore': bestNightScore,
      'worstNightDate':
          worstNightDate != null ? Timestamp.fromDate(worstNightDate!) : null,
      'worstNightScore': worstNightScore,
      'sleepDebtHours': sleepDebtHours,
      'aiInsight': aiInsight,
      'streakCount': streakCount,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  /// Generate a week ID like "2024-W23"
  static String weekId(DateTime date) {
    final weekNum = _isoWeekNumber(date);
    return '${date.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  static int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
