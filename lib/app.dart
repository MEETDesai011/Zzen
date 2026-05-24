// Zzen App Root — MaterialApp, routes, theme, bottom navigation
// SDG 3 Impact: Central navigation hub connecting all 10 sleep health features,
// making holistic wellbeing tools accessible to Gen-Z users.
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/log_sleep_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/sounds_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/report_screen.dart';

class ZzenApp extends StatelessWidget {
  const ZzenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zzen',
      debugShowCheckedModeBanner: false,
      theme: ZzenTheme.darkTheme,
      home: const MainNavigator(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/log': (context) => const LogSleepScreen(),
        '/coach': (context) => const CoachScreen(),
        '/sounds': (context) => const SoundsScreen(),
        '/insights': (context) => const InsightsScreen(),
        '/habits': (context) => const HabitsScreen(),
        '/alarm': (context) => const AlarmScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/report': (context) => const ReportScreen(),
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LogSleepScreen(),
    CoachScreen(),
    SoundsScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF7C6FEA),
        unselectedItemColor: const Color(0xFF4A4A5A),
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime_rounded),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_rounded),
            label: 'Sounds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
