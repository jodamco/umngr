import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_manager/core/routing/routes.dart';

class MicroMngrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const MicroMngrAppBar({
    required this.title,
    this.showBackButton = false,
    super.key,
  });

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    return context.go(Routes.goals);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      scrolledUnderElevation: 0.0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _onBack(context),
            )
          : null,
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
              title,
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
