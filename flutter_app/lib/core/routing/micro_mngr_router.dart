import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_manager/core/routing/routes.dart';
import 'package:micro_manager/features/goals/views/goals_view.dart';
import 'package:micro_manager/features/goals/views/goal_detail_view.dart';
import 'package:micro_manager/widgets/micro_mngr_app_bar.dart';
import 'package:micro_manager/widgets/micro_mngr_nav_bar.dart';

abstract final class MicroMngrRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String _getTitleForRoute(GoRouterState state) {
    final String location = state.uri.path;

    if (location.contains('details')) {
      return 'PROTOCOL_OVERVIEW';
    }

    return switch (location) {
      Routes.goals => 'µMNGR: OH, YOU\'RE BACK.',
      _ => 'µMNGR: OH, YOU\'RE BACK.',
    };
  }

  static bool _shouldShowBackButton(GoRouterState state) {
    final String location = state.uri.path;
    // Show back button for subroutes (e.g., details pages)
    return location.contains('details');
  }

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.goals,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return Scaffold(
                appBar: MicroMngrAppBar(
                  title: _getTitleForRoute(state),
                  showBackButton: _shouldShowBackButton(state),
                ),
                body: navigationShell,
                bottomNavigationBar: MicroMngrNavBar(
                  navigationShell: navigationShell,
                ),
                resizeToAvoidBottomInset: false,
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.goals,
                builder: (BuildContext context, GoRouterState state) =>
                    const GoalsView(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'details/:goalId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String goalId = state.pathParameters['goalId']!;
                      return GoalDetailView(
                        goalId: int.parse(goalId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('Look again, you are lost!')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('I can\'t believe that happened again. Start over...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go(Routes.goals),
              child: const Text('Back to Goals'),
            ),
          ],
        ),
      ),
    ),
  );
}
