import 'package:flutter/material.dart';
import '../../core/theme/fluid_motion.dart';

/// Reusable tactile press container for cards, buttons, and tiles (fluid-animations skill).
/// Provides immediate physical press feedback on pointer down and smooth spring release on tap.
/// Respects reduced motion accessibility settings via [MediaQuery.disableAnimations].
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration? duration;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
    this.duration,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final reduceMotion = FluidMotion.isReducedMotion(context);

    if (reduceMotion) {
      return InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: effectiveRadius,
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: widget.child,
        ),
      );
    }

    final effectiveDuration = widget.duration ?? FluidMotion.pressDuration;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? widget.scaleFactor : 1.0,
          duration: effectiveDuration,
          curve: FluidMotion.pressCurve,
          child: ClipRRect(
            borderRadius: effectiveRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
