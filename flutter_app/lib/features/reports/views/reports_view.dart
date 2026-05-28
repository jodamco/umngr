import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/reports/dal/reports_dal.dart';
import 'package:micro_manager/features/reports/models/report_model.dart';

// ---------------------------------------------------------------------------
// Main view
// ---------------------------------------------------------------------------

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late final ReportsDAL _reportsDAL;
  late Future<ReportOverviewModel> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reportsDAL = getIt<ReportsDAL>();
    _dataFuture = _reportsDAL.getReportData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportOverviewModel>(
      future: _dataFuture,
      builder:
          (BuildContext context, AsyncSnapshot<ReportOverviewModel> snapshot) {
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

            final ReportOverviewModel data = snapshot.data!;

            return RefreshIndicator(
              color: MicroMngrTheme.primaryFixedDim,
              backgroundColor: MicroMngrTheme.surfaceContainer,
              onRefresh: () async {
                setState(() {
                  _dataFuture = _reportsDAL.getReportData();
                });
                await _dataFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SystemMessage(data: data),
                    const SizedBox(height: 32),
                    _MetricsSection(data: data),
                    const SizedBox(height: 32),
                    _PersistenceMatrix(
                      dayCountMap: data.dayCountMap,
                      periodStart: data.periodStart,
                      today: data.today,
                    ),
                    const SizedBox(height: 32),
                    _RecentObligationsSection(
                      events: data.recentEvents,
                      goalNames: data.goalNames,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

// ---------------------------------------------------------------------------
// System message
// ---------------------------------------------------------------------------

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.data});

  final ReportOverviewModel data;

  String get _message {
    if (data.totalObligations == 0) {
      return '"NO OBLIGATIONS DETECTED. SYSTEM IDLE. SUSPICIOUSLY IDLE."';
    }
    if (data.weeklyCompliance >= 0.8) {
      return '"ANALYSIS COMPLETE. COMPLIANCE LEVELS UNEXPECTEDLY HIGH. RECALIBRATING EXPECTATIONS."';
    }
    if (data.weeklyCompliance >= 0.5) {
      return '"ANALYSIS COMPLETE. YOUR PERFORMANCE IS STATISTICALLY... PREDICTABLE. THE DATA DOES NOT LIE, UNLIKE YOUR MORNING ALARM."';
    }
    return '"ANALYSIS COMPLETE. FAILURE RATE NOMINAL. SYSTEM MAINTAINS LOW EXPECTATIONS. YOU ARE WELCOME."';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: MicroMngrTheme.primaryFixedDim,
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SYSTEM_MESSAGE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: MicroMngrTheme.primaryFixedDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _message,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: MicroMngrTheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics section
// ---------------------------------------------------------------------------

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.data});

  final ReportOverviewModel data;

  @override
  Widget build(BuildContext context) {
    final String complianceStr =
        '${(data.weeklyCompliance * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MetricCard(
          label: 'TOTAL_OBLIGATIONS',
          value: data.totalObligations.toString(),
          footer: 'STATUS: ACTIVE',
          isCritical: false,
        ),
        const SizedBox(height: 8),
        _ComplianceCard(
          compliance: data.weeklyCompliance,
          complianceStr: complianceStr,
          eventsCount: data.weekEventsCount,
          expectedCount: data.weekExpectedCount,
        ),
        if (data.peakPerformer != null) ...<Widget>[
          const SizedBox(height: 8),
          _MetricCard(
            label: 'PEAK_PERFORMANCE',
            value: data.peakPerformer!,
            footer: 'BEST STREAK THIS WEEK',
            isCritical: false,
            valueIsSmall: true,
          ),
        ],
        const SizedBox(height: 8),
        _MetricCard(
          label: 'CRITICAL_FAILURE',
          value: data.criticalFailure ?? '—',
          footer: 'MECHANICAL NEGLECT DETECTED',
          isCritical: true,
          valueIsSmall: true,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.footer,
    required this.isCritical,
    this.valueIsSmall = false,
  });

  final String label;
  final String value;
  final String footer;
  final bool isCritical;
  final bool valueIsSmall;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isCritical
        ? MicroMngrTheme.error.withValues(alpha: 0.6)
        : MicroMngrTheme.outlineVariant;
    final Color labelColor = isCritical
        ? MicroMngrTheme.error
        : MicroMngrTheme.onSurfaceVariant;
    final Color valueColor = isCritical
        ? MicroMngrTheme.error
        : MicroMngrTheme.onBackground;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainer,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: valueIsSmall ? 14 : 22,
              fontWeight: FontWeight.bold,
              color: isCritical
                  ? MicroMngrTheme.error
                  : MicroMngrTheme.primaryFixedDim,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: MicroMngrTheme.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: valueColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.compliance,
    required this.complianceStr,
    required this.eventsCount,
    required this.expectedCount,
  });

  final double compliance;
  final String complianceStr;
  final int eventsCount;
  final int expectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainer,
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'WEEKLY_COMPLIANCE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.0,
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$eventsCount / $expectedCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                complianceStr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MicroMngrTheme.primaryFixedDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            child: LinearProgressIndicator(
              value: compliance,
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

// ---------------------------------------------------------------------------
// Persistence matrix
// ---------------------------------------------------------------------------

class _PersistenceMatrix extends StatefulWidget {
  const _PersistenceMatrix({
    required this.dayCountMap,
    required this.periodStart,
    required this.today,
  });

  final Map<String, int> dayCountMap;
  final DateTime periodStart;
  final DateTime today;

  @override
  State<_PersistenceMatrix> createState() => _PersistenceMatrixState();
}

class _PersistenceMatrixState extends State<_PersistenceMatrix> {
  int _monthOffset = 0;

  static const List<String> _dayLabels = <String>[
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  static const List<String> _monthNames = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  DateTime get _displayMonth =>
      DateTime(widget.today.year, widget.today.month + _monthOffset);

  bool get _canGoPrevious {
    final DateTime prev = DateTime(_displayMonth.year, _displayMonth.month - 1);
    final DateTime minMonth = DateTime(
      widget.periodStart.year,
      widget.periodStart.month,
    );
    return !prev.isBefore(minMonth);
  }

  bool get _canGoNext => _monthOffset < 0;

  void _onDragEnd(DragEndDetails details) {
    final double? v = details.primaryVelocity;
    if (v == null) return;
    if (v < -200 && _canGoNext) setState(() => _monthOffset++);
    if (v > 200 && _canGoPrevious) setState(() => _monthOffset--);
  }

  Color _colorForCount(int count) {
    if (count == 0) return MicroMngrTheme.surfaceContainerHighest;
    if (count <= 2) return MicroMngrTheme.outlineVariant.withValues(alpha: 1.0);
    return MicroMngrTheme.primaryFixedDim;
  }

  String _key(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  Widget build(BuildContext context) {
    final DateTime month = _displayMonth;
    final int year = month.year;
    final int m = month.month;
    final int daysInMonth = DateTime(year, m + 1, 0).day;
    final int leadingBlanks = DateTime(year, m, 1).weekday - 1;
    final int totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;
    final String monthLabel = '${_monthNames[m - 1]}_${year}_SESSION';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PERSISTENCE_MATRIX',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MicroMngrTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'TEMPORAL_AUDIT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: MicroMngrTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(
                  'LOW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: MicroMngrTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                const _LegendBlock(
                  color: MicroMngrTheme.surfaceContainerHighest,
                ),
                const SizedBox(width: 2),
                const _LegendBlock(color: MicroMngrTheme.outlineVariant),
                const SizedBox(width: 2),
                const _LegendBlock(color: MicroMngrTheme.primaryFixedDim),
                const SizedBox(width: 4),
                Text(
                  'HIGH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: MicroMngrTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onHorizontalDragEnd: _onDragEnd,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MicroMngrTheme.surfaceContainer,
              border: Border.all(color: MicroMngrTheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.0,
                        color: MicroMngrTheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        if (_canGoPrevious)
                          GestureDetector(
                            onTap: () => setState(() => _monthOffset--),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 16,
                              color: MicroMngrTheme.onSurfaceVariant,
                            ),
                          ),
                        if (_canGoNext)
                          GestureDetector(
                            onTap: () => setState(() => _monthOffset++),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: MicroMngrTheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: _dayLabels
                      .map(
                        (String d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 9,
                                  color: MicroMngrTheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (BuildContext context, int index) {
                    final int dayNumber = index - leadingBlanks + 1;
                    final bool inMonth =
                        index >= leadingBlanks && dayNumber <= daysInMonth;
                    if (!inMonth) return const SizedBox.shrink();

                    final DateTime date = DateTime(year, m, dayNumber);
                    final int count = widget.dayCountMap[_key(date)] ?? 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: _colorForCount(count),
                        border: Border.all(
                          color: MicroMngrTheme.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 9,
                            color: count > 0
                                ? MicroMngrTheme.surfaceContainerLow
                                : MicroMngrTheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendBlock extends StatelessWidget {
  const _LegendBlock({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      color: color,
    );
  }
}

// ---------------------------------------------------------------------------
// Recent obligations
// ---------------------------------------------------------------------------

class _RecentObligationsSection extends StatelessWidget {
  const _RecentObligationsSection({
    required this.events,
    required this.goalNames,
  });

  final List<CheckpointEventModel> events;
  final Map<int, String> goalNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'RECENT_OBLIGATIONS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.0,
            color: MicroMngrTheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MicroMngrTheme.surfaceContainerLow,
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
            (CheckpointEventModel e) => _ObligationRow(
              event: e,
              goalName: goalNames[e.goalId] ?? 'UNKNOWN',
            ),
          ),
      ],
    );
  }
}

class _ObligationRow extends StatelessWidget {
  const _ObligationRow({required this.event, required this.goalName});

  final CheckpointEventModel event;
  final String goalName;

  Color get _iconColor {
    return switch (event.status) {
      CheckpointStatus.fulfilled => MicroMngrTheme.primaryFixedDim,
      CheckpointStatus.skipped => MicroMngrTheme.onSurfaceVariant,
      CheckpointStatus.dropped => MicroMngrTheme.error,
    };
  }

  IconData get _icon {
    return switch (event.status) {
      CheckpointStatus.fulfilled => Icons.check_circle,
      CheckpointStatus.skipped => Icons.remove_circle_outline,
      CheckpointStatus.dropped => Icons.cancel,
    };
  }

  String get _timeStr {
    final DateTime dt = event.eventDateTime;
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    return '$day/$month $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bool isFulfilled = event.status == CheckpointStatus.fulfilled;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: MicroMngrTheme.surfaceContainerLow,
        border: Border.all(color: MicroMngrTheme.outlineVariant),
      ),
      child: Opacity(
        opacity: isFulfilled ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(_icon, size: 18, color: _iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goalName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _timeStr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MicroMngrTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
