import 'package:flutter/material.dart';

enum RewardType { dailyCheckIn, daily, weekly, oneOff, adReward }

class RewardTask {
  final String id;
  final String title;
  final String description;
  final int points;
  final RewardType type;
  final int maxCount;
  final bool isCompleted;
  final bool isEnabled;
  final VoidCallback? onAction;
  final Widget? progressChart;
  final String buttonText;

  RewardTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    this.maxCount = 1,
    required this.isCompleted,
    required this.isEnabled,
    this.onAction,
    this.progressChart,
    required this.buttonText,
  });

  factory RewardTask.fromJson(Map<String, dynamic> json) {
    return RewardTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      type: RewardType.values.firstWhere(
        (e) => e.toString() == 'RewardType.${json['type']}',
        orElse: () => RewardType.oneOff,
      ),
      maxCount: json['maxCount'] ?? 1,
      isCompleted: false, // Managed by UI logic
      isEnabled: false, // Managed by UI logic
      onAction: null,
      progressChart: null,
      buttonText: json['buttonText'] ?? 'Claim Reward', // Load from Firestore
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'type': type.toString().split('.').last,
      'maxCount': maxCount,
      'buttonText': buttonText, // Save to Firestore
    };
  }
}
