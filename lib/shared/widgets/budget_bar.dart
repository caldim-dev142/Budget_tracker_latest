import 'package:flutter/material.dart';
import '../../core/utils/money.dart';
import '../../core/theme/app_theme.dart';

/// Horizontal budget progress bar (doc 08 §5).
/// Fill = actual/budget; turns overBudget red past 100%.
/// Displays clear remaining/over budget captions and animated progress pill.
class BudgetBar extends StatelessWidget {
  final Money budget;
  final Money actual;
  final bool showCaption;
  final double height;

  const BudgetBar({
    super.key,
    required this.budget,
    required this.actual,
    this.showCaption = true,
    this.height = 8,
  });

  double get fraction {
    if (budget.isZero) return 0.0;
    return (actual.paise / budget.paise).clamp(0.0, 1.5);
  }

  bool get isOver => actual.paise > budget.paise;
  bool get isNear => !isOver && fraction >= 0.8;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lc = context.layerColors;

    final barColor = isOver
        ? lc.overBudget
        : isNear
            ? Colors.amber.shade700
            : cs.primary;

    final pct = budget.isZero
        ? '—'
        : '${(fraction * 100).toStringAsFixed(0)}%';

    final remainingPaise = budget.paise - actual.paise;
    final remainingText = remainingPaise >= 0
        ? '${MoneyFormatter.formatCompact(Money(remainingPaise))} left'
        : '${MoneyFormatter.formatCompact(Money(remainingPaise.abs()))} over budget';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar with rounded track and animated width fill
        LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = (constraints.maxWidth * fraction.clamp(0.0, 1.0)).clamp(0.0, constraints.maxWidth);

            return Stack(
              children: [
                // Background track
                Container(
                  height: height,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                // Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: height,
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      if (fillWidth > 0)
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (showCaption) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${MoneyFormatter.formatCompact(actual)} of ${MoneyFormatter.formatCompact(budget)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isOver
                      ? lc.overBudget.withValues(alpha: 0.12)
                      : isNear
                          ? Colors.amber.shade700.withValues(alpha: 0.12)
                          : cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOver ? '$pct · $remainingText' : '$pct ($remainingText)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        color: isOver
                            ? lc.overBudget
                            : isNear
                                ? Colors.amber.shade800
                                : cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
