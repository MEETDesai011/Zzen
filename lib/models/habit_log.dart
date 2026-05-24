// Habit Log Data Model
// Represents daily habit tracking including caffeine intake, exercise, and stress.
// SDG 3: Monitoring lifestyle habits correlated with sleep supports preventive
// health behaviours (SDG 3.4).
import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  final String id; // YYYY-MM-DD date string
  final DateTime date;
  final int coffees; // 0–5
  final bool exercise;
  final int stressLevel; // 1–5
  final DateTime? lastCoffeeTime;
  final Map<String, bool> windDownHabits; // habit name → completed
  final bool allHabitsCompleted;

  const HabitLog({
    required this.id,
    required this.date,
    required this.coffees,
    required this.exercise,
    required this.stressLevel,
    this.lastCoffeeTime,
    required this.windDownHabits,
    required this.allHabitsCompleted,
  });

  factory HabitLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final habits = (data['windDownHabits'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as bool)) ??
        {};
    return HabitLog(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      coffees: (data['coffees'] as int?) ?? 0,
      exercise: (data['exercise'] as bool?) ?? false,
      stressLevel: (data['stressLevel'] as int?) ?? 1,
      lastCoffeeTime: data['lastCoffeeTime'] != null
          ? (data['lastCoffeeTime'] as Timestamp).toDate()
          : null,
      windDownHabits: habits,
      allHabitsCompleted: (data['allHabitsCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'coffees': coffees,
      'exercise': exercise,
      'stressLevel': stressLevel,
      'lastCoffeeTime':
          lastCoffeeTime != null ? Timestamp.fromDate(lastCoffeeTime!) : null,
      'windDownHabits': windDownHabits,
      'allHabitsCompleted': allHabitsCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  HabitLog copyWith({
    String? id,
    DateTime? date,
    int? coffees,
    bool? exercise,
    int? stressLevel,
    DateTime? lastCoffeeTime,
    Map<String, bool>? windDownHabits,
    bool? allHabitsCompleted,
  }) {
    return HabitLog(
      id: id ?? this.id,
      date: date ?? this.date,
      coffees: coffees ?? this.coffees,
      exercise: exercise ?? this.exercise,
      stressLevel: stressLevel ?? this.stressLevel,
      lastCoffeeTime: lastCoffeeTime ?? this.lastCoffeeTime,
      windDownHabits: windDownHabits ?? this.windDownHabits,
      allHabitsCompleted: allHabitsCompleted ?? this.allHabitsCompleted,
    );
  }

  /// Format date as document ID (YYYY-MM-DD)
  static String dateToId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
