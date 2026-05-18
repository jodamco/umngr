import 'package:flutter/material.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/routing/micro_mngr_router.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
