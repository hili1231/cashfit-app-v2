import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart'; // Make sure the path is correct

class AuthService {
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
  CollectionReference get usersRef => _firestore.collection('users');

  /// Save new user or overwrite existing user data
  Future<void> saveUser(AppUser user) async {
    await usersRef.doc(user.id).set(user.toMap());
  }

  /// Update user partially (only selected fields)
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await usersRef.doc(userId).update(updates);
  }

  /// Fetch user by ID
  Future<AppUser?> getUserById(String userId) async {
    final doc = await usersRef.doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  /// Loads the extended user data from Firestore into [currentUser].
  Future<void> loadUserFromFirestore(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (snapshot.exists) {
      currentUser = AppUser.fromMap(snapshot.data()!);
    }
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
        // Optionally, send email verification:
        // await user.sendEmailVerification();

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

        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        // Load extended user data into currentUser.
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
      if (result.user != null) {
        await loadUserFromFirestore(result.user!.uid);
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception("Sign in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during sign in: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// FETCH custom user model from Firestore.
  Future<AppUser?> getAppUser(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to fetch user data: $e");
    }
  }
}
