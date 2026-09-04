import 'package:flutter/material.dart';
import '../../core/utils/money.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/fluid_motion.dart';
import '../../domain/entities/entry.dart';

/// The canonical money display widget (doc 08 §5, doc 09 "MoneyText").
/// Formats INR with Indian digit grouping: ₹1,55,419.
/// Colour is determined by EntryKind, never raw sign (doc 01 §6, doc 02 §5 edge 4).
/// Includes smooth implicit count animation when money value changes, respecting reduced motion settings.
class MoneyText extends StatelessWidget {
  final Money money;
  final EntryKind? kind;
  final bool signed;
  final bool compact;
  final TextStyle? style;
  final bool animate;

  const MoneyText(
    this.money, {
    super.key,
    this.kind,
    this.signed = false,
    this.compact = true,
    this.style,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForKind(context, kind);
    final baseStyle = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();

    final textStyle = baseStyle.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final reduceMotion = FluidMotion.isReducedMotion(context);

    if (!animate || reduceMotion) {
      final text = _format(money);
      return Text(text, style: textStyle);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: money.paise.toDouble()),
      duration: FluidMotion.settleDuration,
      curve: FluidMotion.settleCurve,
      builder: (context, currentPaise, child) {
        final animatedMoney = Money(currentPaise.round());
        final text = _format(animatedMoney);
        return Text(
          text,
          style: textStyle,
        );
      },
    );
  }

  String _format(Money m) {
    return signed
        ? MoneyFormatter.formatSigned(m)
        : compact
            ? MoneyFormatter.formatCompact(m)
            : MoneyFormatter.format(m);
  }

  Color? _colorForKind(BuildContext context, EntryKind? kind) {
    if (kind == null) return null;
    final lc = context.layerColors;
    return switch (kind) {
      EntryKind.income || EntryKind.incomeDeduction => lc.income,
      EntryKind.spending => lc.spending,
      EntryKind.protection => lc.protection,
      EntryKind.saving => lc.saving,
      EntryKind.adjustment => null,
    };
  }
}
