import 'package:micro_manager/core/services/db/db_abstraction.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/reports/models/goal_report_model.dart';
import 'package:micro_manager/features/reports/models/report_model.dart';

/// Data Access Layer for Reports.
/// Issues a single pair of parallel queries (goals + events) for a 35-day
/// window and returns a [ReportOverviewModel] that owns all derived computations.
class ReportsDAL {
  ReportsDAL(this._db);

  final DbAbstraction _db;

  Future<ReportOverviewModel> getReportData() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime periodStart = today.subtract(const Duration(days: 34));
    final DateTime periodEnd = today.add(const Duration(days: 1));

    final (
      List<Map<String, dynamic>> goalMaps,
      List<Map<String, dynamic>> eventMaps,
    ) = await (
      _db.query(
        table: 'goals',
        where: 'is_active = ?',
        whereArgs: <dynamic>[1],
      ),
      _db.query(
        table: 'goal_events',
        where: 'event_datetime >= ? AND event_datetime < ?',
        whereArgs: <dynamic>[
          periodStart.toIso8601String(),
          periodEnd.toIso8601String(),
        ],
        orderBy: 'event_datetime DESC',
      ),
    ).wait;

    return ReportOverviewModel(
      goals: goalMaps.map(ReportGoal.fromMap).toList(),
      periodEvents: eventMaps.map(CheckpointEventModel.fromMap).toList(),
      periodStart: periodStart,
      today: today,
    );
  }

  Future<GoalReportModel> getGoalReport(int goalId) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime periodStart = today.subtract(const Duration(days: 34));
    final DateTime periodEnd = today.add(const Duration(days: 1));

    final (
      List<Map<String, dynamic>> goalMaps,
      List<Map<String, dynamic>> eventMaps,
    ) = await (
      _db.query(
        table: 'goals',
        where: 'id = ?',
        whereArgs: <dynamic>[goalId],
      ),
      _db.query(
        table: 'goal_events',
        where: 'goal_id = ? AND event_datetime >= ? AND event_datetime < ?',
        whereArgs: <dynamic>[
          goalId,
          periodStart.toIso8601String(),
          periodEnd.toIso8601String(),
        ],
        orderBy: 'event_datetime DESC',
      ),
    ).wait;

    return GoalReportModel(
      goal: ReportGoal.fromMap(goalMaps.first),
      events: eventMaps.map(CheckpointEventModel.fromMap).toList(),
      periodStart: periodStart,
      today: today,
    );
  }
}
