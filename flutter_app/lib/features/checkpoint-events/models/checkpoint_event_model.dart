/// Represents the status of an obligation at a checkpoint
enum CheckpointStatus {
  fulfilled('Obligation Fulfilled'),
  skipped('Obligation Skipped'),
  dropped('Obligation Dropped');

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
