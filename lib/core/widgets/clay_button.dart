import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'clay_container.dart';

class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.melon,
    this.foregroundColor = AppColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isEnabled ? 1 : 0.55,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          scale: isEnabled && _pressed ? 0.965 : 1,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            offset: isEnabled && _pressed
                ? const Offset(0, 0.015)
                : Offset.zero,
            child: ClayContainer(
              color: widget.backgroundColor,
              borderRadius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shadowStyle: isEnabled && _pressed
                  ? ClayShadowStyle.pressed
                  : ClayShadowStyle.floating,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onPressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon case final icon?) ...[
                        Icon(icon, color: widget.foregroundColor, size: 18),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: widget.foregroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
