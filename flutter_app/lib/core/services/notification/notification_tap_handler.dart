import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:micro_manager/core/di/service_locator.dart';
import 'package:micro_manager/core/routing/micro_mngr_router.dart';
import 'package:micro_manager/features/checkpoint-events/models/checkpoint_event_model.dart';
import 'package:micro_manager/features/checkpoint-events/widgets/new_checkpoint_event_dialog/new_checkpoint_event_dialog.dart';
import 'package:micro_manager/features/goals/dal/goals_dal.dart';
import 'package:micro_manager/features/goals/models/goal_model.dart';

abstract final class NotificationPayloadType {
  static const String checkpoint = 'checkpoint';
}

Future<void> handleNotificationTap(NotificationResponse response) async {
  if (response.payload == null) return;

  final Map<String, dynamic> data;
  try {
    data = jsonDecode(response.payload!) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  switch (data['type'] as String?) {
    case NotificationPayloadType.checkpoint:
      await _handleCheckpointTap(data);
    default:
      return;
  }
}

Future<void> _handleCheckpointTap(Map<String, dynamic> data) async {
  final int? goalId = data['goal_id'] as int?;
  if (goalId == null) return;

  final GoalModel goal;
  try {
    goal = await getIt<GoalsDAL>().getGoalById(id: goalId);
  } catch (_) {
    return;
  }

  final BuildContext? context = MicroMngrRouter.navigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  await showDialog<AddCheckpointEvent>(
    context: context,
    builder: (_) => NewCheckpointEventDialog(
      goalId: goal.id,
      goalName: goal.name,
      dataMetricType: goal.dataMetricType,
    ),
  );
}
