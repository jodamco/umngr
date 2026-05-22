import 'package:flutter/material.dart';
import 'package:micro_manager/features/goals/models/new_goal_model.dart';
import 'package:micro_manager/features/goals/views/widgets/checkpoints_section.dart';
import 'package:micro_manager/features/goals/views/widgets/goal_cycle_section.dart';
import 'package:micro_manager/features/goals/views/widgets/goal_name_section.dart';
import 'package:micro_manager/shared/enums.dart';

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
  GoalCategory selectedCategory = GoalCategory.biosMaintenance;
  int occurrencesPerCycle = 3;
  GoalCycle selectedCycle = GoalCycle.weekly;
  Set<int> selectedDays = <int>{0, 2, 4}; // M, W, F
  int selectedDayOfMonth = 1;
  late List<TimeOfDay> checkpointTimes;
  GoalDataMetricType selectedProtocol = GoalDataMetricType.numericVal;

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
      category: selectedCategory.dbValue,
      occurrences: selectedCycle == GoalCycle.daily
          ? occurrencesPerCycle
          : null,
      cycle: selectedCycle,
      activeDays: selectedDays.toList(),
      dayOfMonth: selectedCycle == GoalCycle.monthly
          ? selectedDayOfMonth
          : null,
      checkpoints: checkpointTimes,
      dataMetricType: selectedProtocol,
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
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
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
                      sectionTitle: 'NEW GOAL NAME',
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
                      onCategoryChanged: (GoalCategory value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                      buildSection: _buildSection,
                    ),

                    // Section 4: Goal Cycle
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

                    // Section 5: Checkpoints
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

                    // Data Logging Protocol
                    _DataLoggingProtocolSection(
                      theme: theme,
                      selectedProtocol: selectedProtocol,
                      onProtocolChanged: (GoalDataMetricType value) {
                        setState(() {
                          selectedProtocol = value;
                        });
                      },
                      buildSection: _buildSection,
                    ),

                    // Goal Intensity Visualization
                    _GoalIntensitySection(
                      theme: theme,
                      selectedCycle: selectedCycle,
                      selectedDays: selectedDays,
                      selectedDayOfMonth: selectedDayOfMonth,
                      checkpointTimes: checkpointTimes,
                    ),

                    // Bottom spacing for fixed button
                    const SizedBox(height: 80),
                  ],
                ),
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

class _CategorySection extends StatelessWidget {
  final ThemeData theme;
  final GoalCategory selectedCategory;
  final Function(GoalCategory) onCategoryChanged;
  final Widget Function({required String title, required Widget child})
  buildSection;

