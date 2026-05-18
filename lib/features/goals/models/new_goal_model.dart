import 'package:flutter/material.dart';
import 'package:micro_manager/shared/enums.dart';

enum GoalCycle {
  daily,
  weekly,
  biWeekly,
  monthly,
}

class NewGoalModel {
  NewGoalModel({
    required this.name,
    required this.category,
    required this.cycle,
    required this.activeDays,
    required this.checkpoints,
    required this.dataMetricType,
    this.occurrences,
    this.dayOfMonth,
  }) : assert(
         (cycle != GoalCycle.monthly || dayOfMonth != null) &&
             (cycle == GoalCycle.daily || occurrences == null),
         'dayOfMonth is required for monthly cycles, and occurrences should only be set for daily cycles',
       );

  final String name;
  final String category;
  final GoalCycle cycle;
  final List<int> activeDays;
  final List<TimeOfDay> checkpoints;
  final GoalDataMetricType dataMetricType;
  final int? occurrences;
  final int? dayOfMonth;

  @override
  String toString() {
    return 'NewGoalModel(name: $name, category: $category, occurrences: $occurrences, cycle: $cycle, activeDays: $activeDays, dayOfMonth: $dayOfMonth, checkpoints: $checkpoints, dataMetricType: $dataMetricType)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewGoalModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category &&
          occurrences == other.occurrences &&
          cycle == other.cycle &&
          activeDays == other.activeDays &&
          dayOfMonth == other.dayOfMonth &&
          checkpoints == other.checkpoints &&
          dataMetricType == other.dataMetricType;

  @override
  int get hashCode =>
      name.hashCode ^
      category.hashCode ^
      occurrences.hashCode ^
      cycle.hashCode ^
      activeDays.hashCode ^
      dayOfMonth.hashCode ^
      checkpoints.hashCode ^
      dataMetricType.hashCode;
}
