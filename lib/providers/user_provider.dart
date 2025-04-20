import 'dart:core';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add FCM dependency
import '../models/app_user.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.dark;

  final Logger _logger = Logger();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => fb.FirebaseAuth.instance.currentUser != null;
  fb.User? get firebaseUser => fb.FirebaseAuth.instance.currentUser;
  ThemeMode get themeMode => _themeMode;

  UserProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
    });
  }

  void init() {
    fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? user) {
      if (user != null) {
        _logger.i("Auth state changed: User logged in with UID: ${user.uid}");
        loadUserData(user.uid);
        _refreshFcmToken(user.uid); // Refresh FCM token on login
      } else {
        _logger.i("Auth state changed: User logged out");
        _currentUser = null;
        _errorMessage = null;
        _isLoading = false;
        _isSaving = false;
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    });

    // Listen for FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (isLoggedIn && firebaseUser != null) {
        _logger.i("FCM token refreshed: $newToken");
        _updateFcmToken(firebaseUser!.uid, newToken);
      }
    });
  }

  Future<void> _refreshFcmToken(String uid) async {
    try {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _updateFcmToken(uid, fcmToken);
      }
    } catch (e) {
      _logger.e("Error refreshing FCM token: $e");
    }
  }

  Future<void> _updateFcmToken(String uid, String fcmToken) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': fcmToken,
      });
      if (_currentUser != null) {
        _currentUser!.fcmToken = fcmToken;
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error updating FCM token in Firestore: $e");
    }
  }

  Future<void> loadUserData(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        _currentUser = AppUser.fromMap(snapshot.data()!);
        _logger.i(
          "User data loaded from Firestore: ${_currentUser!.id}, Points: ${_currentUser!.points}",
        );
        _themeMode =
            _currentUser!.theme == 'light' ? ThemeMode.light : ThemeMode.dark;
      } else {
        _logger.w(
          "User document does not exist for UID: $uid. Creating default user document.",
        );
        final defaultUser = AppUser(
          id: uid,
          name: fb.FirebaseAuth.instance.currentUser?.displayName ?? "User",
          email: fb.FirebaseAuth.instance.currentUser?.email ?? "",
          avatar:
              fb.FirebaseAuth.instance.currentUser?.photoURL ??
              'assets/images/default_avatar_1.png',
          workoutsCompleted: 0,
          mealsTracked: 0,
          gender: "",
          age: "",
          height: "",
          weight: "",
          weightHistory: [],
          activityLevel: "",
          dietGoal: "",
          dietPreference: "",
          workoutGoal: "",
          experienceLevel: "",
          trainingStyle: "",
          availableEquipment: [],
          injuryHistory: [],
          workoutFrequency: 1,
          allergies: [],
          isAdmin: false,
          isPremium: false,
          premiumExpiryDate: null,
          autoRenew: false,
          activeWorkoutPrograms: [],
          activeDietPlans: [],
          joinedChallenges: [],
          activeChallengeId: null,
          joinedSideHustles: [],
          lastLogin: DateTime.now(),
          streak: 0,
          points: 0,
          badges: [],
          workoutHistory: [],
          mealHistory: [],
          theme: "dark",
          notifications: true,
          language: "en",
          createdAt: DateTime.now(),
          referrer: "",
          balance: 0.0,
          hydration: "",
          dietaryRestrictions: [],
          workoutFocus: [],
          workoutDuration: 30.0,
          intensity: "",
          availableDays: [],
          mealFrequency: 3,
          mealTimes: [],
          maxPushUps: null,
          maxPullUps: null,
          mileRunTime: null,
          medicalConditions: [],
          preferredWorkoutTimes: [],
          challengeCheckIns: [],
          challengeProgress: 0,
          dailyStepTarget: null,
          stepTargetHistory: [],
          dailyCalorieTarget: null,
          dailyProteinTarget: null,
          dailyCarbsTarget: null,
          dailyFatTarget: null,
          macroIntakeHistory: [],
          preferredWorkoutStyle: "",
          isBanned: false,
          notificationsEnabled: true,
          dailyReminderTime: "08:00",
          weeklyReminderTime: "09:00",
          fcmToken: await _messaging.getToken(),
          lastCheckIn: null,
          dailyAdsWatched: 0,
          lastAdsWatchedDate: null,
          hasBuiltPlans: false,
          hasClaimedBuildPlansReward: false,
          checkInStreak: 0,
          lastWorkoutCompletionDate: null,
          lastMealPlanCompletionDate: null,
          lastStepGoalCompletionDate: null,
          lastWeightUpdateDate: null,
          completedOneOffIds: [],
          lastAdWatchedTimestamp: null,
          claimedRewards: {},
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(defaultUser.toMap());
        _currentUser = defaultUser;
        _themeMode = ThemeMode.dark;
        _logger.i("Default user document created for UID: $uid");
      }
    } catch (e) {
      _logger.e("Error loading user data from Firestore: $e");
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserFields(Map<String, dynamic> updates) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    if (updates.isEmpty) {
      _errorMessage = "No updates provided";
      notifyListeners();
      return;
    }

    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      if (_currentUser != null) {
        final updatedMap = {..._currentUser!.toMap(), ...updates};
        _currentUser = AppUser.fromMap(updatedMap);
        if (updates.containsKey('theme')) {
          _themeMode =
              updates['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
        }
      }
      notifyListeners();
    } catch (e) {
      _logger.e("Error updating user data: $e");
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      _currentUser = updatedUser;
      _themeMode =
          updatedUser.theme == 'light' ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    } catch (e) {
      _logger.e("Error updating user data: $e");
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileFields({
    required String gender,
    required String age,
    required String height,
    required String weight,
    required String avatar,
  }) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      final updates = {
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'avatar': avatar,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      if (_currentUser != null) {
        final updatedMap = {..._currentUser!.toMap(), ...updates};
        _currentUser = AppUser.fromMap(updatedMap);
      }
      notifyListeners();
    } catch (e) {
      _logger.e("Error updating profile fields: $e");
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> claimReward(String taskId, int points, {String? badge}) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    try {
      final updates = {
        'points': FieldValue.increment(points),
        'claimedRewards.$taskId': {
          'claimed': true,
          'lastClaimed': FieldValue.serverTimestamp(),
        },
      };

      if (taskId == 'daily_check_in') {
        updates['lastCheckIn'] = FieldValue.serverTimestamp();
        updates['checkInStreak'] = FieldValue.increment(1);
      } else if (taskId == 'complete_workout') {
        updates['lastWorkoutCompletionDate'] = FieldValue.serverTimestamp();
        updates['workoutsCompleted'] = FieldValue.increment(1);
      } else if (taskId == 'complete_meal_plan') {
        updates['lastMealPlanCompletionDate'] = FieldValue.serverTimestamp();
        updates['mealsTracked'] = FieldValue.increment(1);
      } else if (taskId == 'daily_step_goal') {
        updates['lastStepGoalCompletionDate'] = FieldValue.serverTimestamp();
      } else if (taskId == 'update_weight') {
        updates['lastWeightUpdateDate'] = FieldValue.serverTimestamp();
        if (badge != null) {
          updates['badges'] = FieldValue.arrayUnion([badge]);
        }
      } else if ([
        'build_profile',
        'share_progress',
        'join_challenge',
        'complete_side_hustle',
      ].contains(taskId)) {
        updates['completedOneOffIds'] = FieldValue.arrayUnion([taskId]);
        if (badge != null) {
          updates['badges'] = FieldValue.arrayUnion([badge]);
        }
      } else if (taskId == 'watch_ad') {
        // Reward claiming handled separately, just increment points
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      if (_currentUser != null) {
        await loadUserData(firebaseUser!.uid);
      }
      notifyListeners();
    } catch (e) {
      _logger.e("Error claiming reward: $e");
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.day == date2.day &&
        date1.month == date2.month &&
        date1.year == date2.year;
  }

  Future<void> updateWeight(String weight) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now();
      final weightEntry = {
        'weight': weight,
        'timestamp': Timestamp.fromDate(now),
      };

      final updates = {
        'weight': weight,
        'weightHistory': FieldValue.arrayUnion([weightEntry]),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      if (_currentUser != null) {
        await loadUserData(firebaseUser!.uid);
      }
      notifyListeners();
    } catch (e) {
      _logger.e("Error updating weight: $e");
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(String newAvatar) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      throw Exception("User not logged in");
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update({'avatar': newAvatar});

      if (_currentUser != null) {
        _currentUser!.avatar = newAvatar;
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error updating avatar: $e");
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> uploadCustomAvatar(File image) async {
    if (!isLoggedIn || firebaseUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      throw Exception("User not logged in");
    }

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'avatars/${firebaseUser!.uid}.jpg',
      );
      await storageRef.putFile(image);
      final downloadUrl = await storageRef.getDownloadURL();

      await updateAvatar(downloadUrl);
    } catch (e) {
      _logger.e("Error uploading custom avatar: $e");
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    if (isLoggedIn && _currentUser != null) {
      await updateUserFields({
        'theme': mode == ThemeMode.light ? 'light' : 'dark',
      });
    }
  }
}
