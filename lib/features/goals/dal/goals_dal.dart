import 'package:flutter/material.dart';
import 'package:micro_manager/core/services/db/db_abstraction.dart';
import 'package:micro_manager/features/goals/models/goal.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';

/// Data Access Layer for Goals
/// Handles all database operations related to goals
/// Uses the DbAbstraction interface, not tied to any specific database implementation
class GoalsDAL {
  final DbAbstraction _db;

  GoalsDAL(this._db);

  /// Save a new goal to the database
  /// Returns the ID of the created goal
  Future<int> createGoal(NewGoalModel model) async {
    // Convert TimeOfDay list to string list (HH:mm format)
    final List<String> checkpointStrings = model.checkpoints
        .map(
          (TimeOfDay tod) =>
              '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}',
        )
        .toList();

    return _createGoal(
      name: model.name,
      category: model.category,
      cycle: model.cycle,
      activeDays: model.activeDays.isNotEmpty ? model.activeDays : null,
      checkpoints: checkpointStrings,
      dataMetricType: model.dataMetricType,
      occurrences: model.occurrences,
      dayOfMonth: model.dayOfMonth,
    );
  }

  Future<int> _createGoal({
    required String name,
    required String category,
    required GoalCycle cycle,
    required List<int>? activeDays,
    required List<String> checkpoints,
    required GoalDataMetricType dataMetricType,
    int? occurrences,
    int? dayOfMonth,
  }) async {
    // Insert goal
    final int goalId = await _db.insert(
      table: 'goals',
      values: <String, dynamic>{
        'name': name,
        'category': category,
        'cycle': cycle.toString().split('.').last,
        'active_days': activeDays?.toString(),
        'data_metric_type': dataMetricType.toString().split('.').last,
        'occurrences': occurrences,
        'day_of_month': dayOfMonth,
        'is_active': 1,
      },
    );

    // Batch insert checkpoints
    if (checkpoints.isNotEmpty) {
      final List<Map<String, dynamic>> checkpointMaps =
          <Map<String, dynamic>>[];
      for (int i = 0; i < checkpoints.length; i++) {
        checkpointMaps.add(<String, dynamic>{
          'goal_id': goalId,
          'checkpoint_time': checkpoints[i],
          'position': i,
        });
      }
      await _db.batchInsert(
        table: 'goal_checkpoints',
        values: checkpointMaps,
      );
    }

    return goalId;
  }

  /// Get all goals with their checkpoints
  Future<List<Goal>> getAllGoals() async {
    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goals_details',
    );
    return results.map(Goal.fromDetailsMap).toList();
  }

  /// Query goals with optional filters
  /// If no filters are provided, returns all goals
  Future<List<Goal>> getGoals({
    int? id,
    String? category,
    int? isActive,
  }) async {
    final List<String> conditions = <String>[];
    final List<dynamic> args = <dynamic>[];

    if (id != null) {
      conditions.add('id = ?');
      args.add(id);
    } else {
      if (category != null) {
        conditions.add('category = ?');
        args.add(category);
      }

      if (isActive != null) {
        conditions.add('is_active = ?');
        args.add(isActive);
      }
    }

    final String? where = conditions.isNotEmpty
        ? conditions.join(' AND ')
        : null;

    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goals_details',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
    );
    return results.map(Goal.fromDetailsMap).toList();
  }

  /// Delete a goal and all its related data
  Future<int> deleteGoal(int goalId) async {
    return await _db.delete(
      table: 'goals',
      where: 'id = ?',
      whereArgs: <dynamic>[goalId],
    );
  }

  /// Update an existing goal with its checkpoints
  Future<void> updateGoal(Goal goal) async {
    // Update goal data
    await _db.update(
      table: 'goals',
      values: <String, dynamic>{
        'name': goal.name,
        'category': goal.category,
        'cycle': goal.cycle,
        'active_days': goal.activeDays,
        'data_metric_type': goal.dataMetricType,
        'occurrences': goal.occurrences,
        'day_of_month': goal.dayOfMonth,
        'is_active': goal.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <dynamic>[goal.id],
    );

    // Delete all existing checkpoints
    await _db.delete(
      table: 'goal_checkpoints',
      where: 'goal_id = ?',
      whereArgs: <dynamic>[goal.id],
    );

    // Batch insert new checkpoints
    if (goal.checkpoints.isNotEmpty) {
      final List<Map<String, dynamic>> checkpointMaps =
          <Map<String, dynamic>>[];
      for (int i = 0; i < goal.checkpoints.length; i++) {
        checkpointMaps.add(<String, dynamic>{
          'goal_id': goal.id,
          'checkpoint_time': goal.checkpoints[i].checkpointTime,
          'position': i,
        });
      }
      await _db.batchInsert(
        table: 'goal_checkpoints',
        values: checkpointMaps,
      );
    }
  }

  /// Toggle goal active status
  Future<int> toggleGoalStatus(int goalId, bool isActive) async {
    return await _db.update(
      table: 'goals',
      values: <String, dynamic>{'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: <dynamic>[goalId],
    );
  }
}
