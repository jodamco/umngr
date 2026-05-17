import 'package:flutter/material.dart';
import 'package:micro_manager/core/utils/bottom_sheet_utils.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/features/goals/views/widgets/active_goal_card.dart';
import 'package:micro_manager/features/goals/views/widgets/active_goals_card.dart';
import 'package:micro_manager/features/goals/views/widgets/efficiency_rating_card.dart';
import 'package:micro_manager/features/goals/views/widgets/create_goal_sheet.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  Future<void> _showCreateGoalSheet(BuildContext context) async {
    await showMicroMngrBottomSheet(
      context: context,
      builder: (BuildContext context) => CreateGoalSheet(
        onGoalCreated: (NewGoalModel goal) {
          // Handle goal creation here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Goal created: ${goal.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
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
                        ActiveGoalsCard(),
                        SizedBox(height: 24),
                        EfficiencyRatingCard(),
                      ],
                    )
                  : const Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: ActiveGoalsCard(),
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
                    'COUNT: 01',
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
              const ActiveGoalCard(
                title: 'Eat Better',
                icon: 'restaurant',
                initiatedDaysAgo: '3 DAYS AGO',
                persistenceScore: 25,
              ),
              const SizedBox(height: 24),

              // Empty State
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
