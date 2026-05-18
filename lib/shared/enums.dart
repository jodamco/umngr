/// Goal category enum with associated metadata
enum GoalCategory {
  biosMaintenance('Nutrition', 'nutrition'),
  fitnessMaintenance('Wellness', 'fitness'),
  cognitiveLoad('Productivity & Learning', 'code'),
  assetManagement('Finance & Organization', 'money'),
  socialProtocol('Relationships & Community', 'people'),
  systemRecovery('Rest & Mental Health', 'rest_mental')
  ;

  final String label;
  final String iconName;

  const GoalCategory(this.label, this.iconName);

  /// Get label string for database storage
  String get value => switch (this) {
    GoalCategory.biosMaintenance => 'CAT_BIOS_MAINTENANCE.SYS',
    GoalCategory.fitnessMaintenance => 'CAT_FITNESS_MAINTENANCE.SYS',
    GoalCategory.cognitiveLoad => 'CAT_COGNITIVE_LOAD.SYS',
    GoalCategory.assetManagement => 'CAT_ASSET_MANAGEMENT.SYS',
    GoalCategory.socialProtocol => 'CAT_SOCIAL_PROTOCOL.SYS',
    GoalCategory.systemRecovery => 'CAT_SYSTEM_RECOVERY.SYS',
  };

  /// Get label string for database storage
  String get dbValue => switch (this) {
    GoalCategory.biosMaintenance => 'bios_maintenance',
    GoalCategory.fitnessMaintenance => 'fitness_maintenance',
    GoalCategory.cognitiveLoad => 'cognitive_load',
    GoalCategory.assetManagement => 'asset_management',
    GoalCategory.socialProtocol => 'social_protocol',
    GoalCategory.systemRecovery => 'system_recovery',
  };

  /// Parse from database value
  static GoalCategory fromDbValue(String value) {
    return GoalCategory.values.firstWhere(
      (GoalCategory cat) => cat.dbValue == value,
      orElse: () => GoalCategory.biosMaintenance,
    );
  }
}
