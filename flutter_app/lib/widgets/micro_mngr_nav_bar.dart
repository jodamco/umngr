import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MicroMngrNavBar extends StatelessWidget {
  const MicroMngrNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 72.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        backgroundColor: theme.scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 10,
          letterSpacing: 0.8,
        ),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _buildNavItem(
              isSelected: navigationShell.currentIndex == 0,
              icon: Icons.assignment_late,
              label: 'GOALS',
              theme: theme,
            ),
            label: 'GOALS',
          ),
          BottomNavigationBarItem(
            icon: _buildNavItem(
              isSelected: navigationShell.currentIndex == 1,
              icon: Icons.visibility,
              label: 'JUDGMENT',
              theme: theme,
            ),
            label: 'JUDGMENT',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required bool isSelected,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 24,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
