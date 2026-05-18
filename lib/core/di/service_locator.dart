import 'package:get_it/get_it.dart';
import 'package:micro_manager/core/services/db/db_service.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';

final GetIt getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setupServiceLocator() async {
  // Register database service
  final SqliteDbService dbService = SqliteDbService();
  await dbService.init();
  getIt.registerSingleton<DbAbstraction>(dbService);

  // Register DAL services
  getIt.registerSingleton<GoalsDAL>(GoalsDAL(getIt<DbAbstraction>()));
}
