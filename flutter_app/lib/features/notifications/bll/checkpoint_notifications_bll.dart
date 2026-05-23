import 'package:micro_manager/core/services/notification/notification_tap_handler.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/features/notifications/bll/notifications_bll.dart';
import 'package:micro_manager/features/notifications/dal/notifications_dal.dart';
import 'package:micro_manager/features/notifications/models/notification_model.dart';

/// Schedules device notifications for goal checkpoints.
///
/// Each checkpoint within a goal fires on every "active day" for that goal's
/// cycle. At most [_maxAheadCount] future occurrences are kept scheduled per
/// checkpoint at any time. Call [scheduleForGoal] after a goal is created or
/// updated, and [cancelForGoal] when a goal is deleted or deactivated.
class CheckpointNotificationsBLL {
  CheckpointNotificationsBLL(this._notificationsBLL, this._dal);

  final NotificationsBLL _notificationsBLL;
  final NotificationsDAL _dal;

  static const int _maxAheadCount = 5;

  /// Cancels all existing checkpoint notifications for [goal], then schedules
  /// up to [_maxAheadCount] future occurrences in total across all checkpoints.
  ///
  /// Occurrences are collected per checkpoint (up to [_maxAheadCount] each),
  /// merged and sorted chronologically, then the first [_maxAheadCount] are
  /// scheduled in parallel.
  Future<void> scheduleForGoal(GoalModel goal) async {
    await _cancelForGoal(goal.id);

    if (goal.checkpoints.isEmpty) return;

    // Collect occurrences across all checkpoints, sort, keep the soonest N.
    final List<({GoalCheckpoint checkpoint, DateTime date})> allOccurrences =
        goal.checkpoints
            .expand(
              (GoalCheckpoint cp) => _nextOccurrences(
                goal: goal,
                checkpoint: cp,
                count: _maxAheadCount,
              ).map((DateTime d) => (checkpoint: cp, date: d)),
            )
            .toList()
          ..sort(
            (
              ({GoalCheckpoint checkpoint, DateTime date}) a,
              ({GoalCheckpoint checkpoint, DateTime date}) b,
            ) => a.date.compareTo(b.date),
          );

    await Future.wait(
      allOccurrences
          .take(_maxAheadCount)
          .map(
            (({GoalCheckpoint checkpoint, DateTime date}) entry) =>
                _notificationsBLL.scheduleNotification(
                  title: goal.name,
                  body: 'Checkpoint at ${entry.checkpoint.checkpointTime}',
                  scheduledAt: entry.date,
                  foreignId: goal.id,
                  payload: <String, dynamic>{
                    'type': NotificationPayloadType.checkpoint,
                    'goal_id': goal.id,
                    'checkpoint_id': entry.checkpoint.id,
                  },
                ),
          ),
    );
  }

  /// Cancels all pending checkpoint notifications for the goal with [goalId].
  Future<void> cancelForGoal(int goalId) => _cancelForGoal(goalId);

