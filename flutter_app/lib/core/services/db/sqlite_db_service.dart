import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:micro_manager/core/services/db/db_abstraction.dart';
import 'package:micro_manager/core/services/db/db_schema.dart';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDbService implements DbAbstraction {
  static final SqliteDbService _instance = SqliteDbService._internal();

  late Database _database;

  SqliteDbService._internal();

  factory SqliteDbService() {
    return _instance;
  }

  /// Get the database instance
  Database get database => _database;

  /// Initialize the SQLite database
  @override
  Future<void> init() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    final String databasePath = await getDatabasesPath();
    String path = join(databasePath, 'micro_manager.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Called when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    await createDatabaseFromSchema(db);
  }

  /// Called when the database version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await createNotificationsTable(db);
    }
  }

  /// Close the database
  @override
  Future<void> close() async {
    await _database.close();
  }

  /// Insert a record into a table
  @override
  Future<int> insert({
    required String table,
    required Map<String, dynamic> values,
  }) async {
    return await _database.insert(table, values);
  }

  /// Batch insert multiple records into a table
  @override
  Future<List<int>> batchInsert({
    required String table,
    required List<Map<String, dynamic>> values,
  }) async {
    final Batch batch = _database.batch();
    for (final Map<String, dynamic> value in values) {
      batch.insert(table, value);
    }
    final List<Object?> results = await batch.commit();
    return results.cast<int>();
  }

  /// Query records from a table
  @override
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return await _database.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// Query a single record from a table
  @override
  Future<Map<String, dynamic>?> querySingle({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final List<Map<String, Object?>> results = await _database.query(
      table,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Update records in a table
  @override
  Future<int> update({
    required String table,
    required Map<String, dynamic> values,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _database.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Delete records from a table
  @override
  Future<int> delete({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _database.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Execute a raw SQL query
  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _database.rawQuery(sql, arguments);
  }

  /// Execute raw SQL without returning results
  @override
  Future<void> rawExecute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    await _database.execute(sql, arguments);
  }

  /// Check if a table exists
  @override
  Future<bool> tableExists(String tableName) async {
    try {
      final List<Map<String, Object?>> result = await _database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        <Object?>[tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
