import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Firebase auth instance
final fb.FirebaseAuth auth = fb.FirebaseAuth.instance;

/// Global variable for the app's current user.
AppUser? currentUser;

/// Returns true if a user is currently signed in.
bool get isLoggedIn => auth.currentUser != null;

/// Returns the current Firebase User.
fb.User? get firebaseUser => auth.currentUser;

/// Loads the extended user data from Firestore into [currentUser].
Future<void> loadUserFromFirestore(String uid) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

  if (snapshot.exists) {
    currentUser = AppUser.fromMap(snapshot.data()!);
  }
}
