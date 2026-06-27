import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../theme.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  int currentSteps = 0;
  int dailyStepTarget = 10000;
  StreamSubscription<StepCount>? _stepCountSubscription;
  bool stepCounterInitialized = false;
  bool get stepCounterSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static const String _keyStepDate = 'cashfit_step_date';
  static const String _keyStepBaseline = 'cashfit_step_baseline';
  static const String _keyDailySteps = 'cashfit_daily_steps';

  @override
  void initState() {
    super.initState();
    _loadDailySteps();
    if (stepCounterSupported) {
      _initializeStepCounter();
    }
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDailySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyStepDate);

    if (savedDate != todayStr) {
      await prefs.setString(_keyStepDate, todayStr);
      await prefs.setInt(_keyDailySteps, 0);
      await prefs.remove(_keyStepBaseline);
      if (mounted) {
        setState(() {
          currentSteps = 0;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          currentSteps = prefs.getInt(_keyDailySteps) ?? 0;
        });
      }
    }
  }

  Future<void> _initializeStepCounter() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      if (!mounted) return;
      setState(() {
        stepCounterInitialized = true;
      });
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          if (!mounted) return;
          final prefs = await SharedPreferences.getInstance();
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final savedDate = prefs.getString(_keyStepDate);

          if (savedDate != todayStr) {
            await prefs.setString(_keyStepDate, todayStr);
            await prefs.setInt(_keyStepBaseline, event.steps);
            await prefs.setInt(_keyDailySteps, 0);
            setState(() {
              currentSteps = 0;
            });
          } else {
            int baseline = prefs.getInt(_keyStepBaseline) ?? -1;
            if (baseline == -1) {
              baseline = event.steps;
              await prefs.setInt(_keyStepBaseline, baseline);
            }
            int calculatedSteps = event.steps - baseline;
            if (calculatedSteps < 0) calculatedSteps = 0;

            await prefs.setInt(_keyDailySteps, calculatedSteps);
            setState(() {
              currentSteps = calculatedSteps;
            });
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            stepCounterInitialized = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    dailyStepTarget = userProvider.currentUser?.dailyStepTarget ?? 10000;
    final progress = (currentSteps / dailyStepTarget).clamp(0.0, 1.0);

    return AnimatedCard(
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: AppTheme.glassCardDecoration(colorScheme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.directions_walk, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DAILY STEP TRACKER",
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          "$currentSteps / $dailyStepTarget steps",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
