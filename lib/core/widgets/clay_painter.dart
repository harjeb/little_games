import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../extensions/color_extension.dart';

class ClayPainter extends CustomPainter {
  const ClayPainter({
    required this.surfaceColor,
    required this.borderRadius,
    required this.shadowStyle,
    required this.depth,
    this.surfaceGradient,
  });

  final Color surfaceColor;
  final double borderRadius;
  final ClayShadowStyle shadowStyle;
  final double depth;
  final Gradient? surfaceGradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final spec = AppShadows.specFor(shadowStyle, depth);

    if (spec.outerOpacity > 0) {
      final outerShadowPaint = Paint()
        ..color = AppColors.outerShadow.withValues(alpha: spec.outerOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec.outerBlur);
      canvas.drawRRect(rrect.shift(spec.outerOffset), outerShadowPaint);
    }

    if (spec.glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = AppColors.innerShadowLight.withValues(alpha: spec.glowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec.glowBlur);
      canvas.drawRRect(rrect.shift(spec.glowOffset), glowPaint);
    }

    final surfacePaint = Paint()
      ..shader =
          (surfaceGradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      surfaceColor.lighten(10),
                      surfaceColor,
                      surfaceColor.darken(6),
                    ],
                    stops: const [0, 0.58, 1],
                  ))
              .createShader(rect);
    canvas.drawRRect(rrect, surfacePaint);

    final rimInset = math.min(
      spec.rimWidth,
      math.min(size.width, size.height) / 2,
    );
    final innerRect = rect.deflate(rimInset);
    if (innerRect.width > 0 && innerRect.height > 0) {
      final innerRRect = RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(math.max(borderRadius - rimInset, 0)),
      );

      canvas.save();
      canvas.clipRRect(rrect);

      final lightRimPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.innerShadowLight.withValues(
              alpha: spec.innerLightOpacity,
            ),
            Colors.transparent,
          ],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec.innerBlur);
      canvas.drawDRRect(rrect, innerRRect, lightRimPaint);

      final darkRimPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            AppColors.innerShadowDark.withValues(alpha: spec.innerDarkOpacity),
            Colors.transparent,
          ],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spec.innerBlur);
      canvas.drawDRRect(rrect, innerRRect, darkRimPaint);

      canvas.restore();
    }

    final strokePaint = Paint()
      ..color = surfaceColor.lighten(18).withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect.deflate(0.6), strokePaint);
  }

  @override
  bool shouldRepaint(covariant ClayPainter oldDelegate) {
    return surfaceColor != oldDelegate.surfaceColor ||
        borderRadius != oldDelegate.borderRadius ||
        shadowStyle != oldDelegate.shadowStyle ||
        depth != oldDelegate.depth ||
        surfaceGradient != oldDelegate.surfaceGradient;
  }
}
