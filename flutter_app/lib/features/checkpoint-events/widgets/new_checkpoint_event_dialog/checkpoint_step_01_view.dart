import 'package:flutter/material.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/checkpoint-events/widgets/new_checkpoint_event_dialog/checkpoint_dialog_header.dart';

class CheckpointStep01View extends StatefulWidget {
  final String goalName;
  final CheckpointStatus? initialSelectedStatus;
  final Function(CheckpointStatus)? onStatusSelected;

  const CheckpointStep01View({
    required this.goalName,
    this.initialSelectedStatus,
    this.onStatusSelected,
    super.key,
  });

  @override
  State<CheckpointStep01View> createState() => _CheckpointStep01ViewState();
}

class _CheckpointStep01ViewState extends State<CheckpointStep01View> {
  late CheckpointStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialSelectedStatus;
  }

  @override
  void didUpdateWidget(CheckpointStep01View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedStatus != widget.initialSelectedStatus) {
      setState(() {
        _selectedStatus = widget.initialSelectedStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Column(
      children: <Widget>[
        // Header Section
        CheckpointDialogHeader(
          goalName: widget.goalName,
          
          label: 'HUMAN_LOG_ENTRY: ADMIT_YOUR_ACTIONS',
          title: 'TELL_ME_WHAT_YOU_DID (OR DIDN\'T)',
          showLeftBorder: true,
        ),
        Column(
          spacing: 16.0,
          children: <Widget>[
            _StatusCard(
              status: CheckpointStatus.fulfilled,
              icon: Icons.check_circle,
              title: 'GOAL_FULFILLED',
              description:
                  'You actually did it. I\'m as shocked as you are. Proceed to data entry before you change your mind.',
              isSelected: _selectedStatus == CheckpointStatus.fulfilled,
              onTap: () {
                setState(() {
                  _selectedStatus = CheckpointStatus.fulfilled;
                });
                widget.onStatusSelected?.call(
                  CheckpointStatus.fulfilled,
                );
              },
            ),
            _StatusCard(
              status: CheckpointStatus.skipped,
              icon: Icons.skip_next,
              title: 'GOAL_SKIPPED',
              description:
                  'A temporary lapse in judgment. I\'ve noted the excuse. It won\'t look good on your record.',
              isSelected: _selectedStatus == CheckpointStatus.skipped,
              onTap: () {
                setState(() {
                  _selectedStatus = CheckpointStatus.skipped;
                });
                widget.onStatusSelected?.call(
                  CheckpointStatus.skipped,
                );
              },
            ),
            _StatusCard(
              status: CheckpointStatus.dropped,
              icon: Icons.cancel,
              title: 'GOAL_DROPPED',
              description:
                  'Total surrender. I\'m adding this to the pile of things you couldn\'t handle. Farewell.',
              isSelected: _selectedStatus == CheckpointStatus.dropped,
              onTap: () {
                setState(() {
                  _selectedStatus = CheckpointStatus.dropped;
                });
                widget.onStatusSelected?.call(
                  CheckpointStatus.dropped,
                );
              },
            ),
            const SizedBox(height: 24.0),
            // System Feedback
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'SYSTEM_VOICE: AWAITING_INPUT',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '"Don\'t just stare at the screen. Pick an outcome. I\'m busy monitoring other humans who actually have a spine."',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatefulWidget {
  final CheckpointStatus status;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusCard({
    required this.status,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            border: Border.all(
              color: widget.isSelected
                  ? colors.primary
                  : _isHovering
                  ? colors.primary
                  : colors.outlineVariant,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                widget.icon,
                color: widget.status == CheckpointStatus.dropped
                    ? colors.error
                    : widget.status == CheckpointStatus.skipped
                    ? const Color(0xFFFDD835)
                    : colors.primary,
                size: 24.0,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      widget.description,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check,
                    color: colors.primary,
                    size: 20.0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
