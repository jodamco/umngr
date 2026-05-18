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

enum GoalDataMetricType {
  nullSet,
  numericVal,
  boolFlag,
  timeElapsed,
  loadFactor,
  ;

  static GoalDataMetricType fromString(String value) {
    try {
      return GoalDataMetricType.values.byName(value);
    } catch (e) {
      return GoalDataMetricType.nullSet;
    }
  }

  String get inputLabel => switch (this) {
    GoalDataMetricType.nullSet => 'NO_DATA_REQUIRED.SYS',
    GoalDataMetricType.numericVal => 'WHAT_IS_THE_NUMBER.SYS',
    GoalDataMetricType.boolFlag => 'PASS_OR_FAIL.SYS',
    GoalDataMetricType.timeElapsed => 'TIME_SPENT.SYS',
    GoalDataMetricType.loadFactor => 'EFFORT_LEVEL.SYS',
  };

  String get inputPlaceholder => switch (this) {
    GoalDataMetricType.nullSet => 'NO_INPUT_REQUIRED',
    GoalDataMetricType.numericVal => 'ENTER_NUMERIC_VALUE',
    GoalDataMetricType.boolFlag => 'YES_OR_NO',
    GoalDataMetricType.timeElapsed => 'HH:MM:SS_OR_MINUTES',
    GoalDataMetricType.loadFactor => '0_TO_100_PERCENT',
  };

  String get typeLabel => switch (this) {
    GoalDataMetricType.nullSet => 'NONE',
    GoalDataMetricType.numericVal => 'FLOAT_64',
    GoalDataMetricType.boolFlag => 'BOOLEAN',
    GoalDataMetricType.timeElapsed => 'TIMESPAN',
    GoalDataMetricType.loadFactor => 'PERCENTAGE',
  };

  bool get shouldShowInput => this != GoalDataMetricType.nullSet;
}
