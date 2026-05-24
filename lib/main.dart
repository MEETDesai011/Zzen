// Zzen App Entry Point
// SDG 3 Impact: This app as a whole is designed to improve sleep quality for
// Gen-Z users, directly contributing to SDG 3.4 (reduce premature mortality
// from non-communicable diseases linked to poor sleep health).
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise timezone data (required for scheduled notifications)
  tz.initializeTimeZones();

  // Initialise Firebase
  await Firebase.initializeApp();

  // Sign in anonymously — zero friction for users and hackathon judges
  await FirebaseService.instance.signInAnonymously();

  runApp(const ZzenApp());
}
