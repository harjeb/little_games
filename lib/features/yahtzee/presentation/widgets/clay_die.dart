import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_shadows.dart';

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
      decoration: BoxDecoration(
        color: held ? AppColors.coral : AppColors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isRolling ? AppShadows.pressed() : AppShadows.floating(),
      ),
      child: Stack(
        children: [
          if (held)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.butter,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.push_pin_rounded,
                  size: 10,
                  color: AppColors.ink,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _PipLayout(value: value, pipColor: pipColor),
          ),
        ],
      ),
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: pipColor,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
      ],
    );
  }
}
