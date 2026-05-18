import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/features/checkpoint-events/dal/checkpoint_events_dal.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/checkpoint-events/widgets/new_checkpoint_event_dialog/checkpoint_step_01_view.dart';
import 'package:micro_manager/features/checkpoint-events/widgets/new_checkpoint_event_dialog/checkpoint_step_02_view.dart';
import 'package:micro_manager/shared/enums.dart';

class NewCheckpointEventDialog extends StatefulWidget {
  final int goalId;
  final String goalName;
  final GoalDataMetricType dataMetricType;
  final Function(AddCheckpointEvent)? onCheckpointSubmitted;

  const NewCheckpointEventDialog({
    required this.goalId,
    required this.goalName,
    required this.dataMetricType,
    this.onCheckpointSubmitted,
    super.key,
  });

  @override
  State<NewCheckpointEventDialog> createState() =>
      _NewCheckpointEventDialogState();
}

class _NewCheckpointEventDialogState extends State<NewCheckpointEventDialog> {
  int _currentStep = 1;
  CheckpointStatus? _selectedStatus;
  String? _dataValue;
  String? _notes;
  bool _isSubmitting = false;

  void _goToNextStep() {
    if (_currentStep == 1 && _selectedStatus != null) {
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  Future<void> _submitCheckpoint() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AddCheckpointEvent checkpoint = AddCheckpointEvent(
        goalId: widget.goalId,
        status: _selectedStatus!,
        dataValue: _dataValue?.isNotEmpty == true ? _dataValue : null,
        notes: _notes?.isNotEmpty == true ? _notes : null,
        eventDateTime: DateTime.now(),
      );

      // Save to database
      final CheckpointEventsDAL dal = getIt<CheckpointEventsDAL>();
      await dal.createCheckpointEvent(checkpoint);

      widget.onCheckpointSubmitted?.call(checkpoint);

      if (mounted) {
        Navigator.of(context).pop(checkpoint);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving checkpoint: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 1) {
      return CheckpointStep01View(
        goalName: widget.goalName,
        initialSelectedStatus: _selectedStatus,
        onStatusSelected: (CheckpointStatus status) {
          setState(() {
            _selectedStatus = status;
          });
        },
      );
    } else if (_currentStep == 2 && _selectedStatus != null) {
      return CheckpointStep02View(
        goalName: widget.goalName,
        status: _selectedStatus!,
        dataMetricType: widget.dataMetricType,
        initialDataValue: _dataValue,
        initialNotes: _notes,
        onDataChanged: (String? dataValue, String? notes) {
          setState(() {
            _dataValue = dataValue;
            _notes = notes;
          });
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Dialog.fullscreen(
      child: Column(
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.outlineVariant,
                  width: 1.0,
                ),
              ),
              color: colors.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'CHECKPOINT_SUBMISSION',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    letterSpacing: 0.05,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 0.0,
                left: 16.0,
                right: 16.0,
                bottom: 24.0,
              ),
              child: _buildCurrentStep(),
            ),
          ),
          // Bottom Actions
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant,
                  width: 1.0,
                ),
              ),
              color: colors.surface,
            ),
            padding: EdgeInsets.fromLTRB(
              24.0,
              16.0,
              24.0,
              16.0 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // Back Button
                if (_currentStep == 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToPreviousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 24.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 8,
                        shadowColor: colors.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Icon(
                            Icons.arrow_back,
                            size: 20.0,
                            color: colors.onPrimary,
                          ),
                          Text(
                            'BACK',
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 20.0),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (_currentStep == 2)
                  const SizedBox(width: 12.0)
                else
                  const SizedBox.shrink(),
                const Spacer(),
                // Next or Submit Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_currentStep == 1 && _selectedStatus != null
                              ? _goToNextStep
                              : (_currentStep == 2 && _selectedStatus != null)
                              ? _submitCheckpoint
                              : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_currentStep == 1 && _selectedStatus == null) ||
                              (_currentStep == 2 && _selectedStatus == null)
                          ? colors.outlineVariant.withValues(alpha: 0.3)
                          : colors.primary,
                      foregroundColor:
                          (_currentStep == 1 && _selectedStatus == null) ||
                              (_currentStep == 2 && _selectedStatus == null)
                          ? colors.onSurfaceVariant
                          : colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation:
                          (_currentStep == 1 && _selectedStatus == null) ||
                              (_currentStep == 2 && _selectedStatus == null)
                          ? 0
                          : 8,
                      shadowColor: colors.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        if (_isSubmitting) {
                          return SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.onPrimary,
                              ),
                              strokeWidth: 2.0,
                            ),
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              _currentStep == 1 ? 'NEXT' : 'SUBMIT',
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color:
                                    (_currentStep == 1 &&
                                            _selectedStatus == null) ||
                                        (_currentStep == 2 &&
                                            _selectedStatus == null)
                                    ? colors.onSurfaceVariant
                                    : colors.onPrimary,
                              ),
                            ),
                            Icon(
                              _currentStep == 1
                                  ? Icons.arrow_forward
                                  : Icons.check_circle_outline,
                              size: 20.0,
                              color:
                                  (_currentStep == 1 &&
                                          _selectedStatus == null) ||
                                      (_currentStep == 2 &&
                                          _selectedStatus == null)
                                  ? colors.onSurfaceVariant
                                  : colors.onPrimary,
                            ),
                          ],
                        );
                      },
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
