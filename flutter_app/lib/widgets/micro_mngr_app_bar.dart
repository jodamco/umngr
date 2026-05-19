import 'package:flutter/material.dart';

class MicroMngrAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MicroMngrAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      scrolledUnderElevation: 0.0,
      title: Row(
        children: <Widget>[
          Icon(
            Icons.terminal,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'µMNGR: OH, YOU\'RE BACK.',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
