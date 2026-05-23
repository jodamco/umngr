import 'package:micro_manager/core/services/db/db_service.dart';
import 'package:micro_manager/features/notifications/models/notification_model.dart';

class NotificationsDAL {
  NotificationsDAL(this._db);

  final DbAbstraction _db;

  static const String _table = 'notifications';

  Future<int> createNotification(NewNotificationModel model) =>
      _db.insert(table: _table, values: model.toMap());

  Future<NotificationModel?> getNotificationById(int id) async {
    final Map<String, dynamic>? map = await _db.querySingle(
      table: _table,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
    return map != null ? NotificationModel.fromMap(map) : null;
  }

  Future<List<NotificationModel>> getNotifications({bool? isCancelled}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      table: _table,
      where: isCancelled != null ? 'is_cancelled = ?' : null,
      whereArgs: isCancelled != null ? <dynamic>[isCancelled ? 1 : 0] : null,
      orderBy: 'scheduled_at ASC',
    );
    return maps.map(NotificationModel.fromMap).toList();
  }

  Future<void> cancelNotification(int id) => _db.delete(
    table: _table,
    where: 'id = ?',
    whereArgs: <dynamic>[id],
  );

  Future<void> cancelAllNotifications() => _db.update(
    table: _table,
    values: <String, dynamic>{'is_cancelled': 1},
  );

  /// Returns all non-cancelled notifications with the given [foreignId].
  /// When [from] is provided, only notifications scheduled after that instant
  /// are returned (useful for counting upcoming notifications).
  Future<List<NotificationModel>> getActiveNotificationsForForeignId(
    int foreignId, {
    DateTime? from,
  }) async {
    final bool hasFrom = from != null;
    final List<Map<String, dynamic>> maps = await _db.query(
      table: _table,
      where: hasFrom
          ? 'foreign_id = ? AND is_cancelled = 0 AND scheduled_at > ?'
          : 'foreign_id = ? AND is_cancelled = 0',
      whereArgs: hasFrom
          ? <dynamic>[foreignId, from.toIso8601String()]
          : <dynamic>[foreignId],
      orderBy: 'scheduled_at ASC',
    );
    return maps.map(NotificationModel.fromMap).toList();
  }
}
