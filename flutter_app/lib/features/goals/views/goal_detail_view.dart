import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';
import 'package:micro_manager/widgets/micro_mngr_app_bar.dart';
import 'package:micro_manager/features/checkpoint-events/dal/checkpoint_events_dal.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/shared/enums.dart';

class GoalDetailView extends StatefulWidget {
  final int goalId;

  const GoalDetailView({
    required this.goalId,
    super.key,
  });

  @override
  State<GoalDetailView> createState() => _GoalDetailViewState();
}

class _GoalDetailViewState extends State<GoalDetailView> {
  late final GoalsDAL _goalsDAL;
  late final CheckpointEventsDAL _checkpointEventsDAL;
  late Future<({GoalModel? goal, List<CheckpointEventModel> events})>
  _dataFuture;

  @override
  void initState() {
    super.initState();
    _goalsDAL = getIt<GoalsDAL>();
    _checkpointEventsDAL = getIt<CheckpointEventsDAL>();
    _dataFuture = _fetchData();
  }

  Future<({GoalModel? goal, List<CheckpointEventModel> events})>
  _fetchData() async {
    final GoalModel goal = await _goalsDAL.getGoalById(id: widget.goalId);
    final List<CheckpointEventModel> events = await _checkpointEventsDAL
        .getCheckpointEventsByGoal(goal.id);

    return (goal: goal, events: events);
  }

  double _calculatePeakLoadIndex(final GoalModel goal) {
    if (goal.eventCount == 0) return 0;
    // Calculate peak load based on event count and frequency
    final double baseScore = goal.eventCount / 10;
    return baseScore.clamp(0, 1.0);
  }

  Color _getStatusColor(final CheckpointStatus status) {
    return switch (status) {
      CheckpointStatus.fulfilled => MicroMngrTheme.primaryFixedDim,
      CheckpointStatus.skipped => MicroMngrTheme.tertiaryFixedDim,
      CheckpointStatus.dropped => MicroMngrTheme.error,
    };
  }

