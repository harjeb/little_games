import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'clay_die.dart';

class ClayCube3D extends StatelessWidget {
  const ClayCube3D({
    super.key,
    required this.value,
    required this.held,
    required this.isRolling,
    required this.rotateX,
    required this.rotateY,
    required this.rotateZ,
    required this.size,
  });

  final int value;
  final bool held;
  final bool isRolling;
  final double rotateX;
  final double rotateY;
  final double rotateZ;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedX = math.sin(rotateX) * 0.5 + 0.5;
    final normalizedY = math.sin(rotateY) * 0.5 + 0.5;
    final edgeShift = Offset(
      (normalizedY - 0.5) * size * 0.12,
      (normalizedX - 0.5) * size * 0.12,
    );
    final perspective = Matrix4.identity()
      ..setEntry(3, 2, 0.00125)
      ..rotateX(rotateX)
      ..rotateY(rotateY)
      ..rotateZ(rotateZ);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Transform.translate(
              offset: edgeShift,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.shadow.withValues(alpha: 0.08),
                      AppColors.shadow.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow.withValues(
                      alpha: isRolling ? 0.18 : 0.12,
                    ),
                    blurRadius: isRolling ? 20 : 14,
                    offset: Offset(0, isRolling ? 14 : 10),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Transform(
              alignment: Alignment.center,
              transform: perspective,
              child: ClayDie(
                value: value,
                held: held,
                isRolling: isRolling,
                size: size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
