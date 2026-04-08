import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';

enum ClayShadowStyle { floating, pressed, inset, flat }

class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.shadowStyle = ClayShadowStyle.floating,
    this.depth = 1,
    this.surfaceGradient,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final ClayShadowStyle shadowStyle;
  final double depth;
  final Gradient? surfaceGradient;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: surfaceGradient ?? _defaultGradient(color),
        boxShadow: _outerShadows(),
      ),
      child: CustomPaint(
        foregroundPainter: _ClayInsetPainter(
          borderRadius: borderRadius,
          shadowStyle: shadowStyle,
          depth: depth,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  Gradient _defaultGradient(Color baseColor) {
    final top = Color.lerp(baseColor, Colors.white, 0.24) ?? baseColor;
    final bottom = Color.lerp(baseColor, AppColors.haze, 0.18) ?? baseColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[top, baseColor, bottom],
      stops: const <double>[0, 0.55, 1],
    );
  }

  List<BoxShadow> _outerShadows() {
    return switch (shadowStyle) {
      ClayShadowStyle.floating => AppShadows.floating(depth: depth),
      ClayShadowStyle.pressed => AppShadows.pressed(depth: depth),
      ClayShadowStyle.inset => const <BoxShadow>[],
      ClayShadowStyle.flat => AppShadows.flat(depth: depth),
    };
  }
}

class _ClayInsetPainter extends CustomPainter {
  const _ClayInsetPainter({
    required this.borderRadius,
    required this.shadowStyle,
    required this.depth,
  });

  final double borderRadius;
  final ClayShadowStyle shadowStyle;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(borderRadius),
    );

    _paintInsetShadow(
      canvas,
      rrect,
      color: AppColors.shadow.withValues(alpha: _darkAlpha),
      offset: _darkOffset,
      blur: _darkBlur,
    );
    _paintInsetShadow(
      canvas,
      rrect,
      color: Colors.white.withValues(alpha: _lightAlpha),
      offset: _lightOffset,
      blur: _lightBlur,
    );

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        <Color>[
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.04),
          AppColors.shadow.withValues(alpha: 0.1),
        ],
        const <double>[0, 0.52, 1],
      );
    canvas.drawRRect(rrect.deflate(0.6), rimPaint);
  }

  double get _darkAlpha => switch (shadowStyle) {
    ClayShadowStyle.floating => 0.22 * depth,
    ClayShadowStyle.pressed => 0.3 * depth,
    ClayShadowStyle.inset => 0.18 * depth,
    ClayShadowStyle.flat => 0.14 * depth,
  };

  double get _lightAlpha => switch (shadowStyle) {
    ClayShadowStyle.floating => 0.48 * depth,
    ClayShadowStyle.pressed => 0.3 * depth,
    ClayShadowStyle.inset => 0.26 * depth,
    ClayShadowStyle.flat => 0.24 * depth,
  };

  Offset get _darkOffset => switch (shadowStyle) {
    ClayShadowStyle.floating => const Offset(8, 8),
    ClayShadowStyle.pressed => const Offset(11, 11),
    ClayShadowStyle.inset => const Offset(6, 6),
    ClayShadowStyle.flat => const Offset(4, 4),
  };

  Offset get _lightOffset => switch (shadowStyle) {
    ClayShadowStyle.floating => const Offset(-7, -7),
    ClayShadowStyle.pressed => const Offset(-4, -4),
    ClayShadowStyle.inset => const Offset(-3, -3),
    ClayShadowStyle.flat => const Offset(-2, -2),
  };

  double get _darkBlur => switch (shadowStyle) {
    ClayShadowStyle.floating => 18,
    ClayShadowStyle.pressed => 20,
    ClayShadowStyle.inset => 12,
    ClayShadowStyle.flat => 8,
  };

  double get _lightBlur => switch (shadowStyle) {
    ClayShadowStyle.floating => 16,
    ClayShadowStyle.pressed => 10,
    ClayShadowStyle.inset => 10,
    ClayShadowStyle.flat => 6,
  };

  void _paintInsetShadow(
    Canvas canvas,
    RRect rrect, {
    required Color color,
    required Offset offset,
    required double blur,
  }) {
    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    final expanded = rrect.shift(offset).inflate(14);
    canvas.drawRRect(expanded, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClayInsetPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shadowStyle != shadowStyle ||
        oldDelegate.depth != depth;
  }
}
