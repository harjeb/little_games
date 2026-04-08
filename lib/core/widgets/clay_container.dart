import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import 'clay_painter.dart';

class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.shadowStyle = ClayShadowStyle.floating,
    this.depth = 1,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final ClayShadowStyle shadowStyle;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ClayPainter(
          surfaceColor: color,
          borderRadius: borderRadius,
          shadowStyle: shadowStyle,
          depth: depth,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
