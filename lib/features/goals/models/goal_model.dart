import 'dart:convert';

import 'package:micro_manager/shared/enums.dart';

/// Represents a goal stored in the database
class GoalModel {
  GoalModel({
    required this.id,
    required this.name,
    required this.category,
    required this.cycle,
    this.activeDays,
    required this.dataMetricType,
    this.occurrences,
    this.dayOfMonth,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.checkpoints,
    this.eventCount = 0,
  });

  /// Create from database map (without checkpoints)
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      cycle: map['cycle'] as String,
      activeDays: map['active_days'] as String?,
      dataMetricType: GoalDataMetricType.fromString(
        map['data_metric_type'] as String,
      ),
      occurrences: map['occurrences'] as int?,
      dayOfMonth: map['day_of_month'] as int?,
      isActive: map['is_active'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      checkpoints: const <GoalCheckpoint>[],
      eventCount: 0,
    );
  }

  /// Create from goals_details view (includes checkpoints as JSON)
  factory GoalModel.fromDetailsMap(Map<String, dynamic> map) {
    List<GoalCheckpoint> checkpoints = <GoalCheckpoint>[];

    final dynamic checkpointsJson = map['checkpoints'];
    if (checkpointsJson != null && checkpointsJson.toString().isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(checkpointsJson as String) as List<dynamic>;
        checkpoints = decoded
            .map(
              (dynamic cp) =>
                  GoalCheckpoint.fromMap(cp as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        // Handle JSON parse error silently
        // print('Error parsing checkpoints: $e');
      }
    }

    return GoalModel(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      cycle: map['cycle'] as String,
      activeDays: map['active_days'] as String?,
      dataMetricType: GoalDataMetricType.fromString(
        map['data_metric_type'] as String,
      ),
      occurrences: map['occurrences'] as int?,
      dayOfMonth: map['day_of_month'] as int?,
      isActive: map['is_active'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      checkpoints: checkpoints,
      eventCount: map['event_count'] as int? ?? 0,
    );
  }

  final int id;
  final String name;
  final String category;
  final String cycle;
  final String? activeDays;
  final GoalDataMetricType dataMetricType;
  final int? occurrences;
  final int? dayOfMonth;
  final int isActive;
  final int eventCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GoalCheckpoint> checkpoints;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'cycle': cycle,
      'active_days': activeDays,
      'data_metric_type': dataMetricType.name,
      'occurrences': occurrences,
      'day_of_month': dayOfMonth,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Goal(id: $id, name: $name, category: $category, cycle: $cycle, checkpoints: ${checkpoints.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ category.hashCode;
}

/// Represents a checkpoint for a goal
class GoalCheckpoint {
  GoalCheckpoint({
    required this.id,
    required this.goalId,
    required this.checkpointTime,
    required this.position,
    required this.createdAt,
  });

  /// Create from database map
  factory GoalCheckpoint.fromMap(Map<String, dynamic> map) {
    return GoalCheckpoint(
      id: map['id'] as int,
      goalId: map['goal_id'] as int,
      checkpointTime: map['checkpoint_time'] as String,
      position: map['position'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final int id;
  final int goalId;
  final String checkpointTime;
  final int position;
  final DateTime createdAt;

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'goal_id': goalId,
      'checkpoint_time': checkpointTime,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'GoalCheckpoint(id: $id, goalId: $goalId, checkpointTime: $checkpointTime, position: $position)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalCheckpoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          goalId == other.goalId &&
          checkpointTime == other.checkpointTime &&
          position == other.position;

  @override
  int get hashCode =>
      id.hashCode ^
      goalId.hashCode ^
      checkpointTime.hashCode ^
      position.hashCode;
}
