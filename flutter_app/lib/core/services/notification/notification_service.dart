import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

const String _defaultChannelId = 'micro_manager_channel';
const String _defaultChannelName = 'Micro Manager';
const String _defaultChannelDescription = 'General notifications for Micro Manager';

const String _scheduledChannelId = 'micro_manager_scheduled';
const String _scheduledChannelName = 'Micro Manager Scheduled';
const String _scheduledChannelDescription = 'Scheduled notifications for Micro Manager';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Pre-built details for immediate notifications. Platform-agnostic.
  static const NotificationDetails _immediateDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _defaultChannelId,
      _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Pre-built details for scheduled notifications. Platform-agnostic.
  static const NotificationDetails _scheduledDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _scheduledChannelId,
      _scheduledChannelName,
      channelDescription: _scheduledChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  }

  /// Requests notification permissions from the user.
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Shows a notification immediately.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _immediateDetails,
      payload: payload,
    );
  }

  /// Schedules a notification at the given [scheduledDate].
  /// Uses the device's local timezone.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _scheduledDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels a single notification by [id].
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Cancels all pending and delivered notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Returns all notifications currently pending delivery.
  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _plugin.pendingNotificationRequests();
}

