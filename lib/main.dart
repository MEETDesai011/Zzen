import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise timezone data (required for scheduled notifications)
  tz.initializeTimeZones();

  // Initialise environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env: $e. Using compile-time fallbacks.");
  }

  // Initialise Firebase
  await Firebase.initializeApp();

  // Determine starting screen based on auth state
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Widget initialScreen = currentUser != null
      ? const MainNavigator()
      : const LoginScreen();

  runApp(ZzenApp(homeScreen: initialScreen));
}
