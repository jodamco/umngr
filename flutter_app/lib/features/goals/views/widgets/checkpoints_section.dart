import 'package:flutter/material.dart';

class CheckpointsSection extends StatelessWidget {
  final ThemeData theme;
  final BuildContext context;
  final List<TimeOfDay> checkpointTimes;
  final Function(int) onTimeSelected;
  final Function(int) onCheckpointRemoved;
  final VoidCallback onCheckpointAdded;
  final Widget Function({required String title, required Widget child})
      buildSection;

  const CheckpointsSection({
    required this.theme,
    required this.context,
    required this.checkpointTimes,
    required this.onTimeSelected,
    required this.onCheckpointRemoved,
    required this.onCheckpointAdded,
    required this.buildSection,
    super.key,
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
