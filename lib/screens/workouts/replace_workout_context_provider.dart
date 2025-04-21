import 'package:flutter/material.dart';

enum OriginatingScreen { exerciseDetail, dayDetail, workoutDetail }

class ReplaceContextProvider with ChangeNotifier {
  String? _exerciseId;
  int? _dayNumber;
  OriginatingScreen? _originatingScreen;
  String? _workoutProgramId;

  String? get exerciseId => _exerciseId;
  int? get dayNumber => _dayNumber;
  OriginatingScreen? get originatingScreen => _originatingScreen;
  String? get workoutProgramId => _workoutProgramId;

  void setContext({
    required String exerciseId,
    required int? dayNumber,
    required OriginatingScreen originatingScreen,
    required String workoutProgramId,
  }) {
    _exerciseId = exerciseId;
    _dayNumber = dayNumber;
    _originatingScreen = originatingScreen;
    _workoutProgramId = workoutProgramId;
    notifyListeners();
  }

  void clearContext() {
    _exerciseId = null;
    _dayNumber = null;
    _originatingScreen = null;
    _workoutProgramId = null;
    notifyListeners();
  }
}