  String _formatEventDateTime(final String dateTimeStr) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr);
      final String date =
          '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final String time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
      return '${date}_$time';
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<
      ({
        GoalModel? goal,
        List<CheckpointEventModel> events,
      })
    >(
      future: _dataFuture,
      builder:
          (
            final BuildContext context,
            final AsyncSnapshot<
              ({GoalModel? goal, List<CheckpointEventModel> events})
            >
            snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                appBar: MicroMngrAppBar(
                  title: 'PROTOCOL_OVERVIEW',
                  showBackButton: true,
                ),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      MicroMngrTheme.primary,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data?.goal == null) {
              return Scaffold(
                appBar: const MicroMngrAppBar(
                  title: 'PROTOCOL_OVERVIEW',
                  showBackButton: true,
                ),
                body: Center(
                  child: Text('Error loading goal: ${snapshot.error}'),
                ),
              );
            }

            final GoalModel goal = snapshot.data!.goal!;
            final List<CheckpointEventModel> events = snapshot.data!.events;

            return Scaffold(
              appBar: const MicroMngrAppBar(
                title: 'PROTOCOL_OVERVIEW',
                showBackButton: true,
              ),
              backgroundColor: MicroMngrTheme.background,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () =>
                    context.push('/reports/goals/${goal.id}'),
                backgroundColor: MicroMngrTheme.surfaceContainerHigh,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: MicroMngrTheme.outlineVariant),
                ),
                elevation: 0,
                icon: const Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: MicroMngrTheme.primaryFixedDim,
                ),
                label: Text(
                  'VIEW_REPORT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: MicroMngrTheme.primaryFixedDim,
                  ),
                ),
              ),
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ).copyWith(top: 16, bottom: 96),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        <Widget>[
                          // Hero Section
                          _GoalHeroSection(
                            goal: goal,
                            peakLoadIndex: _calculatePeakLoadIndex(goal),
                          ),
                          const SizedBox(height: 24),

                          // Configuration Summary
                          _ConfigurationSection(goal: goal),
                          const SizedBox(height: 24),

                          // Historical Log Entries
                          _HistoricalLogSection(
                            events: events,
                            getStatusColor: _getStatusColor,
                            formatEventDateTime: _formatEventDateTime,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}

class _GoalHeroSection extends StatelessWidget {
  final GoalModel goal;
  final double peakLoadIndex;

  const _GoalHeroSection({
    required this.goal,
    required this.peakLoadIndex,
  });

  String generateIdFromGoalId(int goalId) {
    final String input = 'goal_$goalId';
    return md5.convert(input.codeUnits).toString();
  }

  String _getActiveCycleText() {
    return switch (goal.cycle) {
      'daily' => 'DAILY_BURDEN',
      'weekly' => 'WEEKLY_MANDATE',
      'biWeekly' => 'BIWEEKLY_TASK',
      'monthly' => 'MONTHLY_PROTOCOL',
      _ => 'ACTIVE_PROTOCOL',
    };
  }

  List<int> _parseActiveDays(final List<String> activeDays) {
    return activeDays.map((final String day) {
      try {
        return int.parse(day);
      } catch (_) {
        return 0;
      }
    }).toList();
  }

  String _getDayLetter(final int dayIndex) {
    const List<String> days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[dayIndex % 7];
  }

  @override
  Widget build(final BuildContext context) {
    final GoalCategory category = GoalCategory.fromDbValue(goal.category);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: MicroMngrTheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'GOAL NAME',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.border,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'v${generateIdFromGoalId(goal.id).substring(0, 8)}-STABLE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.border,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          // Goal identity
          const SizedBox(height: 4),
          Text(
            goal.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: MicroMngrTheme.primaryFixedDim,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Category with icon
          Row(
            children: <Widget>[
              const Icon(
                Icons.category,
                size: 14,
                color: MicroMngrTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${category.value} (${category.label})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          const Divider(
            color: MicroMngrTheme.outlineVariant,
            height: 1,
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ACTIVE_CYCLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: MicroMngrTheme.border,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getActiveCycleText(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MicroMngrTheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Builder(
                  builder: (BuildContext _) {
                    // Cycle-specific details
                    if (goal.cycle == 'daily') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'DAILY_OCCURRENCES',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: MicroMngrTheme.border,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goal.occurrences ?? 1}x',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: MicroMngrTheme.onBackground,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      );
                    }

                    if (goal.cycle == 'weekly' || goal.cycle == 'biWeekly') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ACTIVE_DAYS',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: MicroMngrTheme.border,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _parseActiveDays(goal.activeDays)
                                .map(
                                  (final int dayIndex) => Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: MicroMngrTheme.primaryFixedDim,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getDayLetter(dayIndex),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: MicroMngrTheme.primaryFixedDim,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MONTHLY_DATE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: MicroMngrTheme.border,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Day ${goal.dayOfMonth ?? 1}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: MicroMngrTheme.onBackground,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigurationSection extends StatelessWidget {
  final GoalModel goal;

  const _ConfigurationSection({
    required this.goal,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'CONFIGURATION_SUMMARY.CFG',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: MicroMngrTheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 130.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12.0,
            children: <Widget>[
              Expanded(
                child: _CheckpointScheduleCard(goal: goal),
              ),
              _MetricProtocolCard(goal: goal),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricProtocolCard extends StatelessWidget {
  final GoalModel goal;

  const _MetricProtocolCard({
    required this.goal,
  });

  @override
  Widget build(final BuildContext context) {
    final String metricLabel = switch (goal.dataMetricType) {
      GoalDataMetricType.nullSet => 'None',
      GoalDataMetricType.numericVal => 'Number',
      GoalDataMetricType.boolFlag => 'Yes or No',
      GoalDataMetricType.timeElapsed => 'Time',
      GoalDataMetricType.loadFactor => 'Percentage',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'METRIC_PROTOCOL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: MicroMngrTheme.border,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UNIT: ${goal.dataMetricType.typeLabel}',
            style: TextStyle(
              fontSize: 8,
              color: MicroMngrTheme.onBackground.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Label: $metricLabel',
            style: const TextStyle(
              fontSize: 11,
              color: MicroMngrTheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointScheduleCard extends StatelessWidget {
  final GoalModel goal;

  const _CheckpointScheduleCard({
    required this.goal,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CHECKPOINT_SCHEDULE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: MicroMngrTheme.border,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goal.checkpoints
                .map(
                  (final GoalCheckpoint cp) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: MicroMngrTheme.outlineVariant,
                      ),
                      color: MicroMngrTheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      cp.checkpointTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: MicroMngrTheme.onBackground,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HistoricalLogSection extends StatefulWidget {
  final List<CheckpointEventModel> events;
  final Color Function(CheckpointStatus) getStatusColor;
  final String Function(String) formatEventDateTime;

  const _HistoricalLogSection({
    required this.events,
    required this.getStatusColor,
    required this.formatEventDateTime,
  });

  @override
  State<_HistoricalLogSection> createState() => _HistoricalLogSectionState();
}

class _HistoricalLogSectionState extends State<_HistoricalLogSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.history,
              size: 16,
              color: MicroMngrTheme.onBackground,
            ),
            SizedBox(width: 8),
            Text(
              'HISTORICAL_LOG_ENTRIES.TXT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: MicroMngrTheme.onBackground,
              ),
            ),
          ],
        ),
        const Divider(
          color: MicroMngrTheme.outlineVariant,
        ),
        const SizedBox(height: 4),
        if (widget.events.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: MicroMngrTheme.outlineVariant),
            ),
            child: const Text(
              'No checkpoint events recorded yet.',
              style: TextStyle(
                fontSize: 14,
                color: MicroMngrTheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: widget.events.map((final CheckpointEventModel event) {
              final CheckpointStatus status = event.status;
              final Color statusColor = widget.getStatusColor(status);
              final String dataValue = event.dataValue ?? 'N/A';
              final String notes = event.notes ?? '';
              final String method = event.startedByUser
                  ? 'USER_MANUAL'
                  : 'AUTO_NAG';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: MicroMngrTheme.outlineVariant),
                  color: MicroMngrTheme.surfaceContainer,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.formatEventDateTime(
                              event.eventDateTime.toIso8601String(),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: MicroMngrTheme.border,
                            ),
                          ),

                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: <TextSpan>[
                                const TextSpan(
                                  text: 'VAL_INPUT: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: MicroMngrTheme.border,
                                  ),
                                ),
                                TextSpan(
                                  text: dataValue,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: MicroMngrTheme.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '"$notes"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: MicroMngrTheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Header row
                        Row(
                          children: <Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.displayName.toUpperCase().split(' ').last,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: MicroMngrTheme.outlineVariant,
                            ),
                            color: MicroMngrTheme.surfaceContainerLow,
                          ),
                          child: Text(
                            method,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MicroMngrTheme.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
