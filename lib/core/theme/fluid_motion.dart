import 'package:flutter/material.dart';

/// Central fluid motion curves & tokens inspired by Apple fluid UI and fluid-animations skill.
class FluidMotion {
  FluidMotion._();

  /// Instant press feedback (buttons, cards, chips)
  static const Curve pressCurve = Curves.easeOutCubic;
  static const Duration pressDuration = Duration(milliseconds: 120);

  /// Snappy state transitions (tab switches, toggles)
  static const Curve snappyCurve = Curves.easeOutCubic;
  static const Duration snappyDuration = Duration(milliseconds: 220);

  /// Standard card reveals & staggered lists
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Duration standardDuration = Duration(milliseconds: 320);

  /// Settle & modal transitions
  static const Curve settleCurve = Curves.easeOutCubic;
  static const Duration settleDuration = Duration(milliseconds: 350);

  /// Checks if reduced motion is requested by system accessibility
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}
