import 'dart:ui' show lerpDouble;

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

class _ClayButtonState extends State<ClayButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _breatheController;
  late final bool _animateIdle;

  @override
  void initState() {
    super.initState();
    _animateIdle = !_isTestBinding();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      value: 0.5,
    );
    if (_animateIdle) {
      _breatheController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final buttonColor = isEnabled
        ? (_pressed ? widget.backgroundColor.darken(5) : widget.backgroundColor)
        : widget.backgroundColor.withValues(alpha: 0.8);
    final breatheScale = isEnabled && !_pressed
        ? lerpDouble(1, 1.018, _breatheController.value)!
        : 1.0;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isEnabled ? 1 : 0.55,
        child: AnimatedScale(
          duration: Duration(milliseconds: _pressed ? 120 : 180),
          curve: _pressed ? Curves.easeOutCubic : Curves.elasticOut,
          scale: (isEnabled && _pressed ? 0.96 : 1) * breatheScale,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            offset: isEnabled && _pressed
                ? const Offset(0, 0.015)
                : Offset.zero,
            child: ClayContainer(
              color: buttonColor,
              borderRadius: 999,
              padding: EdgeInsets.zero,
              shadowStyle: isEnabled && _pressed
                  ? ClayShadowStyle.pressed
                  : ClayShadowStyle.floating,
              depth: isEnabled && _pressed ? 0.92 : 1,
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
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: widget.foregroundColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isTestBinding() {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('TestWidgetsFlutterBinding');
  }
}
