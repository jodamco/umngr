import 'package:micro_manager/features/goals/models/goal_model.dart';

/// Business Logic Layer for computing the Efficiency Rating.
///
/// The Efficiency Rating measures how consistently the user is completing
/// checkpoints relative to the total expected occurrences across all goals.
///
/// See: knowledge_base/efficiency-rating.md for the full specification.
class EfficiencyBLL {
  /// Calculates the total expected occurrences across all provided goals.
  ///
  /// Per-cycle rules:
  /// - **daily**: contributes `occurrences` (times per day); falls back to
  ///   `checkpoints.length` when `occurrences` is null.
  /// - **weekly / bi_weekly**: contributes `activeDays.length` (number of
  ///   active days per week / bi-week); falls back to 1 when empty.
  /// - **monthly**: contributes 1 (once per month on `dayOfMonth`).
  /// - **unknown cycle**: contributes 1 as a safe fallback.
  int calculateTotalOccurrences(List<GoalModel> goals) {
    int total = 0;

    for (final GoalModel goal in goals) {
      switch (goal.cycle) {
        case 'daily':
          total += goal.occurrences ?? goal.checkpoints.length;
        case 'weekly':
        case 'bi_weekly':
          total += goal.activeDays.isEmpty ? 1 : goal.activeDays.length;
        case 'monthly':
          total += 1;
        default:
          total += 1;
      }
    }

    return total;
  }

  /// Calculates the efficiency rating as a clamped percentage in [0, 99].
  ///
  /// efficiency = (totalCheckpointEvents / totalExpectedOccurrences) × 100
  ///
  /// Clamping rules:
  /// - Values below 0 are displayed as 0.
  /// - Values above 100 are displayed as 99 (never shows a perfect 100%).
  /// - Returns 0 when there are no expected occurrences.
  double calculateEfficiency(List<GoalModel> goals) {
    final int totalOccurrences = calculateTotalOccurrences(goals);

    if (totalOccurrences == 0) return 0;

    final int totalEvents = goals.fold(
      0,
      (int sum, GoalModel goal) => sum + goal.eventCount,
    );

    final double raw = (totalEvents / totalOccurrences) * 100;

    if (raw < 0) return 0;
    if (raw > 100) return 99;

    return raw;
  }
}
