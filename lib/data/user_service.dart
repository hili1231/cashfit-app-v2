import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final CollectionReference usersRef = _firestore.collection('users');

  /// Save new user or overwrite existing user data
  static Future<void> saveUser(AppUser user) async {
    await usersRef.doc(user.id).set(user.toMap());
  }

  /// Update user partially (only selected fields)
  static Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await usersRef.doc(userId).update(updates);
  }

  /// Fetch user by ID
  static Future<AppUser?> getUserById(String userId) async {
    final doc = await usersRef.doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  /// Delete user (if needed)
  static Future<void> deleteUser(String userId) async {
    await usersRef.doc(userId).delete();
  }
}
