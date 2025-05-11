import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/meal_plan.dart';
import '../models/workout_program.dart';
import '../models/active_diet_plan.dart';
import '../models/active_workout_program.dart';

/// Centralized cache management service for the app
/// Handles caching and retrieving data from local storage
/// Uses SharedPreferences for persistence
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Logger _logger = Logger();
  static const String kWorkoutProgramsKey = 'cached_workout_programs';
  static const String kMealPlansKey = 'cached_meal_plans';
  static const String kUserWorkoutsKey = 'user_active_workouts_';
  static const String kUserDietsKey = 'user_active_diets_';
  static const String kCacheTimestampKey = 'cache_timestamp_';
  static const Duration kCacheMaxAge = Duration(hours: 24);

  // Cache expiration times by data type
  static const Map<String, Duration> cacheExpiration = {
    'workoutPrograms': Duration(hours: 24),
    'mealPlans': Duration(hours: 24),
    'userWorkouts': Duration(minutes: 30),
    'userDiets': Duration(minutes: 30),
  };

  /// Get workout programs - first from cache, then from Firestore if needed
  Future<List<WorkoutProgram>> getWorkoutPrograms({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedPrograms = await _getCachedWorkoutPrograms();
      if (cachedPrograms.isNotEmpty) {
        _logger.i(
          'Retrieved ${cachedPrograms.length} workout programs from cache',
        );
        return cachedPrograms;
      }
    }

    // Cache miss or force refresh - fetch from Firestore
    _logger.i('Fetching workout programs from Firestore');
    final snapshot =
        await FirebaseFirestore.instance.collection('workoutPrograms').get();

    final programs =
        snapshot.docs
            .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
            .toList();

    await _cacheWorkoutPrograms(programs);
    return programs;
  }

  /// Get meal plans - first from cache, then from Firestore if needed
  Future<List<MealPlan>> getMealPlans({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedMealPlans = await _getCachedMealPlans();
      if (cachedMealPlans.isNotEmpty) {
        _logger.i('Retrieved ${cachedMealPlans.length} meal plans from cache');
        return cachedMealPlans;
      }
    }

    // Cache miss or force refresh - fetch from Firestore
    _logger.i('Fetching meal plans from Firestore');
    final snapshot =
        await FirebaseFirestore.instance.collection('mealPlans').get();

    final mealPlans =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MealPlan.fromMap(data);
        }).toList();

    await _cacheMealPlans(mealPlans);
    return mealPlans;
  }

  /// Get user's active workout programs - from cache with option to force refresh
  Future<Map<String, WorkoutProgram>> getUserActiveWorkouts(
    String userId,
    List<ActiveWorkoutProgram> activeWorkouts, {
    bool forceRefresh = false,
  }) async {
    _logger.d(
      'getUserActiveWorkouts called for user $userId with ${activeWorkouts.length} active programs',
    );

    if (!forceRefresh) {
      final cachedWorkouts = await _getCachedUserActiveWorkouts(userId);
      final isCacheValid = await _isCacheValid('userWorkouts', userId);

      if (cachedWorkouts.isNotEmpty && isCacheValid) {
        _logger.i(
          'Retrieved ${cachedWorkouts.length} active workouts from cache for user $userId',
        );
        _logger.d('Cached workout IDs: ${cachedWorkouts.keys.join(", ")}');
        return cachedWorkouts;
      } else {
        _logger.w('Cache miss or invalid for user workouts');
        _logger.d(
          'Cache valid: $isCacheValid, Cache size: ${cachedWorkouts.length}',
        );
      }
    } else {
      _logger.i('Force refresh requested for user active workouts');
    }

    _logger.i('Fetching active workouts from Firestore for user $userId');
    final Map<String, WorkoutProgram> workoutMap = {};

    // Get workout IDs
    final List<String> workoutIds =
        activeWorkouts.map((aw) => aw.workoutProgramId).toList();
    if (workoutIds.isEmpty) {
      _logger.w('No workout IDs found in user active programs');
      return workoutMap;
    }

    // Get workout details in batches
    const batchSize = 10;
    for (var i = 0; i < workoutIds.length; i += batchSize) {
      final batchIds = workoutIds.sublist(
        i,
        i + batchSize > workoutIds.length ? workoutIds.length : i + batchSize,
      );

      _logger.d('Fetching workout programs batch: $batchIds');

      try {
        final programSnapshot =
            await FirebaseFirestore.instance
                .collection('workoutPrograms')
                .where(FieldPath.documentId, whereIn: batchIds)
                .get();

        final batchWorkouts =
            programSnapshot.docs
                .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
                .toList();

        for (var workout in batchWorkouts) {
          workoutMap[workout.id] = workout;
        }
      } catch (e) {
        _logger.e('Error fetching workout batch: $e');
      }
    }

    await _cacheUserActiveWorkouts(userId, workoutMap);
    return workoutMap;
  }

  Future<Map<String, MealPlan>> getUserActiveDiets(
    String userId,
    List<ActiveDietPlan> activeDiets, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedDiets = await _getCachedUserActiveDiets(userId);
      final isCacheValid = await _isCacheValid('userDiets', userId);

      if (cachedDiets.isNotEmpty && isCacheValid) {
        _logger.i(
          'Retrieved ${cachedDiets.length} active diets from cache for user $userId',
        );
        return cachedDiets;
      }
    }

    _logger.i('Fetching active diet plans from Firestore for user $userId');
    final Map<String, MealPlan> dietMap = {};

    // Get diet plan IDs
    final List<String> dietIds =
        activeDiets.map((ad) => ad.dietPlanId).toList();
    if (dietIds.isEmpty) {
      return dietMap;
    }

    // Get diet details in batches
    const batchSize = 10;
    for (var i = 0; i < dietIds.length; i += batchSize) {
      final batchIds = dietIds.sublist(
        i,
        i + batchSize > dietIds.length ? dietIds.length : i + batchSize,
      );

      _logger.d('Fetching meal plans batch: $batchIds');

      try {
        final plansSnapshot =
            await FirebaseFirestore.instance
                .collection('mealPlans')
                .where(FieldPath.documentId, whereIn: batchIds)
                .get();

        for (var doc in plansSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          final mealPlan = MealPlan.fromMap(data);
          dietMap[mealPlan.id] = mealPlan;
        }
      } catch (e) {
        _logger.e('Error fetching meal plans batch: $e');
      }
    }

    await _cacheUserActiveDiets(userId, dietMap);
    return dietMap;
  }

  /// Invalidate user active workouts cache
  Future<void> invalidateUserWorkoutsCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kUserWorkoutsKey + userId);
    await _updateCacheTimestamp('userWorkouts', userId);
    _logger.i('Invalidated active workouts cache for user $userId');
  }

  /// Invalidate user active diets cache
  Future<void> invalidateUserDietsCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kUserDietsKey + userId);
    await _updateCacheTimestamp('userDiets', userId);
    _logger.i('Invalidated active diets cache for user $userId');
  }

  /// Invalidate all cache items
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear workout and meal plan caches
    await prefs.remove(kWorkoutProgramsKey);
    await prefs.remove(kMealPlansKey);

    // Clear user-specific caches
    final keys =
        prefs
            .getKeys()
            .where(
              (key) =>
                  key.startsWith(kUserWorkoutsKey) ||
                  key.startsWith(kUserDietsKey),
            )
            .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    _logger.i('Cleared all cache items');
  }

  /// Get a single workout program by ID with caching
  Future<WorkoutProgram?> getSingleWorkoutProgram(
    String workoutId, {
    bool forceRefresh = false,
  }) async {
    _logger.d('Getting single workout program: $workoutId');

    if (!forceRefresh) {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final singleKey = 'single_workout_$workoutId';
      final cachedData = prefs.getString(singleKey);

      if (cachedData != null) {
        try {
          final Map<String, dynamic> workoutData = jsonDecode(cachedData);
          _logger.i('Retrieved workout from cache: $workoutId');
          return WorkoutProgram.fromMap(workoutData, workoutId);
        } catch (e) {
          _logger.e('Error parsing cached workout: $e');
        }
      }
    }

    return null;
  }

  /// Cache a single workout program
  Future<void> cacheSingleWorkoutProgram(WorkoutProgram workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final singleKey = 'single_workout_${workout.id}';

      await prefs.setString(singleKey, jsonEncode(workout.toMap()));
      _logger.i('Cached single workout: ${workout.id}');
    } catch (e) {
      _logger.e('Error caching single workout: $e');
    }
  }

  /// Get a single meal plan by ID with caching
  Future<MealPlan?> getSingleMealPlan(
    String mealPlanId, {
    bool forceRefresh = false,
  }) async {
    _logger.d('Getting single meal plan: $mealPlanId');

    if (!forceRefresh) {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final singleKey = 'single_mealplan_$mealPlanId';
      final cachedData = prefs.getString(singleKey);

      if (cachedData != null) {
        try {
          final Map<String, dynamic> mealData = jsonDecode(cachedData);
          _logger.i('Retrieved meal plan from cache: $mealPlanId');
          return MealPlan.fromMap(mealData);
        } catch (e) {
          _logger.e('Error parsing cached meal plan: $e');
        }
      }
    }

    return null;
  }

  /// Cache a single meal plan
  Future<void> cacheSingleMealPlan(MealPlan mealPlan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final singleKey = 'single_mealplan_${mealPlan.id}';

      await prefs.setString(singleKey, jsonEncode(mealPlan.toMap()));
      _logger.i('Cached single meal plan: ${mealPlan.id}');
    } catch (e) {
      _logger.e('Error caching single meal plan: $e');
    }
  }

  /// Optimize cache usage by removing old entries
  Future<void> optimizeCache() async {
    // For better performance, we can regularly clean old caches
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;
    const maxAge = 7 * 24 * 60 * 60 * 1000; // One week in milliseconds

    // Get timestamp keys that are more than one week old
    final oldTimestamps =
        allKeys.where((key) => key.startsWith('timestamp_')).where((key) {
          final timestamp = prefs.getInt(key) ?? 0;
          return now - timestamp > maxAge;
        }).toList();

    // Remove related caches for old timestamps
    for (final key in oldTimestamps) {
      final cacheKey = key.replaceFirst('timestamp_', '');
      final parts = cacheKey.split('_');

      if (parts.length > 1) {
        final type = parts[0];
        final id = parts.length > 1 ? parts[1] : '';

        if (type == 'userWorkouts') {
          await prefs.remove('$kUserWorkoutsKey$id');
        } else if (type == 'userDiets') {
          await prefs.remove('$kUserDietsKey$id');
        } else if (type == 'single') {
          await prefs.remove('single_$id');
        }
      }

      // Remove the timestamp itself
      await prefs.remove(key);
    }

    _logger.i(
      'Cache optimization completed, removed ${oldTimestamps.length} old entries',
    );
  }

  // Private helper methods
  Future<List<WorkoutProgram>> _getCachedWorkoutPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(kWorkoutProgramsKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map<WorkoutProgram>((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          item['data'],
        );
        return WorkoutProgram.fromMap(map, item['id']);
      }).toList();
    } catch (e) {
      _logger.e('Error getting cached workout programs: $e');
      return [];
    }
  }

  Future<void> _cacheWorkoutPrograms(List<WorkoutProgram> programs) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> serialized =
          programs.map((program) {
            return {'id': program.id, 'data': program.toMap()};
          }).toList();

      await prefs.setString(kWorkoutProgramsKey, jsonEncode(serialized));
      await _updateCacheTimestamp('workoutPrograms');
      _logger.i('Cached ${programs.length} workout programs');
    } catch (e) {
      _logger.e('Error caching workout programs: $e');
    }
  }

  Future<List<MealPlan>> _getCachedMealPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(kMealPlansKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map<MealPlan>((item) {
        return MealPlan.fromMap(Map<String, dynamic>.from(item));
      }).toList();
    } catch (e) {
      _logger.e('Error getting cached meal plans: $e');
      return [];
    }
  }

  Future<void> _cacheMealPlans(List<MealPlan> mealPlans) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<Map<String, dynamic>> serialized =
          mealPlans.map((plan) {
            return plan.toMap();
          }).toList();

      await prefs.setString(kMealPlansKey, jsonEncode(serialized));
      await _updateCacheTimestamp('mealPlans');
      _logger.i('Cached ${mealPlans.length} meal plans');
    } catch (e) {
      _logger.e('Error caching meal plans: $e');
    }
  }

  Future<Map<String, WorkoutProgram>> _getCachedUserActiveWorkouts(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(kUserWorkoutsKey + userId);

      if (jsonString == null) {
        return {};
      }

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, WorkoutProgram> result = {};

      decoded.forEach((key, value) {
        result[key] = WorkoutProgram.fromMap(
          Map<String, dynamic>.from(value),
          key,
        );
      });

      return result;
    } catch (e) {
      _logger.e('Error getting cached user active workouts: $e');
      return {};
    }
  }

  Future<void> _cacheUserActiveWorkouts(
    String userId,
    Map<String, WorkoutProgram> workouts,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> serialized = {};
      workouts.forEach((id, workout) {
        serialized[id] = workout.toMap();
      });

      await prefs.setString(kUserWorkoutsKey + userId, jsonEncode(serialized));
      await _updateCacheTimestamp('userWorkouts', userId);
      _logger.i('Cached ${workouts.length} active workouts for user $userId');
    } catch (e) {
      _logger.e('Error caching user active workouts: $e');
    }
  }

  Future<Map<String, MealPlan>> _getCachedUserActiveDiets(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(kUserDietsKey + userId);

      if (jsonString == null) {
        return {};
      }

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, MealPlan> result = {};

      decoded.forEach((key, value) {
        final map = Map<String, dynamic>.from(value);
        map['id'] = key;
        result[key] = MealPlan.fromMap(map);
      });

      return result;
    } catch (e) {
      _logger.e('Error getting cached user active diets: $e');
      return {};
    }
  }

  Future<void> _cacheUserActiveDiets(
    String userId,
    Map<String, MealPlan> diets,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> serialized = {};
      diets.forEach((id, diet) {
        serialized[id] = diet.toMap();
      });

      await prefs.setString(kUserDietsKey + userId, jsonEncode(serialized));
      await _updateCacheTimestamp('userDiets', userId);
      _logger.i('Cached ${diets.length} active diets for user $userId');
    } catch (e) {
      _logger.e('Error caching user active diets: $e');
    }
  }

  Future<void> _updateCacheTimestamp(String type, [String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          userId != null
              ? '$kCacheTimestampKey${type}_$userId'
              : '$kCacheTimestampKey$type';

      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Error updating cache timestamp: $e');
    }
  }

  Future<bool> _isCacheValid(String type, [String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          userId != null
              ? '$kCacheTimestampKey${type}_$userId'
              : '$kCacheTimestampKey$type';

      final timestampStr = prefs.getString(key);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final maxAge = cacheExpiration[type] ?? kCacheMaxAge;

      return DateTime.now().difference(timestamp) < maxAge;
    } catch (e) {
      _logger.e('Error checking cache validity: $e');
      return false;
    }
  }

  /// Refresh specific parts of the cache
  /// Use this when user performs actions that would change cached data
  Future<void> refreshCache({
    bool workoutPrograms = false,
    bool mealPlans = false,
    bool userWorkouts = false,
    bool userDiets = false,
    String? userId,
  }) async {
    _logger.i('Refreshing cache data selectively');

    final tasks = <Future>[];

    if (workoutPrograms) {
      _logger.d('Refreshing workout programs cache');
      tasks.add(getWorkoutPrograms(forceRefresh: true));
    }

    if (mealPlans) {
      _logger.d('Refreshing meal plans cache');
      tasks.add(getMealPlans(forceRefresh: true));
    }

    if (userWorkouts && userId != null) {
      _logger.d('Invalidating user workouts cache');
      tasks.add(invalidateUserWorkoutsCache(userId));
    }

    if (userDiets && userId != null) {
      _logger.d('Invalidating user diets cache');
      tasks.add(invalidateUserDietsCache(userId));
    }

    await Future.wait(tasks);
    _logger.i('Cache refresh completed');
  }

  /// Load global cache data (workout programs and meal plans)
  Future<void> loadGlobalCache() async {
    _logger.i('Loading global cache data');

    // Run the cache loading in a separate isolate or background task
    // to avoid blocking the main UI thread during startup
    Future.microtask(() async {
      try {
        // Check if we already have valid cache data
        final hasWorkoutCache = await _isCacheValid('workoutPrograms');
        final hasMealCache = await _isCacheValid('mealPlans');

        final cacheTasks = <Future>[];

        // Only refresh if the cache is invalid or expired
        if (!hasWorkoutCache) {
          cacheTasks.add(getWorkoutPrograms(forceRefresh: true));
        }

        if (!hasMealCache) {
          cacheTasks.add(getMealPlans(forceRefresh: true));
        }

        // Run periodic cache optimization
        cacheTasks.add(optimizeCache());

        await Future.wait(cacheTasks);
        _logger.i('Global cache loading completed');
      } catch (e) {
        _logger.e('Error loading global cache: $e');
      }
    });
  }

  /// Load user-specific cache data
  Future<void> loadUserCache(
    String userId,
    List<ActiveWorkoutProgram> activeWorkouts,
    List<ActiveDietPlan> activeDiets,
  ) async {
    _logger.i('Loading user-specific cache data for user $userId');

    // Run in a background task to avoid blocking the UI
    Future.microtask(() async {
      try {
        final tasks = <Future>[];
        final userWorkoutCacheValid = await _isCacheValid(
          'userWorkouts',
          userId,
        );
        final userDietCacheValid = await _isCacheValid('userDiets', userId);

        // Only load workouts if either cache is invalid or force refresh is needed
        if (activeWorkouts.isNotEmpty && !userWorkoutCacheValid) {
          _logger.i('Loading ${activeWorkouts.length} active workout programs');
          tasks.add(
            getUserActiveWorkouts(userId, activeWorkouts, forceRefresh: false),
          );
        } else {
          _logger.i('User workout cache is valid, skipping reload');
        }

        if (activeDiets.isNotEmpty && !userDietCacheValid) {
          _logger.i('Loading ${activeDiets.length} active diet plans');
          tasks.add(
            getUserActiveDiets(userId, activeDiets, forceRefresh: false),
          );
        } else {
          _logger.i('User diet cache is valid, skipping reload');
        }

        await Future.wait(tasks);
        _logger.i('User cache loading completed');
      } catch (e) {
        _logger.e('Error loading user cache: $e');
      }
    });
  }

  /// Improves app loading time by prefetching frequently used data
  Future<void> prefetchFrequentlyAccessedData() async {
    _logger.i('Prefetching frequently accessed data');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check when data was last prefetched
      final lastPrefetchTime = prefs.getInt('last_prefetch_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only prefetch once per day to avoid unnecessary network calls
      if (now - lastPrefetchTime > const Duration(hours: 24).inMilliseconds) {
        // Run prefetching in background
        Future.microtask(() async {
          try {
            // Prefetch the most popular workout programs
            final popularWorkouts =
                await FirebaseFirestore.instance
                    .collection('workoutPrograms')
                    .orderBy('popularity', descending: true)
                    .limit(5)
                    .get();

            if (popularWorkouts.docs.isNotEmpty) {
              final programs =
                  popularWorkouts.docs
                      .map((doc) => WorkoutProgram.fromMap(doc.data(), doc.id))
                      .toList();

              await _cacheWorkoutPrograms(programs);
            }

            // Prefetch the most popular meal plans
            final popularMeals =
                await FirebaseFirestore.instance
                    .collection('mealPlans')
                    .orderBy('popularity', descending: true)
                    .limit(5)
                    .get();

            if (popularMeals.docs.isNotEmpty) {
              final plans =
                  popularMeals.docs
                      .map((doc) => MealPlan.fromMap(doc.data()))
                      .toList();

              await _cacheMealPlans(plans);
            }

            // Update the timestamp
            await prefs.setInt('last_prefetch_timestamp', now);
            _logger.i('Prefetching completed successfully');
          } catch (e) {
            _logger.e('Error during prefetching: $e');
          }
        });
      } else {
        _logger.i('Skipping prefetch, data is recent enough');
      }
    } catch (e) {
      _logger.e('Error checking prefetch status: $e');
    }
  }

  /// Prioritizes cache loading by loading critical data first
  Future<void> prioritizedCacheLoad(String userId) async {
    try {
      _logger.i('Starting prioritized cache loading');

      // Load active workouts first (most critical)
      final activeWorkoutIds = await _getActiveEntityIds(
        userId,
        'activeWorkoutPrograms',
      );
      if (activeWorkoutIds.isNotEmpty) {
        for (final id in activeWorkoutIds) {
          await getSingleWorkoutProgram(id, forceRefresh: false);
        }
      }

      // Then load active diet plans
      final activeDietIds = await _getActiveEntityIds(
        userId,
        'activeDietPlans',
      );
      if (activeDietIds.isNotEmpty) {
        for (final id in activeDietIds) {
          await getSingleMealPlan(id, forceRefresh: false);
        }
      }

      _logger.i('Prioritized cache loading completed');
    } catch (e) {
      _logger.e('Error in prioritized cache loading: $e');
    }
  }

  Future<List<String>> _getActiveEntityIds(String userId, String entity) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection(entity)
              .get();

      return snapshot.docs.map((doc) {
        if (entity == 'activeWorkoutPrograms') {
          return doc.data()['workoutProgramId'] as String;
        } else {
          return doc.data()['dietPlanId'] as String;
        }
      }).toList();
    } catch (e) {
      _logger.e('Error getting active $entity IDs: $e');
      return [];
    }
  }
}
