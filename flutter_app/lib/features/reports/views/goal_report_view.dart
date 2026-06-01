import 'dart:math' show max, min, pi;

import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/reports/dal/reports_dal.dart';
import 'package:micro_manager/features/reports/models/goal_report_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// View
// ─────────────────────────────────────────────────────────────────────────────

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
                _MetricChartSection(data: data),
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
// Metric chart section — delegates to protocol-specific chart
// ─────────────────────────────────────────────────────────────────────────────

class _MetricChartSection extends StatelessWidget {
  const _MetricChartSection({required this.data});

  final GoalReportModel data;

  @override
  Widget build(BuildContext context) {
    return switch (data.chartProtocol) {
      GoalChartProtocol.line => _Protocol01LineChart(data: data),
      GoalChartProtocol.donut => _Protocol02DonutChart(data: data),
      GoalChartProtocol.bar => _Protocol03BarChart(data: data),
      GoalChartProtocol.scatter => _Protocol04ScatterChart(data: data),
    };
  }
}

// ─── Protocol 01: Quantitative / Duration (Line Chart) ───────────────────────

class _Protocol01LineChart extends StatelessWidget {
  const _Protocol01LineChart({required this.data});

  final GoalReportModel data;

  @override
  Widget build(BuildContext context) {
    final List<double?> values = data.last7DayNumericValues;
    final List<String> labels = data.last7DayLabels;
    final String todayLabel = labels.last;

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'INTENSITY_FLUX',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      color: MicroMngrTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'L7D Quantitative Baseline',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: MicroMngrTheme.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.monitor_heart_outlined,
                size: 20,
                color: MicroMngrTheme.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _ValueLineChartPainter(
                values: values,
                lineColor: MicroMngrTheme.primaryFixedDim,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((String label) {
              final bool isToday = label == todayLabel;
              return Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isToday
                      ? MicroMngrTheme.primaryFixedDim
                      : MicroMngrTheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ValueLineChartPainter extends CustomPainter {
  const _ValueLineChartPainter({
    required this.values,
    required this.lineColor,
  });

  final List<double?> values;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> nonNull = values.whereType<double>().toList();

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (nonNull.isEmpty) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    final double maxVal = nonNull.reduce(max);
    final double minVal = nonNull.reduce(min);
    final double range = maxVal == minVal
        ? (maxVal == 0 ? 1.0 : maxVal)
        : maxVal - minVal;
    final double step = size.width / (values.length - 1);
    const double topPad = 0.1;
    final double chartHeight = size.height * (1 - topPad);

    // Compute point positions (null → no point)
    final List<Offset?> points = <Offset?>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] == null) {
        points.add(null);
      } else {
        final double normalized = (values[i]! - minVal) / range;
        points.add(
          Offset(
            i * step,
            size.height * topPad + chartHeight * (1 - normalized),
          ),
        );
      }
    }

    // Area fill (connects all non-null points in order)
    final List<Offset> nonNullPoints = points.whereType<Offset>().toList();
    if (nonNullPoints.length > 1) {
      final Path fillPath = Path()
        ..moveTo(nonNullPoints.first.dx, nonNullPoints.first.dy);
      for (final Offset p in nonNullPoints.skip(1)) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(nonNullPoints.last.dx, size.height);
      fillPath.lineTo(nonNullPoints.first.dx, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              lineColor.withValues(alpha: 0.1),
              lineColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );
    }

    // Line segments (skip nulls)
    final Path linePath = Path();
    bool started = false;
    for (final Offset? p in points) {
      if (p == null) {
        started = false;
      } else if (!started) {
        linePath.moveTo(p.dx, p.dy);
        started = true;
      } else {
        linePath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Square nodes (4 × 4 px) at non-null data points
    final Paint nodePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (final Offset? p in points) {
      if (p != null) {
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 4, height: 4),
          nodePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ValueLineChartPainter old) => old.values != values;
}

// ─── Protocol 02: Binary Success (Donut Chart) ───────────────────────────────

class _Protocol02DonutChart extends StatelessWidget {
  const _Protocol02DonutChart({required this.data});

  final GoalReportModel data;

  @override
  Widget build(BuildContext context) {
    final int failed = data.weekEventsCount - data.weekFulfilledCount;
    final String complianceStr =
        '${(data.weeklyCompliance * 100).toStringAsFixed(0)}%';

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'RESOLVE_INDEX',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      color: MicroMngrTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'L7D Binary Compliance',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: MicroMngrTheme.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.donut_large_outlined,
                size: 20,
                color: MicroMngrTheme.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CustomPaint(
                      painter: _DonutChartPainter(
                        fulfilled: data.weekFulfilledCount,
                        total: data.weekEventsCount,
                      ),
                      size: const Size(140, 140),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          complianceStr,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: MicroMngrTheme.primaryFixedDim,
                              ),
                        ),
                        Text(
                          'TOTAL_RESOLVE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 9,
                                letterSpacing: 1.0,
                                color: MicroMngrTheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _DonutLegendRow(
                      color: MicroMngrTheme.primaryFixedDim,
                      label: 'FULFILLED',
                      count: data.weekFulfilledCount,
                    ),
                    const SizedBox(height: 8),
                    _DonutLegendRow(
                      color: MicroMngrTheme.error,
                      label: 'FAILED',
                      count: failed,
                    ),
                    const SizedBox(height: 8),
                    _DonutLegendRow(
                      color: MicroMngrTheme.onSurfaceVariant,
                      label: 'EXPECTED',
                      count: data.weekExpectedCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 1.0,
            color: MicroMngrTheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.fulfilled,
    required this.total,
  });

  final int fulfilled;
  final int total;

  static const double _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = min(size.width, size.height) / 2 - _strokeWidth / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = MicroMngrTheme.surfaceContainerHighest
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (total == 0) return;

    final double fulfilledFraction = (fulfilled / total).clamp(0.0, 1.0);
    final double failedFraction = 1.0 - fulfilledFraction;
    const double start = -pi / 2;

    if (fulfilledFraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * pi * fulfilledFraction,
        false,
        Paint()
          ..color = MicroMngrTheme.primaryFixedDim
          ..strokeWidth = _strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    if (failedFraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + 2 * pi * fulfilledFraction,
        2 * pi * failedFraction,
        false,
        Paint()
          ..color = MicroMngrTheme.error.withValues(alpha: 0.7)
          ..strokeWidth = _strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.fulfilled != fulfilled || old.total != total;
}

// ─── Protocol 03: Intensity Audit (Bar Chart) ────────────────────────────────

class _Protocol03BarChart extends StatelessWidget {
  const _Protocol03BarChart({required this.data});

  final GoalReportModel data;

  @override
  Widget build(BuildContext context) {
    final List<double> values = data.last7DayLoadValues;
    final List<String> labels = data.last7DayLabels;
    final String todayLabel = labels.last;

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'INTENSITY_AUDIT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      color: MicroMngrTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'L7D Load Distribution',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: MicroMngrTheme.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.bar_chart,
                size: 20,
                color: MicroMngrTheme.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _BarChartPainter(values: values),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((String label) {
              final bool isToday = label == todayLabel;
              return Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isToday
                      ? MicroMngrTheme.primaryFixedDim
                      : MicroMngrTheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Row(
            children: <Widget>[
              _BarLegendChip(
                color: MicroMngrTheme.primaryFixedDim,
                label: '<70',
              ),
              SizedBox(width: 12),
              _BarLegendChip(
                color: MicroMngrTheme.tertiaryFixedDim,
                label: '70–90',
              ),
              SizedBox(width: 12),
              _BarLegendChip(
                color: MicroMngrTheme.error,
                label: '>90',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarLegendChip extends StatelessWidget {
  const _BarLegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 9,
            letterSpacing: 1.0,
            color: MicroMngrTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.values});

  final List<double> values;

  Color _barColor(double value) {
    if (value > 90) return MicroMngrTheme.error;
    if (value >= 70) return MicroMngrTheme.tertiaryFixedDim;
    return MicroMngrTheme.primaryFixedDim;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double gap = 2.0;
    final int count = values.length;
    final double barWidth = (size.width - gap * (count - 1)) / count;

    // Grid lines at 25, 50, 75, 100 (opacity 0.05)
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final double y = size.height * (1 - i * 0.25);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bars
    for (int i = 0; i < count; i++) {
      final double barHeight =
          (values[i].clamp(0.0, 100.0) / 100) * size.height;
      if (barHeight <= 0) continue;
      canvas.drawRect(
        Rect.fromLTWH(
          i * (barWidth + gap),
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        Paint()
          ..color = _barColor(values[i])
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.values != values;
}

// ─── Protocol 04: Daily Scatter Audit (Scatter Plot) ─────────────────────────

class _Protocol04ScatterChart extends StatelessWidget {
  const _Protocol04ScatterChart({required this.data});

  final GoalReportModel data;

  static const List<String> _weekLabels = <String>[
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  Widget build(BuildContext context) {
    final int todayCol = data.today.weekday - 1; // 0 = Mon

    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'DAILY_SCATTER_AUDIT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      color: MicroMngrTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Current Week — Discrete Event Density',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: MicroMngrTheme.onBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.scatter_plot_outlined,
                size: 20,
                color: MicroMngrTheme.outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _ScatterChartPainter(
                points: data.scatterPoints,
                nodeColor: MicroMngrTheme.primaryFixedDim,
                yMax: data.scatterYMax,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (int i) {
              return Text(
                _weekLabels[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: i == todayCol
                      ? MicroMngrTheme.primaryFixedDim
                      : MicroMngrTheme.outlineVariant,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ScatterChartPainter extends CustomPainter {
  const _ScatterChartPainter({
    required this.points,
    required this.nodeColor,
    this.yMax,
  });

  final List<(int, double)> points;
  final Color nodeColor;
  final double? yMax;

  @override
  void paint(Canvas canvas, Size size) {
    const int cols = 7;
    final double colWidth = size.width / cols;
    const double topPad = 0.1;
    final double chartH = size.height * (1 - topPad);

    // Determine Y maximum
    final double maxY;
    if (yMax != null) {
      maxY = yMax!;
    } else {
      final List<double> ys = points.map(((int, double) p) => p.$2).toList();
      maxY = ys.isEmpty ? 4.0 : ys.reduce(max).clamp(1.0, double.infinity);
    }

    // Background grid (opacity 0.05)
    final Paint gridPaint = Paint()
      ..color = nodeColor.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 1; i < cols; i++) {
      final double x = i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 1; i <= 4; i++) {
      final double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final Paint nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
    for (final (int d, double v) in points) {
      final double x = (d + 0.5) * colWidth;
      final double normalized = (v / maxY).clamp(0.0, 1.0);
      final double y = size.height * topPad + chartH * (1 - normalized);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 4, height: 4),
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScatterChartPainter old) =>
      old.points != points || old.yMax != yMax;
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
