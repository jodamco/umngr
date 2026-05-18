/// Abstract database service that defines the contract for database operations.
/// This abstraction allows for different database implementations (SQLite, Firebase, etc.)
/// to be plugged in without changing the rest of the application code.
abstract class DbAbstraction {
  /// Initialize the database
  Future<void> init();

  /// Close the database connection
  Future<void> close();

  /// Insert a record into a table
  /// Returns the ID of the inserted record
  Future<int> insert({
    required String table,
    required Map<String, dynamic> values,
  });

  /// Batch insert multiple records into a table
  /// Returns the list of inserted record IDs
  Future<List<int>> batchInsert({
    required String table,
    required List<Map<String, dynamic>> values,
  });

  /// Query records from a table
  Future<List<Map<String, dynamic>>> query({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// Query a single record from a table
  Future<Map<String, dynamic>?> querySingle({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Update records in a table
  /// Returns the number of records updated
  Future<int> update({
    required String table,
    required Map<String, dynamic> values,
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Delete records from a table
  /// Returns the number of records deleted
  Future<int> delete({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Execute a raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]);

  /// Execute raw SQL without returning results
  Future<void> rawExecute(String sql, [List<dynamic>? arguments]);

  /// Check if a table exists
  Future<bool> tableExists(String tableName);
}
