import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/features/goals/views/widgets/goal_options_sheet.dart';
import 'package:micro_manager/shared/enums.dart';

enum _GoalState {
  uncertain,
  stable,
  degrading,
  atRisk,
  failing,
  abandoned,
}

class _GoalStateConfig {
  final String label;
  final Color color;
  final String note;
  final String copy;

  const _GoalStateConfig({
    required this.label,
    required this.color,
    required this.note,
    required this.copy,
  });
}

class ActiveGoalCard extends StatelessWidget {
  final GoalModel goal;
  final Future<void> Function(GoalModel)? onGoalUpdated;

  const ActiveGoalCard({
    required this.goal,
    this.onGoalUpdated,
    super.key,
  });

  /// Calculate persistence score based on goal events
  /// Returns a value between 0-100
  /// For now, uses event_count as a simple metric
  double _calculatePersistenceScore() {
    if (goal.eventCount == 0) return 0;
    // Scale event count to a 0-100 score (adjust formula as needed)
    return (goal.eventCount * 10).clamp(0, 100).toDouble();
  }

  String _getInitiatedDaysAgo() {
    final Duration diff = DateTime.now().difference(goal.createdAt);
    final int days = diff.inDays;
    if (days == 0) return 'TODAY';
    if (days == 1) return '1 DAY AGO';
    return '$days DAYS AGO';
  }

  String _getCategoryIcon() {
    final GoalCategory category = GoalCategory.fromDbValue(goal.category);
    return category.iconName;
  }

  _GoalState _getState(double score) {
    // Check if goal was recently created (2 days or less)
    final Duration timeSinceCreation = DateTime.now().difference(
      goal.createdAt,
    );
    if (timeSinceCreation.inDays <= 2) {
      return _GoalState.uncertain;
    }

    // Score-based state determination
    if (score >= 90) return _GoalState.stable;
    if (score >= 70) return _GoalState.degrading;
    if (score >= 40) return _GoalState.atRisk;
    if (score > 0) return _GoalState.failing;
    return _GoalState.abandoned;
  }

  _GoalStateConfig _getStateConfig(_GoalState state, ThemeData theme) {
    return switch (state) {
      _GoalState.uncertain => _GoalStateConfig(
        label: 'UNCERTAIN',
        color: theme.colorScheme.primary,
        note: 'DATA INSUFFICIENT',
        copy:
            'Goal recently initiated. Insufficient data for analysis. Collecting metrics.',
      ),
      _GoalState.stable => const _GoalStateConfig(
        label: 'STABLE',
        color: Color(0xFF64FFDA),
        note: 'SYSTEM IS WATCHING',
        copy: 'Optimal adherence detected. Do not get comfortable.',
      ),
      _GoalState.degrading => const _GoalStateConfig(
        label: 'DEGRADING',
        color: Color(0xFFFFD740),
        note: 'LOGGING DISCREPANCY',
        copy: 'Slight variance in resolve. Monitoring frequency increased.',
      ),
      _GoalState.atRisk => const _GoalStateConfig(
        label: 'AT RISK',
        color: Color(0xFFFFAB40),
        note: 'INTERVENTION IMMINENT',
        copy:
            'Statistical likelihood of failure rising. I am disappointed, but not surprised.',
      ),
      _GoalState.failing => const _GoalStateConfig(
        label: 'FAILING',
        color: Color(0xFFCF6679),
        note: 'FAILURE ARCHIVE PENDING',
        copy:
            'Resolve is non-existent. Prepare for transition to the Failure Log.',
      ),
      _GoalState.abandoned => const _GoalStateConfig(
        label: 'ABANDONED',
        color: Color(0xFF393939),
        note: 'JUDGMENT RENDERED',
        copy: 'Task terminated. Added to your permanent record of failures.',
      ),
    };
  }

  void _showOptionsSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (BuildContext context) => GoalOptionsSheet(
        goal: goal,
        onGoalUpdated: onGoalUpdated,
      ),
    );
  }

  void _navigateToGoalDetail(BuildContext context) {
    context.push('/goals/details/${goal.id}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double persistenceScore = _calculatePersistenceScore();
    final _GoalState state = _getState(persistenceScore);
    final _GoalStateConfig config = _getStateConfig(state, theme);
    final Color statusColor = config.color;

    return GestureDetector(
      onTap: () => _navigateToGoalDetail(context),
      onLongPress: () => _showOptionsSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            // Goal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _getIconData(_getCategoryIcon()),
                          size: 32,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              goal.name.toUpperCase(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'INITIATED: ${_getInitiatedDaysAgo()} | PERSISTENCE: ${persistenceScore.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Badge and System Note
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      config.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  config.note,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: statusColor.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // State-specific copy message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.05),
                border: Border(
                  left: BorderSide(
                    color: statusColor,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                config.copy,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 11,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    return switch (icon.toLowerCase()) {
      'restaurant' => Icons.restaurant,
      'fitness' => Icons.fitness_center,
      'nutrition' => Icons.egg_alt,
      'book' => Icons.book,
      'code' => Icons.code,
      'money' => Icons.savings,
      'rest_mental' => Icons.self_improvement,
      'people' => Icons.diversity_3,
      _ => Icons.check_circle,
    };
  }
}
