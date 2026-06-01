import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/reports/models/report_model.dart';
import 'package:micro_manager/shared/enums.dart';

enum GoalChartProtocol { line, donut, bar, scatter }

double _weeklyExpected(ReportGoal g) {
  return switch (g.cycle) {
    'daily' => (g.occurrences ?? 1) * 7.0,
    'weekly' => g.activeDays.isEmpty ? 1.0 : g.activeDays.length.toDouble(),
    'bi_weekly' => g.activeDays.isEmpty ? 0.5 : g.activeDays.length / 2.0,
    'monthly' => 7.0 / 30.0,
    _ => 1.0,
  };
}

/// Per-goal report data model.
///
/// Holds raw events for a single goal within a 35-day window and exposes
/// derived metrics as getters, consistent with [ReportOverviewModel].
class GoalReportModel {
  const GoalReportModel({
    required this.goal,
    required this.events,
    required this.periodStart,
    required this.today,
  });

  /// The goal being reported on.
  final ReportGoal goal;

  /// All checkpoint events for this goal within the reporting period,
  /// newest first.
  final List<CheckpointEventModel> events;

  /// Inclusive start of the 35-day window.
  final DateTime periodStart;

  /// Normalised "today" (midnight, no time component).
  final DateTime today;

  // ──────────────────────────────────────────────────────────────────────────
  // Week slice (last 7 days including today)
  // ──────────────────────────────────────────────────────────────────────────

  DateTime get _weekStart => today.subtract(const Duration(days: 6));

  List<CheckpointEventModel> get weekEvents => events
      .where((CheckpointEventModel e) => !e.eventDateTime.isBefore(_weekStart))
      .toList();

  int get weekEventsCount => weekEvents.length;

  int get weekFulfilledCount => weekEvents
      .where((CheckpointEventModel e) => e.status == CheckpointStatus.fulfilled)
      .length;

  int get weekExpectedCount => _weeklyExpected(goal).round();

