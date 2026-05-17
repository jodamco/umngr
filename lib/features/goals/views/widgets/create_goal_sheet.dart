import 'package:flutter/material.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';

class CreateGoalSheet extends StatefulWidget {
  final VoidCallback? onClose;
  final Function(NewGoalModel)? onGoalCreated;

  const CreateGoalSheet({
    this.onClose,
    this.onGoalCreated,
    super.key,
  });

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final TextEditingController goalNameController = TextEditingController();
  late TextEditingController dayOfMonthController;
  String selectedCategory = 'CAT_BIOS_MAINTENANCE.SYS';
  int occurrencesPerCycle = 3;
  GoalCycle selectedCycle = GoalCycle.weekly;
  Set<int> selectedDays = <int>{0, 2, 4}; // M, W, F
  int selectedDayOfMonth = 1;
  late List<TimeOfDay> checkpointTimes;

  // Error states for inline error messages
  String? daysError;
  String? checkpointsError;
  String? goalNameError;

  @override
  void initState() {
    super.initState();
    dayOfMonthController = TextEditingController(
      text: selectedDayOfMonth.toString().padLeft(2, '0'),
    );
    checkpointTimes = <TimeOfDay>[
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
    ];
  }

  final List<String> dayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> categoryOptions = <String>[
    'CAT_BIOS_MAINTENANCE.SYS',
    'CAT_COGNITIVE_LOAD.SYS',
    'CAT_ASSET_MANAGEMENT.SYS',
    'CAT_SOCIAL_PROTOCOL.SYS',
    'CAT_SYSTEM_RECOVERY.SYS',
  ];

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
    final NewGoalModel newGoal = NewGoalModel(
      name: goalNameController.text,
      category: selectedCategory,
      occurrences: occurrencesPerCycle,
      cycle: selectedCycle,
      activeDays: selectedDays.toList(),
      dayOfMonth: selectedCycle == GoalCycle.monthly
          ? selectedDayOfMonth
          : null,
      checkpoints: checkpointTimes,
    );

    widget.onGoalCreated?.call(newGoal);
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
                  'NEW GOAL ENTRY',
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
                  _GoalNameSection(
                    theme: theme,
                    controller: goalNameController,
                    buildSection: _buildSection,
                  ),
                  if (goalNameError != null)
                    Text(
                      goalNameError!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),

