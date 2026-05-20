import 'package:micro_manager/core/services/db/db_abstraction.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';

/// Data Access Layer for Checkpoint Events
/// Handles all database operations related to checkpoint events
class CheckpointEventsDAL {
  final DbAbstraction _db;

  CheckpointEventsDAL(this._db);

  /// Save a new checkpoint event to the database
  /// Returns the ID of the created checkpoint event
  Future<int> createCheckpointEvent(AddCheckpointEvent checkpoint) async {
    return await _db.insert(
      table: 'goal_events',
      values: checkpoint.toMap(),
    );
  }

  /// Get all checkpoint events for a specific goal
  /// Returns events sorted by event_datetime in descending order (most recent first)
  Future<List<CheckpointEventModel>> getCheckpointEventsByGoal(
    int goalId,
  ) async {
    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goal_events',
      where: 'goal_id = ?',
      whereArgs: <dynamic>[goalId],
      orderBy: 'event_datetime DESC',
    );

    return results.map(CheckpointEventModel.fromMap).toList();
  }

  /// Get checkpoint events for a goal with optional date range filter
  /// Returns events sorted by event_datetime in descending order (most recent first)
  Future<List<CheckpointEventModel>> getCheckpointEventsByGoalAndDateRange(
    int goalId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<Map<String, dynamic>> results = await _db.query(
      table: 'goal_events',
      where: 'goal_id = ? AND event_datetime >= ? AND event_datetime <= ?',
      whereArgs: <dynamic>[
        goalId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'event_datetime DESC',
    );

    return results.map(CheckpointEventModel.fromMap).toList();
  }

  /// Get the count of checkpoint events for a goal
  Future<int> getCheckpointEventCount(int goalId) async {
    final List<Map<String, dynamic>> result = await _db.query(
      table: 'goal_events',
      where: 'goal_id = ?',
      whereArgs: <dynamic>[goalId],
    );
    return result.length;
  }
}
