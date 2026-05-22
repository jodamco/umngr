import 'dart:convert';

import 'package:micro_manager/core/services/notification/notification_service.dart';
import 'package:micro_manager/features/notifications/dal/notifications_dal.dart';
import 'package:micro_manager/features/notifications/models/notification_model.dart';

class NotificationsBLL {
  NotificationsBLL(this._dal, this._notificationService);

  final NotificationsDAL _dal;
  final NotificationService _notificationService;

  /// Persists a notification record and schedules it on the device.
  /// The DB row id is used as the notification plugin id so they stay in sync.
  Future<NotificationModel> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledAt,
    int? foreignId,
    Map<String, dynamic>? payload,
  }) async {
    final int id = await _dal.createNotification(
      NewNotificationModel(
        title: title,
        body: body,
        foreignId: foreignId,
        payload: payload,
        scheduledAt: scheduledAt,
      ),
    );

    await _notificationService.schedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      payload: payload != null ? jsonEncode(payload) : null,
    );

    return (await _dal.getNotificationById(id))!;
  }

  /// Cancels a notification on the device and marks it as cancelled in the DB.
  Future<void> cancelNotification(NotificationModel notification) async {
    await _notificationService.cancel(notification.id);
    await _dal.cancelNotification(notification.id);
  }

  /// Cancels all notifications on the device and marks all as cancelled in the DB.
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAll();
    await _dal.cancelAllNotifications();
  }

  /// Returns notifications from the DB, optionally filtered by cancellation state.
  Future<List<NotificationModel>> getNotifications({bool? isCancelled}) =>
      _dal.getNotifications(isCancelled: isCancelled);

  Future<NotificationModel?> getNotificationById(int id) =>
      _dal.getNotificationById(id);
}
