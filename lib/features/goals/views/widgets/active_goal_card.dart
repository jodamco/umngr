import 'package:flutter/material.dart';

enum _GoalState {
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
  final String title;
  final String icon;
  final String initiatedDaysAgo;
  final double persistenceScore;

  const ActiveGoalCard({
    required this.title,
    required this.icon,
    this.initiatedDaysAgo = '3 DAYS AGO',
    this.persistenceScore = 0.4,
    super.key,
  });

  _GoalState _getState(double score) {
    if (score >= 90) return _GoalState.stable;
    if (score >= 70) return _GoalState.degrading;
    if (score >= 40) return _GoalState.atRisk;
    if (score > 0) return _GoalState.failing;
    return _GoalState.abandoned;
  }

  _GoalStateConfig _getStateConfig(_GoalState state) {
    return switch (state) {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _GoalState state = _getState(persistenceScore);
    final _GoalStateConfig config = _getStateConfig(state);
    final Color statusColor = config.color;

    return Container(
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
                        _getIconData(icon),
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
                            title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'INITIATED: $initiatedDaysAgo | PERSISTENCE: ${persistenceScore.toStringAsFixed(0)}%',
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
    );
  }

  IconData _getIconData(String icon) {
    return switch (icon.toLowerCase()) {
      'restaurant' => Icons.restaurant,
      'fitness_center' => Icons.fitness_center,
      'book' => Icons.book,
      'code' => Icons.code,
      'money' => Icons.money,
      'health_and_safety' => Icons.health_and_safety,
      _ => Icons.check_circle,
    };
  }
}
