import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
        _refreshFcmToken(user.uid);
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

    _supportsFcm.then((enabled) {
      if (!enabled) return;
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (isLoggedIn && firebaseUser != null) {
          _logger.i('FCM token refreshed: $token');
          _updateFcmToken(firebaseUser!.uid, token);
        }
      });
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

  Future<void> loadUserData(String uid, {bool silent = false}) async {
    try {
      if (!silent) {
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();
      }

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
          fcmToken: await _safeFcmToken(),
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
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshUser() async =>
      loadUserData(firebaseUser!.uid, silent: true);

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
    required String name,
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
        'name': name,
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

  Future<void> updateStreak() async {
    if (!isLoggedIn || firebaseUser == null || _currentUser == null) {
      _errorMessage = "User not logged in";
      notifyListeners();
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? lastActivityDate;

      // Determine the most recent activity date
      final activityDates =
          [
            _currentUser!.lastCheckIn,
            _currentUser!.lastWorkoutCompletionDate,
            _currentUser!.lastMealPlanCompletionDate,
            _currentUser!.lastStepGoalCompletionDate,
          ].where((date) => date != null).toList();

      if (activityDates.isNotEmpty) {
        lastActivityDate = activityDates.reduce(
          (a, b) => a!.isAfter(b!) ? a : b,
        );
      }

      int newStreak = _currentUser!.checkInStreak;

      if (lastActivityDate != null) {
        final lastActivityDay = DateTime(
          lastActivityDate.year,
          lastActivityDate.month,
          lastActivityDate.day,
        );

        if (today.isAfter(lastActivityDay)) {
          // Check if today is the next day after the last activity
          if (today.difference(lastActivityDay).inDays == 1) {
            newStreak += 1;
          } else {
            // More than one day has passed, reset streak
            newStreak = 1;
          }
        } else if (today == lastActivityDay) {
          // Same day, keep streak
          newStreak = newStreak;
        } else {
          // Last activity is in the future (unlikely), reset
          newStreak = 1;
        }
      } else {
        // No previous activity, start streak
        newStreak = 1;
      }

      // Update Firestore
      final updates = {
        'checkInStreak': newStreak,
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
      _logger.e("Error updating streak: $e");
      _errorMessage = e.toString();
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
        // Manually update _currentUser to avoid FieldValue type issues
        final currentMap = _currentUser!.toMap();
        currentMap['points'] = (_currentUser!.points ?? 0) + points;
        currentMap['claimedRewards'] = {
          ...(_currentUser!.claimedRewards),
          taskId: {'claimed': true, 'lastClaimed': Timestamp.now()},
        };

        if (taskId == 'daily_check_in') {
          currentMap['lastCheckIn'] = Timestamp.now();
          currentMap['checkInStreak'] = (_currentUser!.checkInStreak) + 1;
        } else if (taskId == 'complete_workout') {
          currentMap['lastWorkoutCompletionDate'] = Timestamp.now();
          currentMap['workoutsCompleted'] =
              (_currentUser!.workoutsCompleted) + 1;
        } else if (taskId == 'complete_meal_plan') {
          currentMap['lastMealPlanCompletionDate'] = Timestamp.now();
          currentMap['mealsTracked'] = (_currentUser!.mealsTracked) + 1;
        } else if (taskId == 'daily_step_goal') {
          currentMap['lastStepGoalCompletionDate'] = Timestamp.now();
        } else if (taskId == 'update_weight') {
          currentMap['lastWeightUpdateDate'] = Timestamp.now();
          if (badge != null) {
            currentMap['badges'] = [...(currentMap['badges'] ?? []), badge];
          }
        } else if ([
          'build_profile',
          'share_progress',
          'join_challenge',
          'complete_side_hustle',
        ].contains(taskId)) {
          currentMap['completedOneOffIds'] = [
            ...(currentMap['completedOneOffIds'] ?? []),
            taskId,
          ];
          if (badge != null) {
            currentMap['badges'] = [...(currentMap['badges'] ?? []), badge];
          }
        }

        _currentUser = AppUser.fromMap(currentMap);
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error claiming reward: $e");
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
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
        'lastWeightUpdateDate': FieldValue.serverTimestamp(),
        'weightHistory': FieldValue.arrayUnion([weightEntry]),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      if (_currentUser != null) {
        await loadUserData(firebaseUser!.uid, silent: true);
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

  Future<bool> get _supportsFcm async {
    try {
      await FirebaseMessaging.instance.getToken();
      return true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _safeFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on MissingPluginException {
      _logger.w('FCM plugin not available on this platform – skipping token');
      return null;
    } catch (e) {
      _logger.e('Unexpected FCM error: $e');
      return null;
    }
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
