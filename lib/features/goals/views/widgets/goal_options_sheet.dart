import 'package:flutter/material.dart';
import 'package:micro_manager/features/goals/models/goal.dart';

class GoalOptionsSheet extends StatelessWidget {
  final Goal goal;

  const GoalOptionsSheet({
    required this.goal,
    super.key,
  });

  void _showAddCheckpoint(BuildContext context) {
    // TODO: Implement add checkpoint logic
    Navigator.pop(context);
  }

  void _showCompleteObligation(BuildContext context) {
    // TODO: Implement complete obligation logic
    Navigator.pop(context);
  }

  void _showEditProtocol(BuildContext context) {
    // TODO: Implement edit protocol logic
    Navigator.pop(context);
  }

  void _showArchiveObligation(BuildContext context) {
    // TODO: Implement archive obligation logic
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16.0,
              children: <Widget>[
                // Action Buttons
                _ActionButton(
                  label: 'ADD_CHECKPOINT',
                  icon: Icons.add_circle,
                  onPressed: () => _showAddCheckpoint(context),
                ),
                _ActionButton(
                  label: 'COMPLETE_OBLIGATION',
                  icon: Icons.check_circle,
                  onPressed: () => _showCompleteObligation(context),
                ),
                _ActionButton(
                  label: 'EDIT_PROTOCOL',
                  icon: Icons.edit,
                  onPressed: () => _showEditProtocol(context),
                ),
                _ActionButton(
                  label: 'ARCHIVE_OBLIGATION',
                  icon: Icons.archive,
                  isDestructive: true,
                  onPressed: () => _showArchiveObligation(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color buttonColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: buttonColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: buttonColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
