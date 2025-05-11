// Merged and fixed auth_service implementation
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/post.dart';
import '../models/meal_plan.dart';
import '../models/workout_program.dart';
import '../services/cache_service.dart';

/// A fixed version of AuthService that properly uses the new CacheService
class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Helper method to preload cache data for better performance
  Future<void> preloadCacheForUser(AppUser user) async {
    try {
      // Load global cache data
      await CacheService().loadGlobalCache();

      // Load user-specific cache data if they have active programs
      if (user.activeWorkoutPrograms.isNotEmpty ||
          user.activeDietPlans.isNotEmpty) {
        await CacheService().loadUserCache(
          user.id,
          user.activeWorkoutPrograms,
          user.activeDietPlans,
        );
      }
    } catch (e) {
      // Don't fail if cache fails
      if (kDebugMode) {
        print("Warning: Cache preloading failed: $e");
      }
    }
  }

  Stream<User?> get authState => _auth.authStateChanges();

  bool get isLoggedIn => _auth.currentUser != null;

  User? get firebaseUser => _auth.currentUser;

  CollectionReference get usersRef => _firestore.collection('users');

  FirebaseFirestore get firestore => _firestore;

  Future<void> saveUser(AppUser user) async {
    await usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await usersRef.doc(userId).update(updates);
    await _awardBadges(userId); // Check for badges after updating user fields
  }

  Future<void> dailyCheckIn(
    String userId,
    int newStreak,
    int pointsToAward,
  ) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.update({
      'lastCheckIn': Timestamp.fromDate(DateTime.now()),
      'checkInStreak': newStreak,
      'points': FieldValue.increment(pointsToAward),
    });
  }

  Future<void> claimBuildPlansReward(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.update({
      'hasClaimedBuildPlansReward': true,
      'points': FieldValue.increment(10), // Award 10 points for building plans
    });
  }

  Future<void> watchAdForPoints(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final now = DateTime.now();
    await userDoc.update({
      'dailyAdsWatched': FieldValue.increment(1),
      'lastAdsWatchedDate': Timestamp.fromDate(now),
      'points': FieldValue.increment(2), // Award 2 points per ad
    });
  }

  Future<AppUser?> getAppUser(String userId) async {
    final doc = await usersRef.doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Ensures the user is ready (logged in, email verified).
  /// Returns true if the user is ready, false otherwise.
  Future<bool> ensureUserIsReady() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
      throw Exception("Please verify your email to continue.");
    }

    return true;
  }

  // Fetch a MealPlan by dietPlanId, ensuring it matches the user's ID
  Future<MealPlan?> getMealPlan(String dietPlanId, String userId) async {
    final doc = await _firestore.collection('meal_plans').doc(dietPlanId).get();
    if (doc.exists) {
      final mealPlan = MealPlan.fromMap(doc.data()!);
      // Only return the meal plan if userId matches the current user's ID
      if (mealPlan.userId == userId) {
        return mealPlan;
      }
    }
    return null;
  }

  // Fetch a WorkoutProgram by workoutProgramId, ensuring it matches the user's ID
  Future<WorkoutProgram?> getWorkoutProgram(
    String workoutProgramId,
    String userId,
  ) async {
    final doc =
        await _firestore
            .collection('workout_programs')
            .doc(workoutProgramId)
            .get();
    if (doc.exists) {
      final workoutProgram = WorkoutProgram.fromMap(doc.data()!, doc.id);
      // Only return the workout program if userId matches the current user's ID
      if (workoutProgram.userId == userId) {
        return workoutProgram;
      }
    }
    return null;
  }

  Future<User?> signUp(String email, String password, String name) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.sendEmailVerification();

        String? fcmToken;
        try {
          fcmToken = await _messaging.getToken();
        } catch (e) {
          // If FCM token retrieval fails, proceed without it
          fcmToken = null;
        }

        final appUser = AppUser(
          id: user.uid,
          name: name,
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
          notificationsEnabled: true,
          dailyReminderTime: "08:00",
          weeklyReminderTime: "09:00",
          fcmToken: fcmToken,
          dietaryRestrictions: [],
          workoutFocus: [],
          workoutDuration: 30.0,
          availableDays: [],
          mealFrequency: 3,
          mealTimes: [],
          medicalConditions: [],
          stepTargetHistory: [],
          macroIntakeHistory: [],
          isBanned: false,
        );

        await saveUser(appUser);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("This email is already registered. Please sign in.");
      } else if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please try again later.");
      }
      throw Exception("Registration failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during registration: $e");
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = result.user;

      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          throw Exception("Please verify your email to continue.");
        }

        String? fcmToken;
        try {
          fcmToken = await _messaging.getToken();
        } catch (e) {
          // If FCM token retrieval fails, proceed without it
          fcmToken = null;
        }

        await updateUserFields(user.uid, {
          'lastLogin': DateTime.now().toIso8601String(),
          'fcmToken': fcmToken, // Will be null if retrieval failed
        });

        // Preload cache data for better performance
        final appUser = await getAppUser(user.uid);
        if (appUser != null) {
          await preloadCacheForUser(appUser);
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please try again later.");
      }
      throw Exception("Sign in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during sign in: $e");
    }
  }

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final User? user = result.user;

      if (user != null) {
        final existingUser = await getAppUser(user.uid);
        String? fcmToken;
        try {
          fcmToken = await _messaging.getToken();
        } catch (e) {
          // If FCM token retrieval fails, proceed without it
          fcmToken = null;
        }

        if (existingUser == null) {
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
            notificationsEnabled: true,
            dailyReminderTime: "08:00",
            weeklyReminderTime: "09:00",
            fcmToken: fcmToken,
            dietaryRestrictions: [],
            workoutFocus: [],
            workoutDuration: 30.0,
            availableDays: [],
            mealFrequency: 3,
            mealTimes: [],
            medicalConditions: [],
            stepTargetHistory: [],
            macroIntakeHistory: [],
            isBanned: false,
          );
          await saveUser(appUser);
        } else {
          await updateUserFields(user.uid, {
            'lastLogin': DateTime.now().toIso8601String(),
            'fcmToken': fcmToken,
          });

          // Preload cache data for better performance
          await preloadCacheForUser(existingUser);
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please try again later.");
      }
      throw Exception("Google sign-in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during Google sign-in: $e");
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential result = await _auth.signInWithCredential(
        oauthCredential,
      );
      final User? user = result.user;

      if (user != null) {
        final existingUser = await getAppUser(user.uid);
        String? fcmToken;
        try {
          fcmToken = await _messaging.getToken();
        } catch (e) {
          // If FCM token retrieval fails, proceed without it
          fcmToken = null;
        }

        if (existingUser == null) {
          final appUser = AppUser(
            id: user.uid,
            name: appleCredential.givenName ?? user.displayName ?? '',
            email: appleCredential.email ?? user.email ?? '',
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
            notificationsEnabled: true,
            dailyReminderTime: "08:00",
            weeklyReminderTime: "09:00",
            fcmToken: fcmToken,
            dietaryRestrictions: [],
            workoutFocus: [],
            workoutDuration: 30.0,
            availableDays: [],
            mealFrequency: 3,
            mealTimes: [],
            medicalConditions: [],
            stepTargetHistory: [],
            macroIntakeHistory: [],
            isBanned: false,
          );
          await saveUser(appUser);
        } else {
          await updateUserFields(user.uid, {
            'lastLogin': DateTime.now().toIso8601String(),
            'fcmToken': fcmToken,
          });

          // Preload cache data for better performance
          await preloadCacheForUser(existingUser);
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please try again later.");
      }
      throw Exception("Apple sign-in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during Apple sign-in: $e");
    }
  }

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();
      if (loginResult.status != LoginStatus.success) return null;

      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

      final UserCredential result = await _auth.signInWithCredential(
        facebookAuthCredential,
      );
      final User? user = result.user;

      if (user != null) {
        final existingUser = await getAppUser(user.uid);
        String? fcmToken;
        try {
          fcmToken = await _messaging.getToken();
        } catch (e) {
          // If FCM token retrieval fails, proceed without it
          fcmToken = null;
        }

        if (existingUser == null) {
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
            notificationsEnabled: true,
            dailyReminderTime: "08:00",
            weeklyReminderTime: "09:00",
            fcmToken: fcmToken,
            dietaryRestrictions: [],
            workoutFocus: [],
            workoutDuration: 30.0,
            availableDays: [],
            mealFrequency: 3,
            mealTimes: [],
            medicalConditions: [],
            stepTargetHistory: [],
            macroIntakeHistory: [],
            isBanned: false,
          );
          await saveUser(appUser);
        } else {
          await updateUserFields(user.uid, {
            'lastLogin': DateTime.now().toIso8601String(),
            'fcmToken': fcmToken,
          });

          // Preload cache data for better performance
          await preloadCacheForUser(existingUser);
        }
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception("Too many attempts. Please try again later.");
      }
      throw Exception("Facebook sign-in failed: ${e.message}");
    } catch (e) {
      throw Exception("An unknown error occurred during Facebook sign-in: $e");
    }
  }

  Future<void> signOut() async {
    try {
      try {
        await _auth.signOut();
      } catch (e) {
        throw Exception("Failed to sign out from Firebase Authentication: $e");
      }
    } catch (e) {
      throw Exception("Failed to sign out: $e");
    }
  }

  Future<void> markMealAsDone(String userId, String mealId) async {
    DateTime.now().toIso8601String();
    await updateUserFields(userId, {
      'mealsTracked': FieldValue.increment(1),
      'mealHistory': FieldValue.arrayUnion([mealId]),
      'points': FieldValue.increment(5), // 5 points for marking a meal as done
    });
  }

  Future<void> markWorkoutAsDone(String userId, String workoutId) async {
    DateTime.now().toIso8601String();
    await updateUserFields(userId, {
      'workoutsCompleted': FieldValue.increment(1),
      'workoutHistory': FieldValue.arrayUnion([workoutId]),
      'points': FieldValue.increment(
        10,
      ), // 10 points for marking a workout as done
    });
  }

  // COMMUNITY FEED METHODS

  Future<void> createPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    String? imageUrl,
    String? workoutId,
  }) async {
    final post = Post(
      id: const Uuid().v4(),
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
      workoutId: workoutId,
    );

    await _firestore.collection('posts').doc(post.id).set(post.toMap());

    // Award points for creating a post
    await updateUserFields(userId, {
      'points': FieldValue.increment(5), // 5 points for creating a post
    });
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    if (postDoc.exists) {
      final post = Post.fromMap(postDoc.data() as Map<String, dynamic>);
      final postOwner = await getAppUser(post.userId);
      if (postOwner != null &&
          postOwner.id != userId &&
          postOwner.notificationsEnabled &&
          postOwner.fcmToken != null) {}
    }

    // Award points for liking a post
    await updateUserFields(userId, {
      'points': FieldValue.increment(2), // 2 points for liking a post
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> addComment(
    String postId,
    String userId,
    String userName,
    String content,
  ) async {
    final comment = {
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([comment]),
    });

    // Award points for commenting on a post
    await updateUserFields(userId, {
      'points': FieldValue.increment(3), // 3 points for commenting on a post
    });
  }

  Future<void> reportPost(String postId, String userId, String reason) async {
    await _firestore.collection('reported_posts').doc(postId).set({
      'postId': postId,
      'reportedBy': userId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  // ADMIN DASHBOARD METHODS

  Future<void> banUser(String userId) async {
    await updateUserFields(userId, {'isBanned': true});
  }

  Future<void> unbanUser(String userId) async {
    await updateUserFields(userId, {'isBanned': false});
  }

  Future<void> dismissFlag(String userId) async {
    await _firestore.collection('flagged_users').doc(userId).delete();
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
    await _firestore.collection('reported_posts').doc(postId).delete();
  }

  Future<void> dismissReportedPost(String postId) async {
    await _firestore.collection('reported_posts').doc(postId).delete();
  }

  // Helper method to award badges based on user activity
  Future<void> _awardBadges(String userId) async {
    final user = await getAppUser(userId);
    if (user == null) return;

    List<String> updatedBadges = List.from(user.badges ?? []);

    // Check for "Consistent" badge: Achieve a streak of 7 days
    if ((user.streak ?? 0) >= 7 && !updatedBadges.contains("Consistent")) {
      updatedBadges.add("Consistent");
    }

    // Check for "Social Butterfly" badge: Create 5 posts
    final postsSnapshot =
        await _firestore
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();
    if (postsSnapshot.docs.length >= 5 &&
        !updatedBadges.contains("Social Butterfly")) {
      updatedBadges.add("Social Butterfly");
    }

    // Check for "Engager" badge: Like or comment on 10 posts
    int engagementCount = 0;
    final allPostsSnapshot = await _firestore.collection('posts').get();
    for (var doc in allPostsSnapshot.docs) {
      final post = Post.fromMap(doc.data());
      if (post.likes.contains(userId)) {
        engagementCount++;
      }
      if (post.comments.any((comment) => comment['userId'] == userId)) {
        engagementCount++;
      }
    }
    if (engagementCount >= 10 && !updatedBadges.contains("Engager")) {
      updatedBadges.add("Engager");
    }

    // Check for "Point Master" badge: Earn 500 points
    if ((user.points ?? 0) >= 500 && !updatedBadges.contains("Point Master")) {
      updatedBadges.add("Point Master");
    }

    // Check for "Meal Tracker" badge: Track 10 meals
    if ((user.mealsTracked) >= 10 && !updatedBadges.contains("Meal Tracker")) {
      updatedBadges.add("Meal Tracker");
    }

    // Check for "Workout Warrior" badge: Complete 10 workouts
    if ((user.workoutsCompleted) >= 10 &&
        !updatedBadges.contains("Workout Warrior")) {
      updatedBadges.add("Workout Warrior");
    }

    // Update the user's badges if any new ones were awarded
    if (updatedBadges.length != (user.badges?.length ?? 0)) {
      await updateUserFields(userId, {'badges': updatedBadges});
    }
  }
}
