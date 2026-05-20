/// Represents the status of a goal at a checkpoint
enum CheckpointStatus {
  fulfilled('Goal Fulfilled'),
  skipped('Goal Skipped'),
  dropped('Goal Dropped');

  const CheckpointStatus(this.displayName);

  final String displayName;

  /// Get icon for status
  String get icon {
    switch (this) {
      case CheckpointStatus.fulfilled:
        return 'check_circle';
      case CheckpointStatus.skipped:
        return 'skip_next';
      case CheckpointStatus.dropped:
        return 'cancel';
    }
  }

  /// Get color variant for status
  String get colorVariant {
    switch (this) {
      case CheckpointStatus.fulfilled:
        return 'primary-fixed-dim';
      case CheckpointStatus.skipped:
        return 'on-surface-variant';
      case CheckpointStatus.dropped:
        return 'error';
    }
  }
}

/// Model for inserting new checkpoint events into the database
class AddCheckpointEvent {
  AddCheckpointEvent({
    required this.goalId,
    required this.status,
    this.dataValue,
    this.notes,
    DateTime? eventDateTime,
    this.wasAlerted = 0,
    this.startedByUser = 1,
  }) : eventDateTime = eventDateTime ?? DateTime.now();

  final int goalId;
  final CheckpointStatus status;
  final String? dataValue;
  final String? notes;
  final DateTime eventDateTime;
  final int wasAlerted;
  final int startedByUser;

  /// Get the boolean flags based on the status
  int get isSkipped => status == CheckpointStatus.skipped ? 1 : 0;
  int get isFinished => status == CheckpointStatus.fulfilled ? 1 : 0;
  int get wasDropped => status == CheckpointStatus.dropped ? 1 : 0;

  /// Convert to database map for insertion
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'goal_id': goalId,
      'event_datetime': eventDateTime.toIso8601String(),
      'data_value': dataValue,
      'was_alerted': wasAlerted,
      'started_by_user': startedByUser,
      'is_skipped': isSkipped,
      'is_finished': isFinished,
      'was_dropped': wasDropped,
      'notes': notes,
    };
  }

  @override
  String toString() =>
      'AddCheckpointEvent(goalId: $goalId, status: ${status.displayName}, notes: $notes)';
}

/// Model representing a checkpoint event retrieved from the database
class CheckpointEventModel {
  CheckpointEventModel({
    required this.id,
    required this.goalId,
    required this.eventDateTime,
    required this.status,
    this.dataValue,
    this.notes,
    this.wasAlerted = false,
    this.startedByUser = true,
  });

  final int id;
  final int goalId;
  final DateTime eventDateTime;
  final CheckpointStatus status;
  final String? dataValue;
  final String? notes;
  final bool wasAlerted;
  final bool startedByUser;

  /// Create a CheckpointEventModel from a database map
  factory CheckpointEventModel.fromMap(Map<String, dynamic> map) {
    final bool isFinished = (map['is_finished'] as int?) == 1;
    final bool isSkipped = (map['is_skipped'] as int?) == 1;
    final bool wasDropped = (map['was_dropped'] as int?) == 1;

    CheckpointStatus status;
    if (isFinished) {
      status = CheckpointStatus.fulfilled;
    } else if (isSkipped) {
      status = CheckpointStatus.skipped;
    } else if (wasDropped) {
      status = CheckpointStatus.dropped;
    } else {
      status = CheckpointStatus.skipped; // Default fallback
    }

    return CheckpointEventModel(
      id: map['id'] as int,
      goalId: map['goal_id'] as int,
      eventDateTime: DateTime.parse(map['event_datetime'] as String),
      dataValue: map['data_value'] as String?,
      notes: map['notes'] as String?,
      wasAlerted: (map['was_alerted'] as int?) == 1,
      startedByUser: (map['started_by_user'] as int?) == 1,
      status: status,
    );
  }

  @override
  String toString() =>
      'CheckpointEventModel(id: $id, goalId: $goalId, status: ${status.displayName}, eventDateTime: $eventDateTime)';
}