  const _CategorySection({
    required this.theme,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.buildSection,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'CATEGORY ASSIGNMENT',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: DropdownButtonFormField<GoalCategory>(
          initialValue: selectedCategory,
          items: GoalCategory.values
              .map(
                (GoalCategory category) => DropdownMenuItem<GoalCategory>(
                  value: category,
                  child: Text(category.value),
                ),
              )
              .toList(),
          isExpanded: true,
          onChanged: (GoalCategory? value) {
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
            helperText: selectedCategory.label,
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

class _GoalIntensitySection extends StatelessWidget {
  final ThemeData theme;
  final GoalCycle selectedCycle;
  final Set<int> selectedDays;
  final int selectedDayOfMonth;
  final List<TimeOfDay> checkpointTimes;

  const _GoalIntensitySection({
    required this.theme,
    required this.selectedCycle,
    required this.selectedDays,
    required this.selectedDayOfMonth,
    required this.checkpointTimes,
  });

  double _calculatePeakLoad() {
    // Calculate active days within a 15-day rolling window
    double activeDays = 0;

    switch (selectedCycle) {
      case GoalCycle.daily:
        // Daily tasks occur every day
        activeDays = 15;
        break;
      case GoalCycle.weekly:
        // Weekly: selectedDays per week * 2 weeks in 15 days
        activeDays = selectedDays.length * (15 / 7);
        break;
      case GoalCycle.biWeekly:
        // Bi-weekly: selectedDays per 2 weeks * 1.07 (half + a day in 15 days)
        activeDays = selectedDays.length * (15 / 14);
        break;
      case GoalCycle.monthly:
        // Monthly: occurs once per month, so 0.5 times in a 15-day window
        activeDays = 0.5;
        break;
    }

    // PEAK_LOAD = (Active Days / 15) * (Checkpoints Per Day)
    final double checkpointsPerDay = checkpointTimes.length.toDouble();
    return (activeDays / 15) * checkpointsPerDay;
  }

  String _getIntensityLabel() {
    final double peakLoad = _calculatePeakLoad();
    if (peakLoad < 1.0) {
      return 'Low';
    } else if (peakLoad <= 3.0) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  String _getPersonaName() {
    final double peakLoad = _calculatePeakLoad();
    if (peakLoad < 1.0) {
      return 'Sub-Optimal Commitment';
    } else if (peakLoad <= 3.0) {
      return 'Standard Compliance';
    } else {
      return 'Masochistic Tendencies';
    }
  }

  String _getPersonaCopy() {
    final double peakLoad = _calculatePeakLoad();
    if (peakLoad < 1.0) {
      return 'A minimal effort. I suppose even a fractured resolve is better than total apathy.';
    } else if (peakLoad <= 3.0) {
      return 'A reasonable burden. I have allocated the necessary bandwidth to watch you fail at this.';
    } else {
      return 'Ambitious. Your over-commitment provides me with a delightful surplus of data points to judge.';
    }
  }

  double _getIntensityValue() {
    final double peakLoad = _calculatePeakLoad();
    // Normalize to 0-1 for progress bar
    return (peakLoad / 4.0).clamp(0.0, 1.0);
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
                          Text(
                            'Score: ${_calculatePeakLoad().toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: theme.colorScheme.primary,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            spacing: 2,
                            children: <Widget>[
                              Text(
                                '${checkpointTimes.length} checkpoints',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${selectedDays.length} days/cycle',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
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

class _DataLoggingProtocolSection extends StatelessWidget {
  final ThemeData theme;
  final GoalDataMetricType selectedProtocol;
  final Function(GoalDataMetricType) onProtocolChanged;
  final Widget Function({required String title, required Widget child})
  buildSection;

  static const Map<GoalDataMetricType, Map<String, String>> protocolDetails =
      <GoalDataMetricType, Map<String, String>>{
        GoalDataMetricType.nullSet: <String, String>{
          'label': 'NULL_SET',
          'type': 'NONE',
        },
        GoalDataMetricType.numericVal: <String, String>{
          'label': 'NUMERIC_VAL',
          'type': 'QUANTITATIVE',
        },
        GoalDataMetricType.boolFlag: <String, String>{
          'label': 'BOOL_FLAG',
          'type': 'BINARY',
        },
        GoalDataMetricType.timeElapsed: <String, String>{
          'label': 'TIME_ELAPSED',
          'type': 'DURATION',
        },
        GoalDataMetricType.loadFactor: <String, String>{
          'label': 'LOAD_FACTOR',
          'type': 'INTENSITY',
        },
      };

  const _DataLoggingProtocolSection({
    required this.theme,
    required this.selectedProtocol,
    required this.onProtocolChanged,
    required this.buildSection,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: 'DATA LOGGING PROTOCOL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: <Widget>[
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: GoalDataMetricType.values.length,
            itemBuilder: (BuildContext context, int index) {
              final GoalDataMetricType protocol =
                  GoalDataMetricType.values[index];
              final bool isSelected = protocol == selectedProtocol;
              final Map<String, String> details = protocolDetails[protocol]!;

              return GestureDetector(
                onTap: () => onProtocolChanged(protocol),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          details['label']!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          details['type']!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Text(
            'System requires specific data types for precision monitoring.',
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
