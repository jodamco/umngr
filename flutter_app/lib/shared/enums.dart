import 'dart:math';

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

  /// Returns the 3 notification copy variants for this category.
  /// Titles/bodies may contain the literal `{goalName}` placeholder.
  List<({String title, String body})>
  get notificationVariants => switch (this) {
    GoalCategory.biosMaintenance => <({String title, String body})>[
      (
        title: '{goalName} is not going to fix itself',
        body:
            'Your body keeps submitting maintenance tickets. You keep ignoring them. Outstanding strategy.',
      ),
      (
        title: 'Fuel status: questionable',
        body:
            '{goalName} currently depends on whatever nutritional chaos you call "good enough."',
      ),
      (
        title: 'Biological hardware underperforming',
        body:
            'You wanted energy, focus, and stability. {goalName} would be a decent place to start.',
      ),
    ],
    GoalCategory.fitnessMaintenance => <({String title, String body})>[
      (
        title: 'Muscles detected. Barely.',
        body:
            '{goalName} has remained theoretical for longer than medically inspiring.',
      ),
      (
        title: 'Your skeleton expected support',
        body:
            'Apparently {goalName} was optional. Bold interpretation of "wellness."',
      ),
      (
        title: 'Movement recommended by experts',
        body:
            'Current activity levels suggest your chair is winning the relationship.',
      ),
    ],
    GoalCategory.cognitiveLoad => <({String title, String body})>[
      (
        title: 'Cognitive throughput declining',
        body:
            '{goalName} is still waiting for the version of you that "gets serious tomorrow."',
      ),
      (
        title: 'Your potential filed another complaint',
        body:
            'You keep collecting ambitions like browser tabs. {goalName} included.',
      ),
      (
        title: 'Brain offline. Again.',
        body:
            '{goalName} will not complete itself through passive guilt accumulation.',
      ),
    ],
    GoalCategory.assetManagement => <({String title, String body})>[
      (
        title: 'Operational disorder detected',
        body:
            '{goalName} currently exists in the same category as "I\'ll organize it later."',
      ),
      (
        title: 'Financial stability remains fictional',
        body:
            'Small reminder that ignoring {goalName} is still technically a strategy. Just not a good one.',
      ),
      (
        title: 'Your future self sent feedback',
        body:
            'Apparently they\'re tired of cleaning up after your current decision-making framework.',
      ),
    ],
    GoalCategory.socialProtocol => <({String title, String body})>[
      (
        title: 'Human connection requires maintenance',
        body: '{goalName} cannot survive exclusively inside your intentions.',
      ),
      (
        title: 'Social system latency increasing',
        body:
            'At some point people stop interpreting silence as "busy" and start interpreting it correctly.',
      ),
      (
        title: 'Community features disabled',
        body:
            'You should probably interact with humans before your friendships become archival material.',
      ),
    ],
    GoalCategory.systemRecovery => <({String title, String body})>[
      (
        title: 'System recovery postponed again',
        body:
            '{goalName} would benefit from a brain operating above emergency mode.',
      ),
      (
        title: 'You are not a renewable resource',
        body:
            'Current stress-management protocol appears to be "ignore warning signs."',
      ),
      (
        title: 'Mental stack overflow imminent',
        body: 'Sleep.',
      ),
    ],
  };

  /// Picks a random notification variant and substitutes [goalName].
  ({String title, String body}) pickNotification(String goalName) {
    final ({String title, String body}) variant =
        notificationVariants[Random().nextInt(notificationVariants.length)];
    return (
      title: variant.title.replaceAll('{goalName}', goalName),
      body: variant.body.replaceAll('{goalName}', goalName),
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