                  // Section 2: Category
                  _CategorySection(
                    theme: theme,
                    selectedCategory: selectedCategory,
                    categoryOptions: categoryOptions,
                    onCategoryChanged: (String value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    buildSection: _buildSection,
                  ),

                  // Section 4: Goal Cycle
                  _GoalCycleSection(
                    theme: theme,
                    selectedCycle: selectedCycle,
                    selectedDays: selectedDays,
                    dayLabels: dayLabels,
                    selectedDayOfMonth: selectedDayOfMonth,
                    dayOfMonthController: dayOfMonthController,
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

                  // Section 3: Occurrences Stepper
                  _OccurrencesSection(
                    theme: theme,
                    occurrencesPerCycle: occurrencesPerCycle,
                    onOccurrencesChanged: (int value) {
                      setState(() {
                        occurrencesPerCycle = value;
                      });
                    },
                  ),

                  // Section 5: Checkpoints
                  _CheckpointsSection(
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

                  // Goal Intensity Visualization
                  _GoalIntensitySection(
                    theme: theme,
                    occurrencesPerCycle: occurrencesPerCycle,
                    checkpointTimes: checkpointTimes,
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
                      'LOG GOAL',
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

class _GoalNameSection extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController controller;
  final Widget Function({required String title, required Widget child})
  buildSection;

  const _GoalNameSection({
    required this.theme,
    required this.controller,
    required this.buildSection,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'NEW GOAL NAME',
      child: TextField(
        controller: controller,
        maxLength: 50,
        decoration: InputDecoration(
          hintText: 'e.g. Daily Reflection',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          counterText: '',
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ThemeData theme;
  final String selectedCategory;
  final List<String> categoryOptions;
  final Function(String) onCategoryChanged;
  final Widget Function({required String title, required Widget child})
  buildSection;

  // Helper text for each category
  static const Map<String, String> categoryHelpers = <String, String>{
    'CAT_BIOS_MAINTENANCE.SYS': 'Wellness & Nutrition',
    'CAT_COGNITIVE_LOAD.SYS': 'Productivity & Learning',
    'CAT_ASSET_MANAGEMENT.SYS': 'Finance & Organization',
    'CAT_SOCIAL_PROTOCOL.SYS': 'Relationships & Community',
    'CAT_SYSTEM_RECOVERY.SYS': 'Rest & Mental Health',
  };

  const _CategorySection({
    required this.theme,
    required this.selectedCategory,
    required this.categoryOptions,
    required this.onCategoryChanged,
    required this.buildSection,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'CATEGORY ASSIGNMENT',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          items: categoryOptions
              .map(
                (String category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          isExpanded: true,
          onChanged: (String? value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            helperText: categoryHelpers[selectedCategory],
            helperStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalCycleSection extends StatelessWidget {
  final ThemeData theme;
  final GoalCycle selectedCycle;
  final Set<int> selectedDays;
  final List<String> dayLabels;
  final int selectedDayOfMonth;
  final TextEditingController dayOfMonthController;
  final Function(GoalCycle) onCycleChanged;
  final Function(int) onDayToggled;
  final Function(int) onDayOfMonthChanged;
  final Widget Function({required String title, required Widget child})
  buildSection;

  const _GoalCycleSection({
    required this.theme,
    required this.selectedCycle,
    required this.selectedDays,
    required this.dayLabels,
    required this.selectedDayOfMonth,
    required this.dayOfMonthController,
    required this.onCycleChanged,
    required this.onDayToggled,
    required this.onDayOfMonthChanged,
    required this.buildSection,
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
          if (selectedCycle == GoalCycle.monthly)
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

class _CheckpointsSection extends StatelessWidget {
  final ThemeData theme;
  final BuildContext context;
  final List<TimeOfDay> checkpointTimes;
  final Function(int) onTimeSelected;
  final Function(int) onCheckpointRemoved;
  final VoidCallback onCheckpointAdded;
  final Widget Function({required String title, required Widget child})
  buildSection;

  const _CheckpointsSection({
    required this.theme,
    required this.context,
    required this.checkpointTimes,
    required this.onTimeSelected,
    required this.onCheckpointRemoved,
    required this.onCheckpointAdded,
    required this.buildSection,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'SCHEDULED CHECKPOINTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkpointTimes.length,
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              itemBuilder: (BuildContext context, int index) {
                final List<String> checkpointNames = <String>[
                  'Alpha',
                  'Beta',
                  'Gamma',
                  'Delta',
                  'Epsilon',
                  'Zeta',
                ];
                final String label = index < checkpointNames.length
                    ? checkpointNames[index]
                    : 'CP${index + 1}';
                return Dismissible(
                  key: ValueKey<TimeOfDay>(checkpointTimes[index]),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onCheckpointRemoved(index),
                  confirmDismiss: (_) async {
                    if (checkpointTimes.length <= 1) {
                      return false;
                    }
                    return true;
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    title: Text(
                      'Checkpoint $label',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () => onTimeSelected(index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          checkpointTimes[index].format(context),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCheckpointAdded,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.add,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ADD CHECKPOINT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Swipe left to delete. Minimum 1 checkpoint required.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalIntensitySection extends StatelessWidget {
  final ThemeData theme;
  final int occurrencesPerCycle;
  final List<TimeOfDay> checkpointTimes;

  const _GoalIntensitySection({
    required this.theme,
    required this.occurrencesPerCycle,
    required this.checkpointTimes,
  });

  String _getIntensityLabel() {
    if (occurrencesPerCycle <= 2) {
      return 'Low';
    } else if (occurrencesPerCycle <= 5) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  String _getPersonaName() {
    if (occurrencesPerCycle <= 2) {
      return 'Sub-Optimal Commitment';
    } else if (occurrencesPerCycle <= 5) {
      return 'Standard Compliance';
    } else {
      return 'Masochistic Tendencies';
    }
  }

  String _getPersonaCopy() {
    if (occurrencesPerCycle <= 2) {
      return 'A minimal effort. I suppose even a fractured resolve is better than total apathy.';
    } else if (occurrencesPerCycle <= 5) {
      return 'A reasonable burden. I have allocated the necessary bandwidth to watch you fail at this.';
    } else {
      return 'Ambitious. Your over-commitment provides me with a delightful surplus of data points to judge.';
    }
  }

  double _getIntensityValue() {
    if (occurrencesPerCycle <= 2) {
      return 0.33;
    } else if (occurrencesPerCycle <= 5) {
      return 0.66;
    } else {
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: <Widget>[
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: <Widget>[
                          Text(
                            'GOAL INTENSITY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          Text(
                            _getIntensityLabel(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 4,
                        children: <Widget>[
                          Text(
                            'PEAK LOAD',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          Text(
                            '${checkpointTimes.length} checkpoints',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _getIntensityValue(),
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surface.withValues(
                        alpha: 0.5,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: theme.colorScheme.surface.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: <Widget>[
                        Text(
                          _getPersonaName(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          _getPersonaCopy(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
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
      ),
    );
  }
}
