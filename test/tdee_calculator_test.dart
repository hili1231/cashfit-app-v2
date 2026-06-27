import 'package:flutter_test/flutter_test.dart';
import 'package:cashfit/utils/tdee_calculator.dart';
import 'package:cashfit/models/app_user.dart';

void main() {
  group('TDEECalculator Tests', () {
    test('Returns sensible weight loss defaults when user is null', () {
      final targets = TDEECalculator.calculateTargets(null);
      expect(targets['calories'], 2000);
      expect(targets['protein'], 150);
    });

    test('Calculates custom calorie deficit targets for user profile', () {
      final user = AppUser(
        id: 'user_123',
        name: 'Alex',
        email: 'alex@example.com',
        avatar: '',
        workoutsCompleted: 0,
        mealsTracked: 0,
        gender: 'male',
        age: '28',
        height: '180',
        weight: '85',
        weightHistory: [],
        activityLevel: 'moderate',
        dietGoal: 'weight_loss',
        dietPreference: '',
        workoutGoal: '',
        experienceLevel: '',
        trainingStyle: '',
        availableEquipment: [],
        injuryHistory: [],
        workoutFrequency: 3,
        allergies: [],
        isAdmin: false,
        isPremium: false,
        autoRenew: false,
        activeWorkoutPrograms: [],
        activeDietPlans: [],
        joinedSideHustles: [],
        lastLogin: DateTime.now(),
        streak: 0,
        points: 100,
        badges: [],
        workoutHistory: [],
        mealHistory: [],
        theme: 'dark',
        notifications: true,
        language: 'en',
        createdAt: DateTime.now(),
        referrer: '',
        balance: 0.0,
        hydration: '',
        dietaryRestrictions: [],
        workoutFocus: [],
        workoutDuration: 45.0,
        intensity: '',
        availableDays: [],
        mealFrequency: 3,
        mealTimes: [],
        medicalConditions: [],
        preferredWorkoutTimes: [],
        macroIntakeHistory: [],
        preferredWorkoutStyle: '',
        isBanned: false,
        notificationsEnabled: true,
        dailyReminderTime: '',
        weeklyReminderTime: '',
        dailyAdsWatched: 0,
        hasBuiltPlans: false,
        hasClaimedBuildPlansReward: false,
        checkInStreak: 0,
        completedOneOffIds: [],
        claimedRewards: {},
      );

      final targets = TDEECalculator.calculateTargets(user);
      expect(targets['calories']!, greaterThan(1200));
      expect(targets['protein']!, greaterThan(0));
      expect(targets['carbs']!, greaterThan(0));
      expect(targets['fat']!, greaterThan(0));
    });
  });
}
