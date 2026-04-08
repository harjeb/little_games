import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/clay_container.dart';

class ClayDie extends StatelessWidget {
  const ClayDie({
    super.key,
    required this.value,
    required this.held,
    this.isRolling = false,
    this.size = 72,
  });

  final int value;
  final bool held;
  final bool isRolling;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pipColor = held ? AppColors.white : AppColors.ink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      child: ClayContainer(
        color: held ? AppColors.coral : AppColors.white.withValues(alpha: 0.98),
        borderRadius: 22,
        padding: const EdgeInsets.all(12),
        depth: held ? 1.12 : 1,
        shadowStyle: held || isRolling
            ? ClayShadowStyle.pressed
            : ClayShadowStyle.floating,
        child: Stack(
          children: [
            if (held)
              Positioned(
                top: 0,
                right: 0,
                child: ClayContainer(
                  color: AppColors.butter,
                  borderRadius: 999,
                  padding: const EdgeInsets.all(4),
                  shadowStyle: ClayShadowStyle.flat,
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 10,
                    color: AppColors.ink,
                  ),
                ),
              ),
            _PipLayout(value: value, pipColor: pipColor),
          ],
        ),
      ),
    );
  }
}

class _PipDot extends StatelessWidget {
  const _PipDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.05,
          colors: <Color>[
            Color.lerp(color, Colors.white, 0.22) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.15) ?? color,
          ],
          stops: const <double>[0, 0.55, 1],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.22),
            blurRadius: 2,
            offset: const Offset(-1.2, -1.2),
          ),
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.18),
            blurRadius: 3,
            offset: const Offset(1.4, 1.4),
          ),
        ],
      ),
      child: const SizedBox(width: 10, height: 10),
    );
  }
}

class _PipLayout extends StatelessWidget {
  const _PipLayout({required this.value, required this.pipColor});

  final int value;
  final Color pipColor;

  @override
  Widget build(BuildContext context) {
    final positions = switch (value) {
      1 => const [Alignment.center],
      2 => const [Alignment.topLeft, Alignment.bottomRight],
      3 => const [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
      4 => const [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ],
      5 => const [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.center,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ],
      _ => const [
        Alignment.topLeft,
        Alignment.centerLeft,
        Alignment.bottomLeft,
        Alignment.topRight,
        Alignment.centerRight,
        Alignment.bottomRight,
      ],
    };

    return Stack(
      children: [
        for (final alignment in positions)
          Align(
            alignment: alignment,
            child: _PipDot(color: pipColor),
          ),
      ],
    );
  }
}
