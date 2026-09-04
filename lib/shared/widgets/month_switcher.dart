import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/providers/dashboard_providers.dart';
import 'pressable_scale.dart';

/// Sticky month switcher widget: ‹ Nov 2023 ›
/// Closed months show a read-only badge. (doc 08 §5, doc 09)
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final isClosed = ref.watch(isCurrentMonthClosedProvider).valueOrNull ?? false;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous month
          PressableScale(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ref
                .read(selectedMonthProvider.notifier)
                .select(selectedMonth.previous),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Month label + optional read-only badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Padding(
              key: ValueKey(selectedMonth),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedMonth.toDisplayString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                  if (isClosed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Closed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Next month
          PressableScale(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ref
                .read(selectedMonthProvider.notifier)
                .select(selectedMonth.next),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
