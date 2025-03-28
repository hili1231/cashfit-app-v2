import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart'; // Make sure the path is correct

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  /// 🔐 SIGN UP & CREATE USER IN FIRESTORE
  Future<User?> signUp(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        final appUser = AppUser(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          avatar: user.photoURL ?? '',
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
          workoutFrequency: 3,
          allergies: [],
          isAdmin: false, activeWorkoutPrograms: [], activeDietPlans: [], // default value
        );

        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  /// 🔓 SIGN IN (No overwrite on Firestore)
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 📦 Fetch custom user model from Firestore
  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }
}