  /// Ensures [_maxAheadCount] notifications are scheduled for [goal].
  ///
  /// Call this on every app start. If the goal already has [_maxAheadCount]
  /// future notifications, this is a no-op. Otherwise only the missing ones
  /// are scheduled, preserving notifications already on the device.
  Future<void> topUpForGoal(GoalModel goal) async {
    if (goal.checkpoints.isEmpty) return;

    final DateTime now = DateTime.now();

    // Only count notifications that are still in the future.
    final List<NotificationModel> existing = await _dal
        .getActiveNotificationsForForeignId(goal.id, from: now);

    final int missing = _maxAheadCount - existing.length;
    if (missing <= 0) return;

    // Dates already scheduled — used to avoid duplicates.
    final Set<DateTime> alreadyScheduled =
        existing.map((NotificationModel n) => n.scheduledAt).toSet();

    // Generate candidates across all checkpoints, sort chronologically.
    final List<({GoalCheckpoint checkpoint, DateTime date})> candidates =
        goal.checkpoints
            .expand(
              (GoalCheckpoint cp) => _nextOccurrences(
                goal: goal,
                checkpoint: cp,
                count: _maxAheadCount,
              ).map((DateTime d) => (checkpoint: cp, date: d)),
            )
            .toList()
          ..sort(
            (
              ({GoalCheckpoint checkpoint, DateTime date}) a,
              ({GoalCheckpoint checkpoint, DateTime date}) b,
            ) => a.date.compareTo(b.date),
          );

    await Future.wait(
      candidates
          .where(
            (({GoalCheckpoint checkpoint, DateTime date}) e) =>
                !alreadyScheduled.contains(e.date),
          )
          .take(missing)
          .map(
            (({GoalCheckpoint checkpoint, DateTime date}) entry) =>
                _notificationsBLL.scheduleNotification(
                  title: goal.name,
                  body: 'Checkpoint at ${entry.checkpoint.checkpointTime}',
                  scheduledAt: entry.date,
                  foreignId: goal.id,
                  payload: <String, dynamic>{
                    'type': NotificationPayloadType.checkpoint,
                    'goal_id': goal.id,
                    'checkpoint_id': entry.checkpoint.id,
                  },
                ),
          ),
    );
  }

  // ─── private helpers ────────────────────────────────────────────────────────

  Future<void> _cancelForGoal(int goalId) async {
    final List<NotificationModel> existing = await _dal
        .getActiveNotificationsForForeignId(goalId);
    await Future.wait(
      existing.map(
        _notificationsBLL.cancelNotification,
      ),
    );
  }

  /// Returns the next [count] future [DateTime]s at which [checkpoint] fires
  /// for [goal], starting strictly after now.
  List<DateTime> _nextOccurrences({
    required GoalModel goal,
    required GoalCheckpoint checkpoint,
    required int count,
  }) {
    final List<String> parts = checkpoint.checkpointTime.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final DateTime now = DateTime.now();
    final List<DateTime> results = <DateTime>[];

    // Start from today at the checkpoint time; advance to tomorrow if already past.
    DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month, now.day + 1, hour, minute);
    }

    // Safety cap: never iterate beyond 2 years to avoid an infinite loop when
    // active days or dayOfMonth never align.
    final DateTime limit = now.add(const Duration(days: 730));

    while (results.length < count && candidate.isBefore(limit)) {
      if (_isActiveOn(goal, candidate)) {
        results.add(candidate);
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    return results;
  }

  /// Returns true if [date] is an active day for [goal].
  bool _isActiveOn(GoalModel goal, DateTime date) {
    switch (goal.cycle) {
      case 'daily':
        return true;

      case 'weekly':
        // activeDays stores day indices 0=Mon … 6=Sun as strings.
        // DateTime.weekday: 1=Mon … 7=Sun  →  index = weekday - 1.
        return goal.activeDays.contains((date.weekday - 1).toString());

      case 'biWeekly':
        if (!goal.activeDays.contains((date.weekday - 1).toString())) {
          return false;
        }
        return _isActiveWeek(goal.createdAt, date);

      case 'monthly':
        return date.day == goal.dayOfMonth;

      default:
        return false;
    }
  }

  /// Determines whether [date] falls in an "active" bi-weekly window.
  ///
  /// The week that contains [createdAt] (Monday-anchored) is week 0 (active).
  /// Odd weeks are skipped; even weeks are active.
  bool _isActiveWeek(DateTime createdAt, DateTime date) {
    final DateTime creationMonday = createdAt.subtract(
      Duration(days: createdAt.weekday - 1),
    );
    final DateTime dateMonday = date.subtract(Duration(days: date.weekday - 1));
    final int weeksBetween = (dateMonday.difference(creationMonday).inDays / 7)
        .round();
    return weeksBetween.isEven;
  }
}
