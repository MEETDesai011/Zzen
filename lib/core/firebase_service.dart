// Firebase Service — Anonymous Auth + Firestore helpers
// Handles anonymous sign-in and provides centralised Firebase access.
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _uid;

  /// The current user's UID (set after signInAnonymously)
  String get uid => _uid ?? _auth.currentUser?.uid ?? '';

  FirebaseFirestore get firestore => _firestore;

  /// Sign in anonymously on first launch.
  /// UID is persisted in SharedPreferences so the same user is used across sessions.
  Future<void> signInAnonymously() async {
    try {
      final savedUid = await _secureStorage.read(key: ZzenConstants.prefUid);

      // Check if we already have a logged-in user
      if (_auth.currentUser != null) {
        _uid = _auth.currentUser!.uid;
        return;
      }

      // Sign in anonymously
      final credential = await _auth.signInAnonymously();
      _uid = credential.user?.uid;

      // Persist UID securely
      if (_uid != null) {
        await _secureStorage.write(key: ZzenConstants.prefUid, value: _uid!);
      }

      // Create user profile doc if it doesn't exist
      if (_uid != null && savedUid == null) {
        await _createUserProfile(_uid!);
      }
    } catch (e) {
      // If anonymous auth fails, continue — Firestore writes will fail gracefully
      if (kDebugMode) debugPrint('Anonymous auth error: $e');
    }
  }

  Future<void> _createUserProfile(String uid) async {
    try {
      final userDoc = _firestore.collection(ZzenConstants.usersCollection).doc(uid);
      final existing = await userDoc.get();
      if (!existing.exists) {
        await userDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'streakCount': 0,
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Profile creation error: $e');
    }
  }

  /// Get a Firestore collection reference under the current user
  CollectionReference<Map<String, dynamic>> userCollection(String collectionName) {
    return _firestore
        .collection(ZzenConstants.usersCollection)
        .doc(uid)
        .collection(collectionName);
  }

  /// Get user settings document reference
  DocumentReference<Map<String, dynamic>> get userSettingsDoc {
    return _firestore
        .collection(ZzenConstants.usersCollection)
        .doc(uid);
  }

  /// Update streak count in Firestore
  Future<void> updateStreak(int streak) async {
    try {
      await userSettingsDoc.update({'streakCount': streak});
    } catch (e) {
      if (kDebugMode) debugPrint('Streak update error: $e');
    }
  }

  /// Get current streak from Firestore
  Future<int> getStreak() async {
    try {
      final doc = await userSettingsDoc.get();
      if (doc.exists) {
        return (doc.data()?['streakCount'] as int?) ?? 0;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Get streak error: $e');
    }
    return 0;
  }
}
