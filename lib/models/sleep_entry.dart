// Sleep Entry Data Model
// Represents a single night's sleep log with computed score.
// SDG 3: Tracking sleep duration and quality metrics supports evidence-based
// health improvements aligned with SDG 3.4.
import 'package:cloud_firestore/cloud_firestore.dart';

class SleepEntry {
  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final double durationHours;
  final int score;
  final DateTime date;

  const SleepEntry({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.durationHours,
    required this.score,
    required this.date,
  });

  /// Create from Firestore document
  factory SleepEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SleepEntry(
      id: doc.id,
      sleepTime: (data['sleepTime'] as Timestamp).toDate(),
      wakeTime: (data['wakeTime'] as Timestamp).toDate(),
      durationHours: (data['durationHours'] as num).toDouble(),
      score: data['score'] as int,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'sleepTime': Timestamp.fromDate(sleepTime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'durationHours': durationHours,
      'score': score,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  SleepEntry copyWith({
    String? id,
    DateTime? sleepTime,
    DateTime? wakeTime,
    double? durationHours,
    int? score,
    DateTime? date,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationHours: durationHours ?? this.durationHours,
      score: score ?? this.score,
      date: date ?? this.date,
    );
  }

  @override
  String toString() =>
      'SleepEntry(id: $id, date: $date, duration: ${durationHours}h, score: $score)';
}
