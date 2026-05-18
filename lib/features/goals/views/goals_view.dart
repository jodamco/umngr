import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/utils/bottom_sheet_utils.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';
import 'package:micro_manager/features/goals/models/goal.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/features/goals/views/widgets/active_goal_card.dart';
import 'package:micro_manager/features/goals/views/widgets/summary_card.dart';
import 'package:micro_manager/features/goals/views/widgets/efficiency_rating_card.dart';
import 'package:micro_manager/features/goals/views/widgets/create_goal_sheet.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({super.key});

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  late final GoalsDAL _goalsDAL;
  late Future<List<Goal>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsDAL = getIt<GoalsDAL>();
    _goalsFuture = _goalsDAL.getAllGoals();
  }

  Future<void> _showCreateGoalSheet(BuildContext context) async {
    await showMicroMngrBottomSheet(
      context: context,
      builder: (BuildContext context) => CreateGoalSheet(
        onGoalCreated: (NewGoalModel goal) async {
          // Save goal to database
          await _goalsDAL.createGoal(goal);
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                  ? const Column(
                      children: <Widget>[
                        SummaryCard(),
                        SizedBox(height: 24),
                        EfficiencyRatingCard(),
                      ],
                    )
                  : const Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: SummaryCard(),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: EfficiencyRatingCard(),
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
              FutureBuilder<List<Goal>>(
                future: _goalsFuture,
                builder: (BuildContext context, AsyncSnapshot<List<Goal>> snapshot) {
                  final int goalCount = snapshot.data?.length ?? 0;

                  return Column(
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
                            'COUNT: ${goalCount.toString().padLeft(2, '0')}',
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
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else if (snapshot.hasError)
                        Center(
                          child: Text(
                            'Error loading goals: ${snapshot.error}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      else if (snapshot.hasData && snapshot.data!.isNotEmpty)
                        Column(
                          children: snapshot.data!
                              .map(
                                (Goal goal) => Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: ActiveGoalCard(goal: goal),
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
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 48),

          // CTA Section
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCreateGoalSheet(context),
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
