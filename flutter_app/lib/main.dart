import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_strategy/url_strategy.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/routing/micro_mngr_router.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs instead of hash-based (#) URLs
  setPathUrlStrategy();

  // Initialize timezone database and set local timezone
  tz.initializeTimeZones();
  if (!kIsWeb) {
    final TimezoneInfo localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
  }

  // Setup service locator and initialize dependencies
  await setupServiceLocator();

  runApp(const MicroManager());
}

class MicroManager extends StatelessWidget {
  const MicroManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'µMngr',
      theme: MicroMngrTheme.darkTheme,
      routerConfig: MicroMngrRouter.router,
    );
  }
}
