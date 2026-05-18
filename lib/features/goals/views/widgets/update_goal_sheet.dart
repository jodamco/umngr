import 'package:flutter/material.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/features/goals/views/widgets/checkpoints_section.dart';
import 'package:micro_manager/features/goals/views/widgets/goal_cycle_section.dart';
import 'package:micro_manager/features/goals/views/widgets/goal_name_section.dart';

class UpdateGoalSheet extends StatefulWidget {
  final GoalModel goal;
  final VoidCallback? onClose;
  final Function(GoalModel)? onGoalUpdated;

  const UpdateGoalSheet({
    required this.goal,
    this.onClose,
    this.onGoalUpdated,
    super.key,
  });

  @override
  State<UpdateGoalSheet> createState() => _UpdateGoalSheetState();
}

class _UpdateGoalSheetState extends State<UpdateGoalSheet> {
  late TextEditingController goalNameController;
  late TextEditingController dayOfMonthController;
  late GoalCycle selectedCycle;
  late Set<int> selectedDays;
  late int selectedDayOfMonth;
  late List<TimeOfDay> checkpointTimes;
  late int occurrencesPerCycle;

  // Error states for inline error messages
  String? daysError;
  String? checkpointsError;
  String? goalNameError;

  final List<String> dayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _initializeFromGoal();
  }

  void _initializeFromGoal() {
    goalNameController = TextEditingController(text: widget.goal.name);

    // Parse cycle
    selectedCycle = _parseCycle(widget.goal.cycle);

    // Parse active days
    selectedDays = _parseActiveDays(widget.goal.activeDays);

    // Parse day of month
    selectedDayOfMonth = widget.goal.dayOfMonth ?? 1;
    dayOfMonthController = TextEditingController(
      text: selectedDayOfMonth.toString().padLeft(2, '0'),
    );

    // Parse checkpoints from checkpointTime string (format: "HH:mm")
    checkpointTimes = widget.goal.checkpoints
        .map((GoalCheckpoint cp) => _parseTimeOfDay(cp.checkpointTime))
        .toList();

    // Parse occurrences
    occurrencesPerCycle = widget.goal.occurrences ?? 3;
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final List<String> parts = timeString.split(':');
      if (parts.length == 2) {
        final int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Silently fail and return default
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  GoalCycle _parseCycle(String cycleString) {
    return switch (cycleString) {
      'daily' => GoalCycle.daily,
      'weekly' => GoalCycle.weekly,
      'bi_weekly' => GoalCycle.biWeekly,
      'monthly' => GoalCycle.monthly,
      _ => GoalCycle.weekly,
    };
  }

  Set<int> _parseActiveDays(String? activeDaysString) {
    if (activeDaysString == null || activeDaysString.isEmpty) {
      return <int>{0, 2, 4}; // Default: M, W, F
    }
    try {
      final List<String> parts = activeDaysString.split(',');
      return parts.map((String s) => int.parse(s.trim())).toSet();
    } catch (e) {
      return <int>{0, 2, 4};
    }
  }

  @override
  void dispose() {
    goalNameController.dispose();
    dayOfMonthController.dispose();
    super.dispose();
  }

  void _toggleDay(int index) {
    if (selectedDays.contains(index) && selectedDays.length == 1) {
      setState(() {
        daysError =
            'At least one day required. Even commitment needs a day off... but not this.';
      });
      return;
    }
    setState(() {
      daysError = null;
      if (selectedDays.contains(index)) {
        selectedDays.remove(index);
      } else {
        selectedDays.add(index);
      }
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: checkpointTimes[index],
    );
    if (picked != null) {
      setState(() {
        checkpointTimes[index] = picked;
      });
    }
  }

  void _addCheckpoint() {
    if (checkpointTimes.length >= 4) {
      setState(() {
        checkpointsError =
            'Four checkpoints maximum. I can\'t be that annoying without consequences.';
      });
      return;
    }
    setState(() {
      checkpointsError = null;
      checkpointTimes.add(
        TimeOfDay(
          hour: (checkpointTimes.last.hour + 2) % 24,
          minute: 0,
        ),
      );
    });
  }

  void _removeCheckpoint(int index) {
    if (checkpointTimes.length > 1) {
      setState(() {
        checkpointsError = null;
        checkpointTimes.removeAt(index);
      });
    } else {
      setState(() {
        checkpointsError = 'At least 1 checkpoint required';
      });
    }
  }

  void _handleSubmit() {
    if (goalNameController.text.trim().isEmpty) {
      setState(() {
        goalNameError =
            'A goal needs a name. Even your chaos deserves labeling.';
      });
      return;
    }
    setState(() {
      goalNameError = null;
    });

    // Create updated checkpoints
    final List<GoalCheckpoint> updatedCheckpoints = checkpointTimes
        .asMap()
        .entries
        .map(
          (MapEntry<int, TimeOfDay> entry) {
            final String checkpointTime =
                '${entry.value.hour.toString().padLeft(2, '0')}:${entry.value.minute.toString().padLeft(2, '0')}';
            // Use existing checkpoint ID if available, otherwise create new
            if (widget.goal.checkpoints.length > entry.key) {
              final GoalCheckpoint existing = widget.goal.checkpoints[entry.key];
              return GoalCheckpoint(
                id: existing.id,
                goalId: widget.goal.id,
                checkpointTime: checkpointTime,
                position: entry.key,
                createdAt: existing.createdAt,
              );
            } else {
              return GoalCheckpoint(
                id: 0,
                goalId: widget.goal.id,
                checkpointTime: checkpointTime,
                position: entry.key,
                createdAt: DateTime.now(),
              );
            }
          },
        )
        .toList();

    // Create an updated Goal object
    final GoalModel updatedGoal = GoalModel(
      id: widget.goal.id,
      name: goalNameController.text,
      category: widget.goal.category,
      cycle: selectedCycle.name,
      activeDays: selectedDays.toList().join(','),
      dataMetricType: widget.goal.dataMetricType,
      occurrences: selectedCycle == GoalCycle.daily ? occurrencesPerCycle : null,
      dayOfMonth: selectedCycle == GoalCycle.monthly ? selectedDayOfMonth : null,
      isActive: widget.goal.isActive,
      createdAt: widget.goal.createdAt,
      updatedAt: DateTime.now(),
      checkpoints: updatedCheckpoints,
      eventCount: widget.goal.eventCount,
    );

    widget.onGoalUpdated?.call(updatedGoal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: <Widget>[
          // Sheet Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'UPDATE GOAL',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.onClose?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: <Widget>[
                  // Section 1: Goal Name
                  GoalNameSection(
                    theme: theme,
                    controller: goalNameController,
                    buildSection: _buildSection,
                    sectionTitle: 'GOAL NAME',
                  ),
                  if (goalNameError != null)
                    Text(
                      goalNameError!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),

                  // Section 2: Category (Read-only)
                  _buildSection(
                    title: 'CATEGORY (READ-ONLY)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        widget.goal.category,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Section 3: Goal Cycle
                  GoalCycleSection(
                    theme: theme,
                    selectedCycle: selectedCycle,
                    selectedDays: selectedDays,
                    dayLabels: dayLabels,
                    selectedDayOfMonth: selectedDayOfMonth,
                    dayOfMonthController: dayOfMonthController,
                    occurrencesPerCycle: occurrencesPerCycle,
                    onCycleChanged: (GoalCycle value) {
                      setState(() {
                        selectedCycle = value;
                      });
                    },
                    onDayToggled: _toggleDay,
                    onDayOfMonthChanged: (int value) {
                      setState(() {
                        selectedDayOfMonth = value;
                      });
                    },
                    onOccurrencesChanged: (int value) {
                      setState(() {
                        occurrencesPerCycle = value;
                      });
                    },
                    buildSection: _buildSection,
                  ),
                  if (daysError != null)
                    Text(
                      daysError!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),

                  // Section 4: Checkpoints
                  CheckpointsSection(
                    theme: theme,
                    context: context,
                    checkpointTimes: checkpointTimes,
                    onTimeSelected: _selectTime,
                    onCheckpointRemoved: _removeCheckpoint,
                    onCheckpointAdded: _addCheckpoint,
                    buildSection: _buildSection,
                  ),
                  if (checkpointsError != null)
                    Text(
                      checkpointsError!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),

                  // Section 5: Data Logging Protocol (Read-only)
                  _buildSection(
                    title: 'DATA LOGGING PROTOCOL (READ-ONLY)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: theme.colorScheme.surface.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        widget.goal.dataMetricType.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom spacing for fixed button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Fixed Footer Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              color: theme.colorScheme.surface.withValues(alpha: 0.95),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  elevation: 8,
                  shadowColor: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'UPDATE GOAL',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        child,
      ],
    );
  }
}
