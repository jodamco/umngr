import 'package:flutter/material.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';

class GoalCycleSection extends StatelessWidget {
  final ThemeData theme;
  final GoalCycle selectedCycle;
  final Set<int> selectedDays;
  final List<String> dayLabels;
  final int selectedDayOfMonth;
  final TextEditingController dayOfMonthController;
  final int occurrencesPerCycle;
  final Function(GoalCycle) onCycleChanged;
  final Function(int) onDayToggled;
  final Function(int) onDayOfMonthChanged;
  final Function(int) onOccurrencesChanged;
  final Widget Function({required String title, required Widget child})
      buildSection;

  const GoalCycleSection({
    required this.theme,
    required this.selectedCycle,
    required this.selectedDays,
    required this.dayLabels,
    required this.selectedDayOfMonth,
    required this.dayOfMonthController,
    required this.occurrencesPerCycle,
    required this.onCycleChanged,
    required this.onDayToggled,
    required this.onDayOfMonthChanged,
    required this.onOccurrencesChanged,
    required this.buildSection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'GOAL CYCLE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: <Widget>[
          DropdownButtonFormField<GoalCycle>(
            initialValue: selectedCycle,
            items: <DropdownMenuItem<GoalCycle>>[
              const DropdownMenuItem<GoalCycle>(
                value: GoalCycle.daily,
                child: Text('DAILY'),
              ),
              const DropdownMenuItem<GoalCycle>(
                value: GoalCycle.weekly,
                child: Text('WEEKLY'),
              ),
              const DropdownMenuItem<GoalCycle>(
                value: GoalCycle.biWeekly,
                child: Text('BI-WEEKLY'),
              ),
              const DropdownMenuItem<GoalCycle>(
                value: GoalCycle.monthly,
                child: Text('MONTHLY'),
              ),
            ],
            onChanged: (GoalCycle? value) {
              if (value != null) {
                onCycleChanged(value);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          if (selectedCycle == GoalCycle.weekly ||
              selectedCycle == GoalCycle.biWeekly)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Active Windows [MTWTFSS]',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  itemBuilder: (BuildContext context, int index) {
                    final bool isSelected = selectedDays.contains(index);
                    return GestureDetector(
                      onTap: () => onDayToggled(index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                            width: 1,
                          ),
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            dayLabels[index],
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          if (selectedCycle == GoalCycle.monthly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    'MONTHLY SYNC:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: <Widget>[
                      Text(
                        'DAY',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: TextField(
                          enabled: true,
                          controller: dayOfMonthController,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          textAlign: TextAlign.center,
                          onChanged: (String value) {
                            if (value.isEmpty) {
                              onDayOfMonthChanged(1);
                              dayOfMonthController.text = '01';
                              return;
                            }
                            final int? day = int.tryParse(value);
                            if (day != null && day >= 1 && day <= 31) {
                              onDayOfMonthChanged(day);
                            } else if (value.isNotEmpty) {
                              dayOfMonthController.text = selectedDayOfMonth
                                  .toString()
                                  .padLeft(2, '0');
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (selectedCycle == GoalCycle.daily)
            _OccurrencesSection(
              theme: theme,
              occurrencesPerCycle: occurrencesPerCycle,
              onOccurrencesChanged: onOccurrencesChanged,
            ),
          Container(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              'Precision scheduling reduces the margin for excuse. Interval-based monitoring initiated.',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccurrencesSection extends StatelessWidget {
  final ThemeData theme;
  final int occurrencesPerCycle;
  final Function(int) onOccurrencesChanged;

  const _OccurrencesSection({
    required this.theme,
    required this.occurrencesPerCycle,
    required this.onOccurrencesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text(
                    'OCCURRENCES PER CYCLE',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Recommended target: 03',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (occurrencesPerCycle > 1) {
                            onOccurrencesChanged(occurrencesPerCycle - 1);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          occurrencesPerCycle.toString().padLeft(2, '0'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          onOccurrencesChanged(occurrencesPerCycle + 1);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
