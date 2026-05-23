import 'package:flutter/material.dart';
import 'package:micro_manager/core/theme/micro_mngr_theme.dart';

void showEfficiencyAuditDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (BuildContext context) => const _EfficiencyAuditDialog(),
  );
}

class _EfficiencyAuditDialog extends StatelessWidget {
  const _EfficiencyAuditDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: MicroMngrTheme.surfaceContainer,
            border: Border.all(
              color: MicroMngrTheme.primaryFixedDim,
              width: 2,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _DialogTitleBar(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _TitleSection(),
                      const SizedBox(height: 24),
                      const _FormulaSection(),
                      const SizedBox(height: 24),
                      const _LogicBullets(),
                      const SizedBox(height: 24),
                      const _CapLimitNotice(),
                      const SizedBox(height: 24),
                      _ActionFooter(
                        onConfirm: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTitleBar extends StatelessWidget {
  const _DialogTitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MicroMngrTheme.primaryFixedDim,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'AUDIT_WINDOW_v4.2',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: MicroMngrTheme.surfaceContainer,
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: MicroMngrTheme.surfaceContainer),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 12,
                height: 12,
                color: MicroMngrTheme.surfaceContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.assignment_late_outlined,
              color: MicroMngrTheme.primaryFixedDim,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'PROTOCOL_AUDIT: EFFICIENCY_LOG',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: MicroMngrTheme.primaryFixedDim,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ID: 0x992_EFF_CALC // STATUS: MANDATORY_REVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: MicroMngrTheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(
          color: MicroMngrTheme.outlineVariant,
          height: 1,
        ),
      ],
    );
  }
}

class _FormulaSection extends StatelessWidget {
  const _FormulaSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'THE_MATHEMATICAL_TRUTH',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: MicroMngrTheme.onSurfaceVariant,
            fontSize: 11,
            letterSpacing: 1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MicroMngrTheme.surfaceContainerHigh,
            border: Border.all(color: MicroMngrTheme.outlineVariant),
          ),
          child: Text(
            '( Σ_ACTUAL / Σ_EXPECTED ) * 100',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: MicroMngrTheme.primaryFixedDim,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Efficiency is not a feeling. It is a ratio of your output against the system\'s objective projection of your utility.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: MicroMngrTheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _LogicBullets extends StatelessWidget {
  const _LogicBullets();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < 420;
        final List<Widget> items = <Widget>[
          const _LogicBulletItem(
            label: 'DAILY_WEIGHT',
            description:
                'Granular task completion. Micro-delays are recorded and penalized.',
          ),
          const _LogicBulletItem(
            label: 'WEEKLY_TREND',
            description:
                'Consistency audit. Variance in productivity triggers system warnings.',
          ),
          const _LogicBulletItem(
            label: 'MONTHLY_QUOTA',
            description:
                'Strategic alignment. Failure here indicates systemic obsolescence.',
          ),
        ];

        if (isNarrow) {
          return Column(
            children:
                items
                    .expand(
                      (Widget w) => <Widget>[w, const SizedBox(height: 12)],
                    )
                    .toList()
                  ..removeLast(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              items
                  .expand(
                    (Widget w) => <Widget>[
                      Expanded(child: w),
                      const SizedBox(width: 12),
                    ],
                  )
                  .toList()
                ..removeLast(),
        );
      },
    );
  }
}

class _LogicBulletItem extends StatelessWidget {
  const _LogicBulletItem({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: MicroMngrTheme.primaryFixedDim, width: 2),
        ),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: MicroMngrTheme.primaryFixedDim,
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MicroMngrTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapLimitNotice extends StatelessWidget {
  const _CapLimitNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MicroMngrTheme.error.withValues(alpha: 0.08),
        border: Border.all(color: MicroMngrTheme.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            color: MicroMngrTheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'CAP_LIMIT_NOTICE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: MicroMngrTheme.error,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perfection is a biological impossibility. The system caps at 99.9% to maintain realism. If you claim to be 100% efficient, you are lying to the system. The system does not appreciate being lied to.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MicroMngrTheme.onSurfaceVariant,
                    fontSize: 13,
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

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: _ConfirmButton(onConfirm: onConfirm),
        ),
        const SizedBox(height: 8),
        Text(
          'BY CLICKING, YOU ACKNOWLEDGE YOUR INHERENT FALLIBILITY.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: MicroMngrTheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  const _ConfirmButton({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onConfirm();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 75),
        transform: _pressed
            ? (Matrix4.identity()..translate(4.0, 4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: MicroMngrTheme.primaryFixedDim,
          boxShadow: _pressed
              ? <BoxShadow>[]
              : const <BoxShadow>[
                  BoxShadow(color: Colors.white, offset: Offset(4, 4)),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        child: Text(
          'CONFIRM_UNDERSTANDING',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: MicroMngrTheme.surfaceContainer,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
