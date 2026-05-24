// Zzen App Constants
// Centralised app-wide constants for collection names, scoring, habits, etc.
class ZzenConstants {
  ZzenConstants._();

  // Firestore collection paths
  static const String usersCollection = 'users';
  static const String sleepEntriesCollection = 'sleep_entries';
  static const String habitLogsCollection = 'habit_logs';
  static const String weeklyReportsCollection = 'weekly_reports';
  static const String settingsDoc = 'settings';

  // Score calculation
  static const double targetSleepHours = 8.0;
  static const int consistencyBonusPoints = 10;
  static const int consistencyWindowMinutes = 30;
  static const int pointsPerHalfHourBelow = 10;
  static const int pointsPerHalfHourAbove = 5;
  static const double maxSleepDebtHours = 14.0; // 2 hrs/day × 7 days

  // Notification IDs
  static const int bedtimeNotificationId = 1001;
  static const int windDownNotificationId = 1002;
  static const int habitLogNotificationId = 1003;
  static const int smartAlarmNotificationId = 1004;

  // SharedPreferences keys
  static const String prefUid = 'uid';
  static const String prefBedtime = 'bedtime';
  static const String prefAlarmWindowStart = 'alarm_window_start';
  static const String prefAlarmWindowEnd = 'alarm_window_end';

  // Default wind-down habits
  static const List<String> defaultHabits = [
    'No phone 30 mins before bed',
    'Dim the lights',
    'No caffeine after 4 PM',
    'Read instead of scroll',
    'Deep breathing for 2 mins',
  ];

  // Sleep sound names and asset paths
  static const List<Map<String, String>> sleepSounds = [
    {
      'name': 'White Noise',
      'asset': 'assets/sounds/white_noise.mp3',
      'icon': '🤍',
      'description': 'Steady broadband static for focus',
    },
    {
      'name': 'Rain',
      'asset': 'assets/sounds/rain.mp3',
      'icon': '🌧️',
      'description': 'Gentle rainfall to calm the mind',
    },
    {
      'name': 'Ocean',
      'asset': 'assets/sounds/ocean.mp3',
      'icon': '🌊',
      'description': 'Rolling waves for deep relaxation',
    },
    {
      'name': 'Lo-Fi',
      'asset': 'assets/sounds/lofi.mp3',
      'icon': '🎵',
      'description': 'Chill beats for winding down',
    },
    {
      'name': 'Forest',
      'asset': 'assets/sounds/forest.mp3',
      'icon': '🌲',
      'description': 'Birds and nature for peaceful sleep',
    },
  ];

  // Gemini system prompt
  static const String geminiSystemPrompt = '''
You are Zzen, a friendly Gen-Z sleep coach. You speak in a casual, supportive tone — not clinical. You have access to the user's last 7 days of sleep data provided below. Analyse their patterns and give specific, actionable advice. Keep responses under 100 words. Never give medical advice. Use emojis occasionally.
''';

  // App metadata
  static const String appName = 'Zzen';
  static const String appTagline = 'sleep better. feel better.';
}
