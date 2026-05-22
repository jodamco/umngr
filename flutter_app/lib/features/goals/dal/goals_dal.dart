import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:micro_manager/core/services/db/db_abstraction.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/shared/enums.dart';

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
        'active_days': activeDays != null ? jsonEncode(activeDays) : null,
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
  Future<List<GoalModel>> getAllGoals() async {
    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goals_details',
    );
    return _hydrateGoalsWithCheckpoints(results);
  }

  /// Query goals with optional filters
  /// If no filters are provided, returns all goals
  Future<List<GoalModel>> getGoals({
    String? category,
    int? isActive,
  }) async {
    final List<String> conditions = <String>[];
    final List<dynamic> args = <dynamic>[];

    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }

    if (isActive != null) {
      conditions.add('is_active = ?');
      args.add(isActive);
    }

    final String? where = conditions.isNotEmpty
        ? conditions.join(' AND ')
        : null;

    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goals_details',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
    );
    return _hydrateGoalsWithCheckpoints(results);
  }

  Future<GoalModel> getGoalById({required int id}) async {
    final List<String> conditions = <String>[];
    final List<dynamic> args = <dynamic>[];

    conditions.add('id = ?');
    args.add(id);

    final String? where = conditions.isNotEmpty
        ? conditions.join(' AND ')
        : null;

    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goals_details',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
    );

    if (results.isEmpty) {
      throw Exception('Goal with id $id not found');
    }

    final List<GoalModel> goals = await _hydrateGoalsWithCheckpoints(results);
    return goals.first;
  }

  /// Helper: Fetch checkpoints for multiple goals and combine with goal data
  Future<List<GoalModel>> _hydrateGoalsWithCheckpoints(
    List<Map<String, dynamic>> goalMaps,
  ) async {
    if (goalMaps.isEmpty) {
      return <GoalModel>[];
    }

    // Collect all goal IDs
    final List<int> goalIds =
        goalMaps.map((Map<String, dynamic> m) => m['id'] as int).toList();

    // Fetch all checkpoints in one query using IN clause
    final List<Map<String, dynamic>> checkpointMaps =
        await _db.query(
      table: 'goal_checkpoints',
      where: 'goal_id IN (${List<String>.filled(goalIds.length, '?').join(', ')})',
      whereArgs: goalIds,
      orderBy: 'position ASC',
    );

    // Map checkpoints by goal ID for easy lookup
    final Map<int, List<GoalCheckpoint>> checkpointsByGoal =
        <int, List<GoalCheckpoint>>{};
    for (final Map<String, dynamic> cpMap in checkpointMaps) {
      final int goalId = cpMap['goal_id'] as int;
      checkpointsByGoal.putIfAbsent(goalId, () => <GoalCheckpoint>[]);
      checkpointsByGoal[goalId]!.add(GoalCheckpoint.fromMap(cpMap));
    }

    // Build GoalModels with their checkpoints
    return goalMaps.map((Map<String, dynamic> goalMap) {
      final int goalId = goalMap['id'] as int;
      final List<GoalCheckpoint> checkpoints =
          checkpointsByGoal[goalId] ?? <GoalCheckpoint>[];
      return GoalModel.fromDetailsMap(
        goalMap,
        checkpoints: checkpoints,
      );
    }).toList();
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
  Future<void> updateGoal(GoalModel goal) async {
    // Update goal data using the model's toMap method
    final Map<String, dynamic> goalData = goal.toMap();
    goalData['updated_at'] = DateTime.now().toIso8601String();
    goalData.remove('id'); // Don't update the ID field

    await _db.update(
      table: 'goals',
      values: goalData,
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
