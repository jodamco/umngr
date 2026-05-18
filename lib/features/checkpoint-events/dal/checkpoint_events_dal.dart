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
  Future<List<Map<String, dynamic>>> getCheckpointEventsByGoal(
    int goalId,
  ) async {
    return await _db.query(
      table: 'goal_events',
      where: 'goal_id = ?',
      whereArgs: <dynamic>[goalId],
    );
  }

  /// Get checkpoint events for a goal with optional date range filter
  Future<List<Map<String, dynamic>>> getCheckpointEventsByGoalAndDateRange(
    int goalId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _db.query(
      table: 'goal_events',
      where: 'goal_id = ? AND event_datetime >= ? AND event_datetime <= ?',
      whereArgs: <dynamic>[
        goalId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );
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
