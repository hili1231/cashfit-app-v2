import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../auth/login_screen.dart';

class AuthService {
  // Singleton setup
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extended user data loaded from Firestore.
  AppUser? currentUser;

  /// Stream of Firebase Auth user state.
  Stream<User?> get authState => _auth.authStateChanges();

  /// Returns true if a user is currently signed in.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Returns the current Firebase User.
  User? get firebaseUser => _auth.currentUser;

  /// Collection reference for 'users'
  CollectionReference get usersRef => _firestore.collection('users');

  /// Save new user or merge with existing data.
  Future<void> saveUser(AppUser user) async {
    await usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  /// Update user partially (only selected fields)
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await usersRef.doc(userId).update(updates);
  }

  /// Fetch extended user data from Firestore.
  Future<AppUser?> getAppUser(String userId) async {
    final doc = await usersRef.doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Loads the extended user data into [currentUser].
  Future<void> loadUserFromFirestore(String uid) async {
    final snapshot = await usersRef.doc(uid).get();
    if (snapshot.exists) {
      currentUser = AppUser.fromMap(snapshot.data() as Map<String, dynamic>);
    }
  }

  /// Ensures a user is logged in and extended data is loaded.
  Future<bool> ensureUserIsReady(BuildContext context) async {
    final user = _auth.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }

    if (currentUser == null || currentUser?.id.isEmpty == true) {
      await loadUserFromFirestore(user.uid);
    }

    if (currentUser == null || currentUser?.id.isEmpty == true) {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }

    return true;
  }

  /// SIGN UP & CREATE USER IN FIRESTORE
  Future<User?> signUp(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = result.user;
      if (user != null) {
        final appUser = AppUser(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          avatar: user.photoURL ?? 'assets/images/avatar.png',
          workoutsCompleted: 0,
          mealsTracked: 0,
          gender: '',
          age: '',
          height: '',
          weight: '',
          activityLevel: '',
          dietGoal: '',
          dietPreference: '',
          workoutGoal: '',
          experienceLevel: '',
          trainingStyle: '',
          availableEquipment: [],
          injuryHistory: [],
          workoutFrequency: 0,
          allergies: [],
          isAdmin: false,
          isPremium: false,
          activeWorkoutPrograms: [],
          activeDietPlans: [],
          joinedChallenges: [],
          joinedSideHustles: [],
          lastLogin: DateTime.now(),
          streak: 0,
          points: 0,
          badges: [],
          workoutHistory: [],
          mealHistory: [],
          theme: null,
          notifications: true,
          language: 'en',
          createdAt: DateTime.now(),
          referrer: '',
          balance: 0.0,
        );

        await saveUser(appUser);
        await loadUserFromFirestore(user.uid);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Registration failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during registration: $e");
    }
  }

  /// SIGN IN (No overwrite on Firestore)
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user;

      if (user != null) {
        await updateUserFields(user.uid, {
          'lastLogin': DateTime.now().toIso8601String(),
        });
        await loadUserFromFirestore(user.uid);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Sign in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during sign in: $e");
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    currentUser = null;
    await _auth.signOut();
  }
}
