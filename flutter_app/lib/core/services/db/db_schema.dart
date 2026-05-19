import 'package:sqflite/sqflite.dart';

/// Database schema initialization
Future<void> createDatabaseFromSchema(Database db) async {
  // Create goals table
  await db.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      cycle TEXT NOT NULL,
      active_days TEXT,
      data_metric_type TEXT NOT NULL,
      occurrences INTEGER,
      day_of_month INTEGER,
      is_active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // Create goal_checkpoints table
  await db.execute('''
    CREATE TABLE goal_checkpoints (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal_id INTEGER NOT NULL,
      checkpoint_time TEXT NOT NULL,
      position INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
    )
  ''');

  // Create goal_events table
  await db.execute('''
    CREATE TABLE goal_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal_id INTEGER NOT NULL,
      event_datetime DATETIME NOT NULL,
      data_value TEXT,
      was_alerted INTEGER DEFAULT 0,
      started_by_user INTEGER DEFAULT 1,
      is_skipped INTEGER DEFAULT 0,
      is_finished INTEGER DEFAULT 0,
      was_dropped INTEGER DEFAULT 0,
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
    )
  ''');

  // Create index on goal_id for faster queries
  await db.execute('''
    CREATE INDEX idx_goal_events_goal_id ON goal_events(goal_id)
  ''');

  // Create index on event_datetime for faster date-based queries
  await db.execute('''
    CREATE INDEX idx_goal_events_datetime ON goal_events(event_datetime)
  ''');

  // Create index on goal_checkpoints goal_id
  await db.execute('''
    CREATE INDEX idx_goal_checkpoints_goal_id ON goal_checkpoints(goal_id)
  ''');

  // Create index on checkpoint position for ordering
  await db.execute('''
    CREATE INDEX idx_goal_checkpoints_position ON goal_checkpoints(goal_id, position)
  ''');

  // Create goals_details view
  await db.execute('''
    CREATE VIEW goals_details AS
    SELECT 
      g.id,
      g.name,
      g.category,
      g.cycle,
      g.active_days,
      g.data_metric_type,
      g.occurrences,
      g.day_of_month,
      g.is_active,
      g.created_at,
      g.updated_at,
      COALESCE(
        (SELECT COUNT(*) FROM goal_events WHERE goal_id = g.id),
        0
      ) as event_count,
      COALESCE(
        json_group_array(
          json_object(
            'id', gc.id,
            'goal_id', gc.goal_id,
            'checkpoint_time', gc.checkpoint_time,
            'position', gc.position,
            'created_at', gc.created_at
          )
        ),
        json_array()
      ) as checkpoints
    FROM goals g
    LEFT JOIN goal_checkpoints gc ON g.id = gc.goal_id
    GROUP BY g.id
  ''');
}
