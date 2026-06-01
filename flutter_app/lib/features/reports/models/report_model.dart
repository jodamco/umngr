import 'dart:convert';

import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/shared/enums.dart';

String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

/// Expected event count for [g] within a 7-day window, following the same
/// per-cycle rules as [EfficiencyBLL.calculateTotalOccurrences].
double _weeklyExpected(ReportGoal g) {
  return switch (g.cycle) {
    'daily' => (g.occurrences ?? 1) * 7.0,
    'weekly' => g.activeDays.isEmpty ? 1.0 : g.activeDays.length.toDouble(),
    'bi_weekly' => g.activeDays.isEmpty ? 0.5 : g.activeDays.length / 2.0,
    'monthly' => 7.0 / 30.0,
    _ => 1.0,
  };
}

/// Lightweight goal representation used within the reports context.
/// Only holds what reports actually need — avoids pulling full [GoalModel].
class ReportGoal {
  const ReportGoal({
    required this.id,
    required this.name,
    required this.category,
    required this.cycle,
    required this.activeDays,
    required this.dataMetricType,
    this.occurrences,
  });

  final int id;
  final String name;
  final String category;
  final String cycle;
  final List<String> activeDays;
  final GoalDataMetricType dataMetricType;
  final int? occurrences;

  factory ReportGoal.fromMap(Map<String, dynamic> map) {
    final String? activeDaysStr = map['active_days'] as String?;
    final List<String> activeDays = <String>[];
    if (activeDaysStr != null && activeDaysStr.isNotEmpty) {
      try {
        final List<dynamic> decoded =
            jsonDecode(activeDaysStr) as List<dynamic>;
        activeDays.addAll(decoded.map((dynamic d) => d.toString()));
      } catch (_) {}
    }
    return ReportGoal(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String? ?? '',
      cycle: map['cycle'] as String,
      activeDays: activeDays,
      dataMetricType: GoalDataMetricType.fromString(
        map['data_metric_type'] as String? ?? 'nullSet',
      ),
      occurrences: map['occurrences'] as int?,
    );
  }
}

/// Aggregated data model for the reports feature.
///
/// All raw data is stored as-is; metrics are derived lazily as getters so the
/// view can read what it needs without the DAL or view duplicating logic.
class ReportOverviewModel {
  const ReportOverviewModel({
    required this.goals,
    required this.periodEvents,
    required this.periodStart,
    required this.today,
  });

  /// Active goals snapshot.
  final List<ReportGoal> goals;

  /// All checkpoint events within the reporting period, newest first.
  final List<CheckpointEventModel> periodEvents;

  /// Inclusive start of the 35-day window.
  final DateTime periodStart;

  /// Normalised "today" (midnight, no time component).
  final DateTime today;

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  Map<int, String> get goalNames => <int, String>{
    for (final ReportGoal g in goals) g.id: g.name,
  };

  // ---------------------------------------------------------------------------
  // Top-level metrics
  // ---------------------------------------------------------------------------

  int get totalObligations => goals.length;

  int get totalEvents => periodEvents.length;

  // ---------------------------------------------------------------------------
  // Weekly slice
  // ---------------------------------------------------------------------------

  DateTime get _weekStart => today.subtract(const Duration(days: 6));

  List<CheckpointEventModel> get weekEvents => periodEvents
      .where((CheckpointEventModel e) => !e.eventDateTime.isBefore(_weekStart))
      .toList();

  double get weeklyCompliance {
    if (goals.isEmpty) return 0.0;
    final double expected = goals.fold(
      0.0,
      (double sum, ReportGoal g) => sum + _weeklyExpected(g),
    );
    if (expected == 0.0) return 0.0;
    return (weekEvents.length / expected).clamp(0.0, 1.0);
  }

  int get weekEventsCount => weekEvents.length;

  int get weekExpectedCount =>
      goals.fold(0.0, (double sum, ReportGoal g) => sum + _weeklyExpected(g)).round();

  String? get peakPerformer {
    final Map<int, int> counts = weekEvents
        .where((CheckpointEventModel e) => e.status == CheckpointStatus.fulfilled)
        .fold(<int, int>{}, (Map<int, int> acc, CheckpointEventModel e) =>
            acc..[e.goalId] = (acc[e.goalId] ?? 0) + 1);
    if (counts.isEmpty) return null;
    return goalNames[
      counts.entries
          .reduce((MapEntry<int, int> a, MapEntry<int, int> b) =>
              a.value >= b.value ? a : b)
          .key
    ];
  }

  String? get criticalFailure {
    // Primary: goal with most non-fulfilled events this week
    final Map<int, int> counts = weekEvents
        .where((CheckpointEventModel e) => e.status != CheckpointStatus.fulfilled)
        .fold(<int, int>{}, (Map<int, int> acc, CheckpointEventModel e) =>
            acc..[e.goalId] = (acc[e.goalId] ?? 0) + 1);
    if (counts.isNotEmpty) {
      return goalNames[
        counts.entries
            .reduce((MapEntry<int, int> a, MapEntry<int, int> b) =>
                a.value >= b.value ? a : b)
            .key
      ];
    }
    // Fallback: any active goal with no events in the reporting period
    final Set<int> goalsWithEvents =
        periodEvents.map((CheckpointEventModel e) => e.goalId).toSet();
    return goals
        .where((ReportGoal g) => !goalsWithEvents.contains(g.id))
        .firstOrNull
        ?.name;
  }

  // ---------------------------------------------------------------------------
  // Persistence matrix
  // ---------------------------------------------------------------------------

  /// Maps each day (as 'YYYY-M-D') to the number of checkpoint events logged.
  Map<String, int> get dayCountMap => periodEvents.fold(
        <String, int>{},
        (Map<String, int> acc, CheckpointEventModel e) =>
            acc..[_dayKey(e.eventDateTime)] = (acc[_dayKey(e.eventDateTime)] ?? 0) + 1,
      );

  // ---------------------------------------------------------------------------
  // Recent events (latest 10 across period)
  // ---------------------------------------------------------------------------

  List<CheckpointEventModel> get recentEvents => periodEvents.take(10).toList();
}
