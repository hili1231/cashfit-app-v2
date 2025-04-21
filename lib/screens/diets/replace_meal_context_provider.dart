import 'package:flutter/material.dart';

enum OriginatingScreen { mealDetail, dayDetail, mealPlan }

class ReplaceMealContextProvider with ChangeNotifier {
  String? _mealId;
  String? _mealType;
  int? _dayNumber;
  OriginatingScreen? _originatingScreen;
  String? _mealPlanId;

  String? get mealId => _mealId;
  String? get mealType => _mealType;
  int? get dayNumber => _dayNumber;
  OriginatingScreen? get originatingScreen => _originatingScreen;
  String? get mealPlanId => _mealPlanId;

  void setContext({
    required String mealId,
    required String mealType,
    required int? dayNumber,
    required OriginatingScreen originatingScreen,
    required String mealPlanId,
  }) {
    _mealId = mealId;
    _mealType = mealType;
    _dayNumber = dayNumber;
    _originatingScreen = originatingScreen;
    _mealPlanId = mealPlanId;
    notifyListeners();
  }

  void clearContext() {
    _mealId = null;
    _mealType = null;
    _dayNumber = null;
    _originatingScreen = null;
    _mealPlanId = null;
    notifyListeners();
  }
}
