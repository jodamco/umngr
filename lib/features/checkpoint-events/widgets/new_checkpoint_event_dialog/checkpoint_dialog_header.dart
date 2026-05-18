import 'package:flutter/material.dart';

class CheckpointDialogHeader extends StatelessWidget {
  final String goalName;
  final String label;
  final String title;
  final bool showLeftBorder;

  const CheckpointDialogHeader({
    required this.goalName,
    required this.label,
    required this.title,
    this.showLeftBorder = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Left-bordered label section (Step 1)
          if (showLeftBorder)
            Container(
              padding: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: colors.primary,
                    width: 3.0,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'LOGGING_OUTCOME_FOR: ',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: goalName.toUpperCase(),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
