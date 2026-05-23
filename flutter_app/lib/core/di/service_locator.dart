import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:micro_manager/core/services/db/db_service.dart';
import 'package:micro_manager/core/services/notification/notification_service.dart';
import 'package:micro_manager/features/checkpoint-events/dal/checkpoint_events_dal.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';
import 'package:micro_manager/features/notifications/bll/checkpoint_notifications_bll.dart';
import 'package:micro_manager/features/notifications/bll/notifications_bll.dart';
import 'package:micro_manager/features/notifications/dal/notifications_dal.dart';

final GetIt getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setupServiceLocator({
  void Function(NotificationResponse)? onNotificationTap,
}) async {
  // Register database service
  final SqliteDbService dbService = SqliteDbService();
  await dbService.init();
  getIt.registerSingleton<DbAbstraction>(dbService);

  // Register DAL services
  getIt.registerSingleton<GoalsDAL>(GoalsDAL(getIt<DbAbstraction>()));

  getIt.registerSingleton<CheckpointEventsDAL>(
    CheckpointEventsDAL(getIt<DbAbstraction>()),
  );

  getIt.registerSingleton<NotificationsDAL>(
    NotificationsDAL(getIt<DbAbstraction>()),
  );

  // Register notification service
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize(onNotificationTap: onNotificationTap);
  getIt.registerSingleton<NotificationService>(notificationService);

  // Register BLL services
  getIt.registerSingleton<NotificationsBLL>(
    NotificationsBLL(
      getIt<NotificationsDAL>(),
      getIt<NotificationService>(),
    ),
  );

  getIt.registerSingleton<CheckpointNotificationsBLL>(
    CheckpointNotificationsBLL(
      getIt<NotificationsBLL>(),
      getIt<NotificationsDAL>(),
    ),
  );
}
