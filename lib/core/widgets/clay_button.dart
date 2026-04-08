import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../extensions/color_extension.dart';
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
      child: AnimatedScale(
        duration: Duration(milliseconds: _pressed ? 120 : 180),
        curve: _pressed ? Curves.easeOutCubic : Curves.elasticOut,
        scale: _pressed ? 0.96 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: isEnabled ? 1 : 0.55,
          child: ClayContainer(
            color: isEnabled
                ? (_pressed
                      ? widget.backgroundColor.darken(5)
                      : widget.backgroundColor)
                : widget.backgroundColor.withValues(alpha: 0.8),
            borderRadius: 999,
            padding: EdgeInsets.zero,
            shadowStyle: _pressed
                ? ClayShadowStyle.pressed
                : ClayShadowStyle.floating,
            depth: _pressed ? 0.92 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
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