  double get weeklyCompliance {
    final double expected = _weeklyExpected(goal);
    if (expected == 0) return 0;
    return (weekFulfilledCount / expected).clamp(0.0, 1.0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // L7D chart data
  // ──────────────────────────────────────────────────────────────────────────

  /// Event counts per day for the last 7 days (oldest → newest).
  List<int> get last7DayCounts => List<int>.generate(7, (int i) {
    final DateTime day = today.subtract(Duration(days: 6 - i));
    return events
        .where(
          (CheckpointEventModel e) =>
              e.eventDateTime.year == day.year &&
              e.eventDateTime.month == day.month &&
              e.eventDateTime.day == day.day,
        )
        .length;
  });

  /// Day-of-week labels for the last 7 days (oldest → newest), e.g. 'MON'.
  List<String> get last7DayLabels {
    const List<String> labels = <String>[
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];
    return List<String>.generate(7, (int i) {
      final DateTime day = today.subtract(Duration(days: 6 - i));
      return labels[day.weekday - 1];
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Recent events (last 10)
  // ──────────────────────────────────────────────────────────────────────────

  List<CheckpointEventModel> get recentEvents => events.take(10).toList();

  // ──────────────────────────────────────────────────────────────────────────
  // Chart protocol
  // ──────────────────────────────────────────────────────────────────────────

  GoalChartProtocol get chartProtocol {
    if (goal.cycle == 'daily') return GoalChartProtocol.scatter;
    return switch (goal.dataMetricType) {
      GoalDataMetricType.numericVal ||
      GoalDataMetricType.timeElapsed => GoalChartProtocol.line,
      GoalDataMetricType.boolFlag ||
      GoalDataMetricType.nullSet => GoalChartProtocol.donut,
      GoalDataMetricType.loadFactor => GoalChartProtocol.bar,
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Protocol-specific chart data
  // ──────────────────────────────────────────────────────────────────────────

  /// Per-day summed data_value for L7D (null = no data that day).
  /// Used by Protocol_01 (line chart).
  List<double?> get last7DayNumericValues => List<double?>.generate(7, (int i) {
    final DateTime day = today.subtract(Duration(days: 6 - i));
    final List<double> vals = events
        .where(
          (CheckpointEventModel e) =>
              e.eventDateTime.year == day.year &&
              e.eventDateTime.month == day.month &&
              e.eventDateTime.day == day.day &&
              e.dataValue != null,
        )
        .map((CheckpointEventModel e) => double.tryParse(e.dataValue!))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((double a, double b) => a + b);
  });

  /// Per-day average load factor for L7D (0.0 = no data that day). Values 0–100.
  /// Used by Protocol_03 (bar chart).
  List<double> get last7DayLoadValues => List<double>.generate(7, (int i) {
    final DateTime day = today.subtract(Duration(days: 6 - i));
    final List<double> vals = events
        .where(
          (CheckpointEventModel e) =>
              e.eventDateTime.year == day.year &&
              e.eventDateTime.month == day.month &&
              e.eventDateTime.day == day.day &&
              e.dataValue != null,
        )
        .map((CheckpointEventModel e) => double.tryParse(e.dataValue!))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return 0.0;
    return vals.reduce((double a, double b) => a + b) / vals.length;
  });

  /// Scatter plot data points for the current calendar week (Mon–Sun).
  /// Each record is (weekdayIndex: 0=Mon…6=Sun, yValue).
  /// Events without a parseable data_value are ranked within the day (1, 2, 3…)
  /// to create a visible vertical cluster.
  List<(int, double)> get scatterPoints {
    final int offset = today.weekday - 1;
    final DateTime weekMon = today.subtract(Duration(days: offset));
    final DateTime weekSunEnd = weekMon.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    final List<CheckpointEventModel> thisWeek = events
        .where(
          (CheckpointEventModel e) =>
              !e.eventDateTime.isBefore(weekMon) &&
              !e.eventDateTime.isAfter(weekSunEnd),
        )
        .toList()
      ..sort(
        (CheckpointEventModel a, CheckpointEventModel b) =>
            a.eventDateTime.compareTo(b.eventDateTime),
      );

    final Map<int, int> dayRank = <int, int>{};
    final List<(int, double)> points = <(int, double)>[];
    for (final CheckpointEventModel e in thisWeek) {
      final int d = e.eventDateTime.weekday - 1;
      dayRank[d] = (dayRank[d] ?? 0) + 1;
      final double y = e.dataValue != null
          ? (double.tryParse(e.dataValue!) ?? dayRank[d]!.toDouble())
          : dayRank[d]!.toDouble();
      points.add((d, y));
    }
    return points;
  }

  /// Fixed Y-axis max for the scatter chart.
  /// 100.0 for loadFactor goals; null = derive dynamically from data.
  double? get scatterYMax =>
      goal.dataMetricType == GoalDataMetricType.loadFactor ? 100.0 : null;

  // ──────────────────────────────────────────────────────────────────────────
  // Aggregate metric card helpers
  // ──────────────────────────────────────────────────────────────────────────

  String get aggregateValueStr {
    switch (chartProtocol) {
      case GoalChartProtocol.line:
        final List<double> nonNull = last7DayNumericValues
            .whereType<double>()
            .toList();
        if (nonNull.isEmpty) return '—';
        return nonNull.reduce((double a, double b) => a + b).toStringAsFixed(1);
      case GoalChartProtocol.bar:
        final List<double> active = last7DayLoadValues
            .where((double v) => v > 0)
            .toList();
        if (active.isEmpty) return '—';
        return (active.reduce((double a, double b) => a + b) / active.length)
            .toStringAsFixed(0);
      case GoalChartProtocol.scatter:
        if (goal.dataMetricType == GoalDataMetricType.nullSet ||
            goal.dataMetricType == GoalDataMetricType.boolFlag) {
          return weekEventsCount.toString();
        }
        final List<double> sVals =
            scatterPoints.map((p) => p.$2).toList();
        if (sVals.isEmpty) return '\u2014';
        return sVals
            .reduce((double a, double b) => a + b)
            .toStringAsFixed(1);
      case GoalChartProtocol.donut:
        return weekEventsCount.toString();
    }
  }

  String get aggregateUnit => switch (chartProtocol) {
    GoalChartProtocol.line =>
      goal.dataMetricType == GoalDataMetricType.timeElapsed ? 'MINS' : 'TOTAL',
    GoalChartProtocol.bar => 'AVG %',
    GoalChartProtocol.donut => 'EVENTS',
    GoalChartProtocol.scatter => switch (goal.dataMetricType) {
        GoalDataMetricType.nullSet || GoalDataMetricType.boolFlag => 'EVENTS',
        GoalDataMetricType.timeElapsed => 'MINS',
        _ => 'TOTAL',
      },
  };

  String get aggregateRatioLabel => switch (chartProtocol) {
    GoalChartProtocol.bar => 'LOAD_INDEX',
    _ => 'EFFICIENCY_RATIO',
  };

  double get aggregateRatio {
    if (chartProtocol == GoalChartProtocol.bar) {
      final List<double> active = last7DayLoadValues
          .where((double v) => v > 0)
          .toList();
      if (active.isEmpty) return 0.0;
      return (active.reduce((double a, double b) => a + b) /
              (active.length * 100.0))
          .clamp(0.0, 1.0);
    }
    return weeklyCompliance;
  }
}
