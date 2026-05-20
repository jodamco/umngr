import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/shared/enums.dart';
import 'package:micro_manager/features/checkpoint-events/widgets/new_checkpoint_event_dialog/checkpoint_dialog_header.dart';

class CheckpointStep02View extends StatefulWidget {
  final String goalName;
  final CheckpointStatus status;
  final GoalDataMetricType dataMetricType;
  final Function(String?, String?)? onDataChanged; // (dataValue, notes)
  final String? initialDataValue;
  final String? initialNotes;
  final bool allowDataInput;

  const CheckpointStep02View({
    required this.goalName,
    required this.status,
    required this.dataMetricType,
    this.onDataChanged,
    this.initialDataValue,
    this.initialNotes,
    this.allowDataInput = true,
    super.key,
  });

  @override
  State<CheckpointStep02View> createState() => _CheckpointStep02ViewState();
}

class _CheckpointStep02ViewState extends State<CheckpointStep02View> {
  late TextEditingController _dataValueController;
  late TextEditingController _notesController;
  bool? _boolValue;
  double? _loadFactorValue;

  // Expose validation state for parent components
  bool get isFormValid {
    if (!widget.dataMetricType.shouldShowInput || !widget.allowDataInput) {
      return true;
    }
    switch (widget.dataMetricType) {
      case GoalDataMetricType.boolFlag:
        return _boolValue != null;
      case GoalDataMetricType.loadFactor:
        return _loadFactorValue != null;
      default:
        return _dataValueController.text.trim().isNotEmpty;
    }
  }

  String? get dataValue {
    switch (widget.dataMetricType) {
      case GoalDataMetricType.boolFlag:
        return _boolValue?.toString();
      case GoalDataMetricType.loadFactor:
        return _loadFactorValue?.toStringAsFixed(0);
      default:
        return _dataValueController.text.isEmpty
            ? null
            : _dataValueController.text;
    }
  }

  String? get notes =>
      _notesController.text.isEmpty ? null : _notesController.text;

  @override
  void initState() {
    super.initState();
    _dataValueController = TextEditingController(
      text: widget.initialDataValue ?? '',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');

    // Initialize boolean value
    if (widget.dataMetricType == GoalDataMetricType.boolFlag &&
        widget.initialDataValue != null) {
      _boolValue = widget.initialDataValue == 'true';
    }

    // Initialize load factor value
    if (widget.dataMetricType == GoalDataMetricType.loadFactor &&
        widget.initialDataValue != null) {
      _loadFactorValue = double.tryParse(widget.initialDataValue ?? '0') ?? 0;
    }

    _dataValueController.addListener(_onValueChanged);
    _notesController.addListener(_onValueChanged);
  }

  void _onValueChanged() {
    widget.onDataChanged?.call(
      dataValue,
      _notesController.text,
    );
  }

  void _setBoolValue(bool value) {
    setState(() {
      _boolValue = value;
    });
    _onValueChanged();
  }

  void _setLoadFactorValue(double value) {
    setState(() {
      _loadFactorValue = value;
    });
    _onValueChanged();
  }

  @override
  void dispose() {
    _dataValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TextInputType _getKeyboardType() {
    switch (widget.dataMetricType) {
      case GoalDataMetricType.numericVal:
        return const TextInputType.numberWithOptions(decimal: true);
      case GoalDataMetricType.timeElapsed:
        return TextInputType.number;
      case GoalDataMetricType.loadFactor:
        return const TextInputType.numberWithOptions(decimal: false);
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.dataMetricType) {
      case GoalDataMetricType.numericVal:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ];
      case GoalDataMetricType.timeElapsed:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ];
      case GoalDataMetricType.loadFactor:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ];
      default:
        return <TextInputFormatter>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final DateTime now = DateTime.now();
    final String timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return Column(
      children: <Widget>[
        CheckpointDialogHeader(
          goalName: widget.goalName,
          label: '${widget.status.displayName.toUpperCase()} // CONFIRMED',
          title: 'TELL_ME_HOW_MUCH_YOU_DID (OR DIDN\'T)',
          showLeftBorder: true,
        ),
        // Data Input Section (if applicable)
        if (widget.dataMetricType.shouldShowInput &&
            widget.allowDataInput) ...<Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.dataMetricType.inputLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 12.0),
              // Boolean Input: Yes/No Buttons
              if (widget.dataMetricType ==
                  GoalDataMetricType.boolFlag) ...<Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setBoolValue(true),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _boolValue == true
                              ? colors.primary
                              : colors.surfaceContainerLowest,
                          side: BorderSide(
                            color: _boolValue == true
                                ? colors.primary
                                : colors.outline,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          'YES',
                          style: textTheme.labelSmall?.copyWith(
                            color: _boolValue == true
                                ? colors.onPrimary
                                : colors.onSurface,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setBoolValue(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _boolValue == false
                              ? colors.primary
                              : colors.surfaceContainerLowest,
                          side: BorderSide(
                            color: _boolValue == false
                                ? colors.primary
                                : colors.outline,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          'NO',
                          style: textTheme.labelSmall?.copyWith(
                            color: _boolValue == false
                                ? colors.onPrimary
                                : colors.onSurface,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Load Factor Input: Slider/Knob
              if (widget.dataMetricType ==
                  GoalDataMetricType.loadFactor) ...<Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Slider(
                      value: _loadFactorValue ?? 0,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${(_loadFactorValue ?? 0).toStringAsFixed(0)}%',
                      onChanged: _setLoadFactorValue,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Selected: ${(_loadFactorValue ?? 0).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              // Numeric/Time Input: Text Field
              if (widget.dataMetricType == GoalDataMetricType.numericVal ||
                  widget.dataMetricType ==
                      GoalDataMetricType.timeElapsed) ...<Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _dataValueController,
                    maxLength: 20,
                    keyboardType: _getKeyboardType(),
                    inputFormatters: _getInputFormatters(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.1,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.dataMetricType.inputPlaceholder,
                      hintStyle: textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                      contentPadding: const EdgeInsets.all(12.0),
                      border: InputBorder.none,
                      fillColor: colors.surfaceContainerLowest,
                      filled: true,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child:
                            widget.dataMetricType ==
                                GoalDataMetricType.timeElapsed
                            ? Text(
                                'MINUTES',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  letterSpacing: 0.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'TYPE:',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.outlineVariant,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    widget.dataMetricType.typeLabel,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.primary,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24.0),
        ],
        // Observations Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'GIVE_ME_YOUR_EXCUSES.TXT',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.1,
                  ),
                ),
                Text(
                  '(OPTIONAL)',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.outlineVariant,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _notesController,
                maxLength: 200,
                maxLines: 6,
                minLines: 4,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                      'PROVIDE_QUALITATIVE_CONTEXT_FOR_CENTRAL_PROCESSING',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                  contentPadding: const EdgeInsets.all(12.0),
                  border: InputBorder.none,
                  fillColor: colors.surfaceContainerLowest,
                  filled: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        // System Metadata Card
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.3),
            ),
            color: colors.surfaceContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'SYSTEM_METADATA',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 16.0,
                    color: textTheme.labelSmall?.color,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Divider(
                height: 1.0,
                color: colors.outlineVariant,
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'TIMESTAMP',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outlineVariant,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    timestamp,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SOURCE',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outlineVariant,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'POTENTIALLY_UNRELIABLE_HUMAN',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'NODE_ID',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outlineVariant,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'LOCAL_U_0982',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'INTEGRITY_CHECK',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.outlineVariant,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'PASS_SECURE',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
