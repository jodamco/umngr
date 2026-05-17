import 'package:flutter/material.dart';

enum GoalCycle {
  daily,
  weekly,
  biWeekly,
  monthly,
}

class NewGoalModel {
  final String name;
  final String category;
  final int occurrences;
  final GoalCycle cycle;
  final List<int> activeDays;
  final int? dayOfMonth;
  final List<TimeOfDay> checkpoints;

  NewGoalModel({
    required this.name,
    required this.category,
    required this.occurrences,
    required this.cycle,
    required this.activeDays,
    this.dayOfMonth,
    required this.checkpoints,
  }) : assert(
    cycle != GoalCycle.monthly || dayOfMonth != null,
    'dayOfMonth is required for monthly cycles',
  );

  @override
  String toString() {
    return 'NewGoalModel(name: $name, category: $category, occurrences: $occurrences, cycle: $cycle, activeDays: $activeDays, dayOfMonth: $dayOfMonth, checkpoints: $checkpoints)';
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
          checkpoints == other.checkpoints;

  @override
  int get hashCode =>
      name.hashCode ^
      category.hashCode ^
      occurrences.hashCode ^
      cycle.hashCode ^
      activeDays.hashCode ^
      dayOfMonth.hashCode ^
      checkpoints.hashCode;
}
