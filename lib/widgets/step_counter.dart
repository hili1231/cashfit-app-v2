import 'dart:async';
import 'dart:io';
import 'package:cashfit/theme.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  int currentSteps = 0;
  int dailyStepTarget = 10000;
  Stream<StepCount>? stepCountStream;
  StreamSubscription<StepCount>? _stepCountSubscription;
  bool stepCounterInitialized = false;
  bool stepCounterSupported = true;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _resetStepsAtMidnight();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  void _checkPlatformSupport() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        stepCounterSupported = false;
        stepCounterInitialized = false;
      });
      return;
    }
    _initializeStepCounter();
  }

  Future<void> _initializeStepCounter() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      if (!mounted) return;
      setState(() {
        stepCounterInitialized = true;
      });
      stepCountStream = Pedometer.stepCountStream;
      _stepCountSubscription = stepCountStream?.listen(
        (StepCount event) {
          if (!mounted) return;
          setState(() {
            currentSteps = event.steps;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            stepCounterInitialized = false;
          });
        },
      );
    } else {
      if (status.isPermanentlyDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Step counter permission is required to track your steps. Please enable it in settings.",
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        stepCounterInitialized = false;
      });
    }
  }

  void _resetStepsAtMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    Future.delayed(durationUntilMidnight, () {
      setState(() {
        currentSteps = 0;
        // Reset any other state variables related to step goal reward here
      });
      _resetStepsAtMidnight(); // Schedule the next reset
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return AnimatedCard(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    // Update dailyStepTarget reactively
    dailyStepTarget = userProvider.currentUser?.dailyStepTarget ?? 10000;

    if (!stepCounterSupported) {
      return AnimatedCard(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "Step counting is not supported on this platform.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (!stepCounterInitialized) {
      return AnimatedCard(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Step counter permission required.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    await Permission.activityRecognition.request();
                    _initializeStepCounter();
                  },
                  child: Text(
                    "Grant Permission",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = (currentSteps / dailyStepTarget).clamp(0.0, 1.0);

    return AnimatedCard(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Steps",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "$currentSteps / $dailyStepTarget steps",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.onSurfaceVariant.withAlpha(77),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
