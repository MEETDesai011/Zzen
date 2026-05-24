// Habits Screen — Feature 4: Wind Down Routine + Feature 8: Habit Logger
// SDG 3 Impact: Building consistent pre-sleep routines and tracking lifestyle
// habits directly improves sleep quality and mental health (SDG 3.4).
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/firebase_service.dart';
import '../models/habit_log.dart';
import '../widgets/habit_tile.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Wind Down state (Feature 4)
  Map<String, bool> _habits = {};
  int _streak = 0;

  // Habit Logger state (Feature 8)
  int _coffees = 0;
  bool _exercise = false;
  int _stressLevel = 3;
  TimeOfDay? _lastCoffeeTime;
  bool _saving = false;
  String? _coffeeInsight;

  final String _todayId = HabitLog.dateToId(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initHabits();
    _loadTodayLog();
    _loadStreak();
    _loadCoffeeInsight();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initHabits() {
    for (final habit in ZzenConstants.defaultHabits) {
      _habits[habit] = false;
    }
  }

  Future<void> _loadTodayLog() async {
    try {
      final doc = await FirebaseService.instance
          .userCollection(ZzenConstants.habitLogsCollection)
          .doc(_todayId)
          .get();
      if (doc.exists) {
        final log = HabitLog.fromFirestore(doc);
        setState(() {
          _habits = Map<String, bool>.from(log.windDownHabits);
          _coffees = log.coffees;
          _exercise = log.exercise;
          _stressLevel = log.stressLevel;
          _lastCoffeeTime = log.lastCoffeeTime != null
              ? TimeOfDay.fromDateTime(log.lastCoffeeTime!)
              : null;
        });
      }
    } catch (e) {
      // No existing log — use defaults
    }
  }

  Future<void> _loadStreak() async {
    final s = await FirebaseService.instance.getStreak();
    setState(() => _streak = s);
  }

  Future<void> _loadCoffeeInsight() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await FirebaseService.instance
          .userCollection(ZzenConstants.habitLogsCollection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (snapshot.docs.length < 7) return;

      // Days with coffee after 4 PM
      int lateCoffeeDays = 0;
      double totalScoreLateCoffee = 0;
      double totalScoreNormal = 0;
      int normalDays = 0;

      for (final doc in snapshot.docs) {
        final log = HabitLog.fromFirestore(doc);
        if (log.lastCoffeeTime != null) {
          final coffeeHour = log.lastCoffeeTime!.hour;
          if (coffeeHour >= 16) {
            lateCoffeeDays++;
            totalScoreLateCoffee += log.stressLevel; // Use as proxy
          } else {
            normalDays++;
            totalScoreNormal += log.stressLevel;
          }
        }
      }

      if (lateCoffeeDays > 0 && normalDays > 0) {
        final avgLate = totalScoreLateCoffee / lateCoffeeDays;
        final avgNormal = totalScoreNormal / normalDays;
        setState(() {
          _coffeeInsight = 'On days you had coffee after 4 PM, your stress averaged ${avgLate.toStringAsFixed(1)} vs ${avgNormal.toStringAsFixed(1)} on other days';
        });
      }
    } catch (e) {
      // Not enough data yet
    }
  }

  Future<void> _toggleHabit(String habit, bool value) async {
    setState(() => _habits[habit] = value);
    await _saveWindDown();
  }

  Future<void> _saveWindDown() async {
    try {
      final allDone = _habits.values.every((v) => v);
      final log = HabitLog(
        id: _todayId,
        date: DateTime.now(),
        coffees: _coffees,
        exercise: _exercise,
        stressLevel: _stressLevel,
        lastCoffeeTime: _lastCoffeeTime != null
            ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
                _lastCoffeeTime!.hour, _lastCoffeeTime!.minute)
            : null,
        windDownHabits: _habits,
        allHabitsCompleted: allDone,
      );
      await FirebaseService.instance
          .userCollection(ZzenConstants.habitLogsCollection)
          .doc(_todayId)
          .set(log.toFirestore());

      // Update streak if all habits done
      if (allDone) {
        final newStreak = _streak + 1;
        await FirebaseService.instance.updateStreak(newStreak);
        setState(() => _streak = newStreak);
      }
    } catch (e) {
      debugPrint('Save wind down error: $e');
    }
  }

  Future<void> _saveHabitLog() async {
    setState(() => _saving = true);
    try {
      await _saveWindDown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Habits logged! 📝'),
          backgroundColor: ZzenTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to save habits.'),
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
    return Scaffold(
      backgroundColor: ZzenTheme.background,
      appBar: AppBar(
        title: const Text('Habits'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ZzenTheme.primary,
          labelColor: ZzenTheme.primary,
          unselectedLabelColor: ZzenTheme.textMuted,
          tabs: const [
            Tab(text: 'Wind Down'),
            Tab(text: 'Daily Log'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWindDownTab(),
          _buildHabitLogTab(),
        ],
      ),
    );
  }

  Widget _buildWindDownTab() {
    final completed = _habits.values.where((v) => v).length;
    final total = _habits.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFF6B35).withOpacity(0.2), const Color(0xFFFF6B35).withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_streak day streak', style: const TextStyle(
                        color: Color(0xFFFF6B35), fontSize: 22, fontWeight: FontWeight.w900)),
                    const Text('consecutive nights completed', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tonight\'s Routine', style: TextStyle(
                  color: ZzenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              Text('$completed/$total', style: const TextStyle(color: ZzenTheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            backgroundColor: ZzenTheme.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(ZzenTheme.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          ...ZzenConstants.defaultHabits.map((habit) => HabitTile(
            habit: habit,
            isCompleted: _habits[habit] ?? false,
            onToggle: (v) => _toggleHabit(habit, v),
          )),
          if (completed == total && total > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZzenTheme.scoreGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZzenTheme.scoreGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text('All habits done! Sleep well tonight 🌙',
                      style: TextStyle(color: ZzenTheme.scoreGreen, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_coffeeInsight != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZzenTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZzenTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('☕', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_coffeeInsight!,
                      style: const TextStyle(color: ZzenTheme.warning, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Coffees stepper
          _buildSection('☕ Coffees Today', _buildCoffeeStepper()),
          const SizedBox(height: 16),
          // Last coffee time
          _buildSection('🕐 Last Coffee Time', _buildLastCoffeeTime()),
          const SizedBox(height: 16),
          // Exercise toggle
          _buildSection('🏃 Exercise Today', _buildExerciseToggle()),
          const SizedBox(height: 16),
          // Stress slider
          _buildSection('😤 Stress Level', _buildStressSlider()),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveHabitLog,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Today\'s Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZzenTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZzenTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: ZzenTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildCoffeeStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _coffees > 0 ? () => setState(() => _coffees--) : null,
          icon: const Icon(Icons.remove_circle_outline, color: ZzenTheme.primary),
        ),
        Text('$_coffees', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: ZzenTheme.textPrimary)),
        IconButton(
          onPressed: _coffees < 5 ? () => setState(() => _coffees++) : null,
          icon: const Icon(Icons.add_circle_outline, color: ZzenTheme.primary),
        ),
        const Text('cups', style: TextStyle(color: ZzenTheme.textMuted)),
      ],
    );
  }

  Widget _buildLastCoffeeTime() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _lastCoffeeTime ?? const TimeOfDay(hour: 14, minute: 0),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: ZzenTheme.primary, surface: ZzenTheme.surfaceVariant),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _lastCoffeeTime = picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: ZzenTheme.textMuted, size: 20),
          const SizedBox(width: 8),
          Text(
            _lastCoffeeTime != null ? _lastCoffeeTime!.format(context) : 'Tap to set',
            style: TextStyle(
              color: _lastCoffeeTime != null ? ZzenTheme.textPrimary : ZzenTheme.textMuted,
              fontWeight: FontWeight.w600, fontSize: 16,
            ),
          ),
          if (_lastCoffeeTime != null && _lastCoffeeTime!.hour >= 16) ...[
            const SizedBox(width: 8),
            const Text('⚠️ Late caffeine!', style: TextStyle(color: ZzenTheme.warning, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_exercise ? 'Yes! 💪' : 'No exercise today', style: TextStyle(
          color: _exercise ? ZzenTheme.scoreGreen : ZzenTheme.textSecondary, fontWeight: FontWeight.w500,
        )),
        Switch(
          value: _exercise,
          onChanged: (v) => setState(() => _exercise = v),
        ),
      ],
    );
  }

  Widget _buildStressSlider() {
    final labels = ['', 'Very Low', 'Low', 'Medium', 'High', 'Very High'];
    return Column(
      children: [
        Slider(
          value: _stressLevel.toDouble(),
          min: 1, max: 5, divisions: 4,
          label: labels[_stressLevel],
          onChanged: (v) => setState(() => _stressLevel = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('1 - Chill', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
            Text('5 - Stressed', style: TextStyle(color: ZzenTheme.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
