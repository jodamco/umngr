import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/services/app_data_notifier.dart';
import 'package:micro_manager/core/utils/bottom_sheet_utils.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/features/goals/bll/efficiency_bll.dart';
import 'package:micro_manager/features/goals/views/widgets/active_goal_card.dart';
import 'package:micro_manager/features/goals/views/widgets/summary_card.dart';
import 'package:micro_manager/features/goals/views/widgets/efficiency_rating_card.dart';
import 'package:micro_manager/features/goals/views/widgets/create_goal_sheet.dart';
import 'package:micro_manager/features/goals/views/widgets/goals_loading_state.dart';
import 'package:micro_manager/features/notifications/bll/checkpoint_notifications_bll.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({super.key});

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  late final GoalsDAL _goalsDAL;
  late final CheckpointNotificationsBLL _checkpointNotificationsBLL;
  late Future<List<GoalModel>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsDAL = getIt<GoalsDAL>();
    _checkpointNotificationsBLL = getIt<CheckpointNotificationsBLL>();
    // Create a future that delays showing data by at least 2 seconds
    _goalsFuture = _createDelayedGoalsFuture();
  }

  /// Creates a future that enforces a minimum 2-second display time
  /// for the loading state before showing the actual goals data
  Future<List<GoalModel>> _createDelayedGoalsFuture() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<GoalModel> goals = await _goalsDAL.getAllGoals();

    await Future.wait(
      goals.map(_checkpointNotificationsBLL.scheduleForGoal),
    );

    // Ensure at least 2 seconds have elapsed
    final int elapsedMs = stopwatch.elapsedMilliseconds;
    const int minDurationMs = 2200;

    if (elapsedMs < minDurationMs) {
      await Future<void>.delayed(
        Duration(milliseconds: minDurationMs - elapsedMs),
      );
    }

    return goals;
  }

  Future<void> _showCreateGoalSheet(BuildContext context) async {
    await showMicroMngrBottomSheet(
      context: context,
      builder: (BuildContext context) => CreateGoalSheet(
        onGoalCreated: (NewGoalModel goal) async {
          // Save goal to database
          await _goalsDAL.createGoal(goal);
          getIt<AppDataNotifier>().onGoalChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Goal created: ${goal.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
            // Refresh goals list
            setState(() {
              _goalsFuture = _goalsDAL.getAllGoals();
            });
          }
        },
      ),
    );
  }

  Future<void> _handleGoalUpdated(GoalModel updatedGoal) async {
    // Update goal in database
    await _goalsDAL.updateGoal(updatedGoal);
    await _checkpointNotificationsBLL.scheduleForGoal(updatedGoal);
    getIt<AppDataNotifier>().onGoalChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal updated: ${updatedGoal.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
      // Refresh goals list
      setState(() {
        _goalsFuture = _goalsDAL.getAllGoals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return FutureBuilder<List<GoalModel>>(
      future: _goalsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<GoalModel>> snapshot) {
        // Show loading state while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GoalsLoadingState();
        }

        // Show error state
        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24,
                top: 24,
                right: 24,
                bottom: 16,
              ),
              child: Text(
                'Error loading goals: ${snapshot.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        // Show normal content when data is available
        return _GoalsList(
          goals: snapshot.data ?? <GoalModel>[],
          onCreateGoal: _showCreateGoalSheet,
          onGoalUpdated: _handleGoalUpdated,
        );
      },
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.goals,
    required this.onCreateGoal,
    this.onGoalUpdated,
  });

  final List<GoalModel> goals;
  final Future<void> Function(BuildContext) onCreateGoal;
  final Future<void> Function(GoalModel)? onGoalUpdated;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double efficiency = EfficiencyBLL().calculateEfficiency(goals);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Statistics Section
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isSmall = constraints.maxWidth < 600;
              return isSmall
                  ? Column(
                      children: <Widget>[
                        const SummaryCard(),
                        const SizedBox(height: 24),
                        EfficiencyRatingCard(
                          efficiencyPercentage: efficiency,
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        const Expanded(
                          flex: 2,
                          child: SummaryCard(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: EfficiencyRatingCard(
                            efficiencyPercentage: efficiency,
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 48),

          // Active Goals Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'ACTIVE_GOALS.txt',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'COUNT: ${goals.length.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              // Goals List or Empty State
              if (goals.isNotEmpty)
                Column(
                  children: goals
                      .map(
                        (GoalModel goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ActiveGoalCard(
                            goal: goal,
                            onGoalUpdated: onGoalUpdated,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.sentiment_dissatisfied,
                          size: 32,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"I was hoping for a longer list to judge you by."'
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Placeholder for your inevitable future failures.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.outline,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),

          // CTA Section
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onCreateGoal(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(24),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.add_circle_outline,
                    size: 24,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ADD ANOTHER GOAL',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 16,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'WARNING: ADDING MORE TASKS DOES NOT INCREASE YOUR ACTUAL PRODUCTIVITY.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
