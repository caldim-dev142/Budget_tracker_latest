import 'package:flutter/material.dart';
import 'pressable_scale.dart';

/// Custom numeric keypad for amount entry (doc 08 §5, doc 09 S5).
/// Large tap targets (≥ 48dp) with tactile press feedback and clear key layout.
class AmountKeypad extends StatelessWidget {
  final String currentValue;
  final ValueChanged<String> onValueChanged;

  const AmountKeypad({
    super.key,
    required this.currentValue,
    required this.onValueChanged,
  });

  void _handleKey(String key) {
    String next = currentValue;

    switch (key) {
      case 'DEL':
        if (next.isNotEmpty) next = next.substring(0, next.length - 1);
        if (next.isEmpty) next = '';
      case '.':
        if (!next.contains('.')) next = '$next.';
      case '00':
        if (next.isNotEmpty && next != '0') next = '${next}00';
      default:
        // Prevent multiple leading zeros
        if (next == '0' && key != '.') {
          next = key;
        } else {
          // Max 2 decimal places
          if (next.contains('.')) {
            final decimals = next.split('.')[1].length;
            if (decimals >= 2) return;
          }
          next = '$next$key';
        }
    }

    onValueChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', 'DEL'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((row) {
        return Row(
          children: row.map((key) {
            return Expanded(
              child: _KeypadButton(
                label: key,
                onTap: () => _handleKey(key),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDelete = label == 'DEL';
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: PressableScale(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 60, // ≥ 48dp tap target (doc 08 §8)
          decoration: BoxDecoration(
            color: isDelete
                ? cs.errorContainer.withValues(alpha: 0.25)
                : cs.surfaceContainerHigh.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_outlined, color: cs.error, size: 22)
                : Text(
                    label,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
