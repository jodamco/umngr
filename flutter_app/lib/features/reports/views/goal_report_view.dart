import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/reports/dal/reports_dal.dart';
import 'package:micro_manager/features/reports/models/goal_report_model.dart';
import 'package:micro_manager/features/reports/views/widgets/goal_report.dart';

class GoalReportView extends StatefulWidget {
  const GoalReportView({super.key, required this.goalId});

  final int goalId;

  @override
  State<GoalReportView> createState() => _GoalReportViewState();
}

class _GoalReportViewState extends State<GoalReportView> {
  late final ReportsDAL _dal;
  late Future<GoalReportModel> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dal = getIt<ReportsDAL>();
    _dataFuture = _dal.getGoalReport(widget.goalId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoalReportModel>(
      future: _dataFuture,
      builder: (BuildContext context, AsyncSnapshot<GoalReportModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                MicroMngrTheme.primaryFixedDim,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR: ${snapshot.error}',
              style: const TextStyle(color: MicroMngrTheme.error),
            ),
          );
        }

        final GoalReportModel data = snapshot.data!;

        return RefreshIndicator(
          color: MicroMngrTheme.primaryFixedDim,
          backgroundColor: MicroMngrTheme.surfaceContainer,
          onRefresh: () async {
            setState(() {
              _dataFuture = _dal.getGoalReport(widget.goalId);
            });
            await _dataFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TitleSection(data: data),
                const SizedBox(height: 24),
                MetricChartSection(data: data),
                const SizedBox(height: 16),
                _AggregateMetricCard(data: data),
                const SizedBox(height: 16),
                _SystemObservationCard(data: data),
                const SizedBox(height: 24),
                _CheckpointHistorySection(events: data.recentEvents),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title section
// ─────────────────────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.data});

  final GoalReportModel data;

  String get _protocolId =>
      'PROTOCOL_${data.goal.id.toString().padLeft(2, '0')}';

  String get _categoryLabel => data.goal.category.toUpperCase();

  String get _statusLabel {
    if (data.events.isEmpty) return 'DORMANT';
    if (data.weeklyCompliance >= 0.8) return 'OPTIMAL';
    if (data.weeklyCompliance >= 0.5) return 'STABLE';
    return 'CRITICAL';
  }

  Color get _statusColor {
    if (data.events.isEmpty) return MicroMngrTheme.onSurfaceVariant;
    if (data.weeklyCompliance >= 0.5) return MicroMngrTheme.primaryFixedDim;
    return MicroMngrTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: MicroMngrTheme.primaryFixedDim, width: 4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                _protocolId,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: MicroMngrTheme.primaryFixedDim,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: MicroMngrTheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.goal.name.toUpperCase(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: MicroMngrTheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _StatusDot(color: _statusColor),
              const SizedBox(width: 6),
              Text(
                'STATUS: $_statusLabel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.0,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aggregate metric card
// ─────────────────────────────────────────────────────────────────────────────

class _AggregateMetricCard extends StatelessWidget {
  const _AggregateMetricCard({required this.data});

  final GoalReportModel data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainer,
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'AGGREGATE_SUM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 1.0,
              color: MicroMngrTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TOTAL_METRIC',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: MicroMngrTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                data.aggregateValueStr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: MicroMngrTheme.primaryFixedDim,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.aggregateUnit,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MicroMngrTheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: MicroMngrTheme.outlineVariant.withValues(alpha: 0.4),
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                data.aggregateRatioLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
              Text(
                data.aggregateRatio.toStringAsFixed(2),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: MicroMngrTheme.primaryFixedDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            child: LinearProgressIndicator(
              value: data.aggregateRatio,
              backgroundColor: MicroMngrTheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                MicroMngrTheme.primaryFixedDim,
              ),
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System observation card
// ─────────────────────────────────────────────────────────────────────────────

class _SystemObservationCard extends StatefulWidget {
  const _SystemObservationCard({required this.data});

  final GoalReportModel data;

  @override
  State<_SystemObservationCard> createState() => _SystemObservationCardState();
}

class _SystemObservationCardState extends State<_SystemObservationCard> {
  bool _acknowledged = false;

  String get _observation {
    if (widget.data.chartProtocol == GoalChartProtocol.scatter) {
      return '"YOUR PATTERN OF ERRATIC PRODUCTIVITY SUGGESTS A FASCINATING STRUGGLE BETWEEN AMBITION AND ENTROPY."';
    }
    if (widget.data.events.isEmpty) {
      return '"ZERO OUTPUT REGISTERED. THE PROTOCOL NOTES YOUR ABSENCE. THE PROTOCOL IS DISAPPOINTED."';
    }
    if (widget.data.weeklyCompliance >= 0.8) {
      return '"IMPRESSIVE METRIC. STILL NOT ENOUGH. THE PROTOCOL DEMANDS MORE."';
    }
    if (widget.data.weeklyCompliance >= 0.5) {
      return '"COMPLIANCE MODERATE. THE DIFFERENCE BETWEEN ACCEPTABLE AND FORGETTABLE IS RAZOR-THIN."';
    }
    return '"OBLIGATION LOAD DETECTED. EXECUTION INCOMPLETE. YOUR EXCUSES ARE LOGGED AND IGNORED."';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainerLow,
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MicroMngrTheme.surfaceContainerHighest,
              border: Border.all(color: MicroMngrTheme.outlineVariant),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              size: 20,
              color: MicroMngrTheme.primaryFixedDim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SYSTEM_OBSERVATION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: MicroMngrTheme.primaryFixedDim,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _observation,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: MicroMngrTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _acknowledged = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _acknowledged
                            ? MicroMngrTheme.primaryFixedDim
                            : MicroMngrTheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      _acknowledged ? 'NOTED.' : 'ACKNOWLEDGE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        color: _acknowledged
                            ? MicroMngrTheme.primaryFixedDim
                            : MicroMngrTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkpoint history section
// ─────────────────────────────────────────────────────────────────────────────

class _CheckpointHistorySection extends StatelessWidget {
  const _CheckpointHistorySection({required this.events});

  final List<CheckpointEventModel> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: MicroMngrTheme.surfaceContainerHigh,
            border: Border(
              top: BorderSide(color: MicroMngrTheme.outlineVariant),
              left: BorderSide(color: MicroMngrTheme.outlineVariant),
              right: BorderSide(color: MicroMngrTheme.outlineVariant),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'CHECKPOINT HISTORY [L${events.length}]',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
              const Icon(
                Icons.history,
                size: 18,
                color: MicroMngrTheme.outlineVariant,
              ),
            ],
          ),
        ),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MicroMngrTheme.surfaceContainer,
              border: Border.all(color: MicroMngrTheme.outlineVariant),
            ),
            child: Center(
              child: Text(
                'NO_EVENTS_LOGGED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...events.map(
            (CheckpointEventModel e) => _CheckpointHistoryRow(event: e),
          ),
      ],
    );
  }
}

class _CheckpointHistoryRow extends StatelessWidget {
  const _CheckpointHistoryRow({required this.event});

  final CheckpointEventModel event;

  Color get _iconColor => switch (event.status) {
    CheckpointStatus.fulfilled => MicroMngrTheme.primaryFixedDim,
    CheckpointStatus.skipped => MicroMngrTheme.onSurfaceVariant,
    CheckpointStatus.dropped => MicroMngrTheme.error,
  };

  IconData get _icon => switch (event.status) {
    CheckpointStatus.fulfilled => Icons.check_circle,
    CheckpointStatus.skipped => Icons.remove_circle_outline,
    CheckpointStatus.dropped => Icons.cancel,
  };

  String get _statusLabel => switch (event.status) {
    CheckpointStatus.fulfilled => 'FULFILLED',
    CheckpointStatus.skipped => 'SKIPPED',
    CheckpointStatus.dropped => 'DROPPED',
  };

  Color get _statusTextColor => switch (event.status) {
    CheckpointStatus.fulfilled => MicroMngrTheme.primaryFixedDim,
    CheckpointStatus.skipped => MicroMngrTheme.onSurfaceVariant,
    CheckpointStatus.dropped => MicroMngrTheme.error,
  };

  Color get _statusBgColor => switch (event.status) {
    CheckpointStatus.fulfilled => const Color(0xFF002019),
    CheckpointStatus.skipped => MicroMngrTheme.surfaceContainerHighest,
    CheckpointStatus.dropped => MicroMngrTheme.error.withValues(alpha: 0.15),
  };

  String get _dateStr {
    final DateTime dt = event.eventDateTime;
    final String year = dt.year.toString();
    final String month = dt.month.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String get _timeStr {
    final DateTime dt = event.eventDateTime;
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    final String s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _description {
    if (event.notes != null && event.notes!.isNotEmpty) return event.notes!;
    return switch (event.status) {
      CheckpointStatus.fulfilled => 'Checkpoint completed successfully.',
      CheckpointStatus.skipped => 'Checkpoint skipped for this cycle.',
      CheckpointStatus.dropped => 'Obligation dropped — cycle terminated.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainer,
        border: Border(
          left: const BorderSide(color: MicroMngrTheme.outlineVariant),
          right: const BorderSide(color: MicroMngrTheme.outlineVariant),
          bottom: BorderSide(
            color: MicroMngrTheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Opacity(
        opacity: event.status == CheckpointStatus.fulfilled ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_icon, size: 18, color: _iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _dateStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: MicroMngrTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _timeStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.0,
                        color: MicroMngrTheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  _description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MicroMngrTheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                color: _statusBgColor,
                child: Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: _statusTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
