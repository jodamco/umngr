import 'package:flutter/foundation.dart';

/// Singleton notifier that signals when goals or checkpoint events are mutated.
/// Consumers (e.g. ReportsView) can listen for changes and refresh their data.
class AppDataNotifier extends ChangeNotifier {
  /// Call this whenever a goal is created or updated.
  void onGoalChanged() => notifyListeners();

  /// Call this whenever a checkpoint event is added.
  void onCheckpointAdded() => notifyListeners();
}
