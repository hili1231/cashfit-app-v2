import 'package:flutter/material.dart';

class RewardTask {
  final String title;
  final String description;
  final int points;
  final bool isCompleted;
  final bool isEnabled;
  final VoidCallback? onAction;
  final Widget? progressChart; // Optional chart for tasks like daily check-in

  RewardTask({
    required this.title,
    required this.description,
    required this.points,
    required this.isCompleted,
    required this.isEnabled,
    this.onAction,
    this.progressChart,
  });
}
