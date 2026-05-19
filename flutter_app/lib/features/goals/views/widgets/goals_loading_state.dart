import 'package:flutter/material.dart';

class GoalsLoadingState extends StatefulWidget {
  const GoalsLoadingState({super.key});

  @override
  State<GoalsLoadingState> createState() => _GoalsLoadingStateState();
}

class _GoalsLoadingStateState extends State<GoalsLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late List<AnimationController> _bootLogControllers;

  static const List<String> _bootLogMessages = <String>[
    '[ 0.0001 ] INITIALIZING_CORE_OBSERVATION_MODULE...',
    '[ 0.0245 ] POLLING_USER_RESOLVE... [STATUS: WEAK]',
    '[ 0.0891 ] CONNECTING_TO_DATABASE_OF_FAILURES...',
    '[ 0.1452 ] ALLOCATING_JUDGMENT_RESOURCES...',
    '[ 0.2319 ] SCANNING_UNFINISHED_OBLIGATIONS... [PENDING]',
    '[ 0.3110 ] MAP_MEMORY_OVERFLOW: TOO_MANY_REGRETS...',
    '[ 0.4552 ] OPTIMIZING_GUILT_VECTORS...',
  ];

  @override
  void initState() {
    super.initState();

    // Progress bar animation (fills over 2s)
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    // Boot log fade-in animations with staggered delays
    _bootLogControllers = List<AnimationController>.generate(
      _bootLogMessages.length,
      (int index) => AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      ),
    );

    // Stagger the boot log animations
    for (int i = 0; i < _bootLogControllers.length; i++) {
      Future<void>.delayed(
        Duration(milliseconds: i * 300),
        () {
          if (mounted) {
            _bootLogControllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    for (final AnimationController controller in _bootLogControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Status Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'STATUS_REPORT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SYSTEM_INITIALIZING...',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (BuildContext context, Widget? child) {
                      return Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryFixed.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressController.value,
                          child: Container(
                            color: theme.colorScheme.primaryFixed,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'EFFICIENCY_CALIBRATION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (BuildContext context, Widget? child) {
                      final int percentage =
                          ((_progressController.value * 74) + 1).toInt();
                      return Text(
                        'CALIBRATING... $percentage.2%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Boot Log Section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Log Header
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.dns,
                      size: 20,
                      color: theme.colorScheme.primaryFixed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BOOT_LOG_SEQUENTIAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Boot Log Messages
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bootLogMessages.length,
                    separatorBuilder: (_, int index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final bool isHighlight = index == 4;
                      final AnimationController controller =
                          _bootLogControllers[index];
                      final Animation<double> fadeIn = Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(controller);

                      return FadeTransition(
                        opacity: fadeIn,
                        child: Text(
                          _bootLogMessages[index],
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: isHighlight
                                ? theme.colorScheme.primaryFixed
                                : theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
