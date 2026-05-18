import 'package:flutter/material.dart';

class GoalNameSection extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController controller;
  final Widget Function({required String title, required Widget child})
      buildSection;
  final String sectionTitle;

  const GoalNameSection({
    required this.theme,
    required this.controller,
    required this.buildSection,
    this.sectionTitle = 'GOAL NAME',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSection(
      title: sectionTitle,
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
