import 'package:flutter/material.dart';

import 'app_colors.dart';

enum ClayShadowStyle { floating, pressed, inset, flat }

class ClayShadowSpec {
  const ClayShadowSpec({
    required this.outerBlur,
    required this.outerOffset,
    required this.outerOpacity,
    required this.glowBlur,
    required this.glowOffset,
    required this.glowOpacity,
    required this.rimWidth,
    required this.innerBlur,
    required this.innerLightOpacity,
    required this.innerDarkOpacity,
  });

  final double outerBlur;
  final Offset outerOffset;
  final double outerOpacity;
  final double glowBlur;
  final Offset glowOffset;
  final double glowOpacity;
  final double rimWidth;
  final double innerBlur;
  final double innerLightOpacity;
  final double innerDarkOpacity;
}

final class AppShadows {
  static ClayShadowSpec specFor(ClayShadowStyle style, double depth) {
    final normalizedDepth = depth.clamp(0.4, 1.4).toDouble();

    return switch (style) {
      ClayShadowStyle.floating => ClayShadowSpec(
        outerBlur: 24 * normalizedDepth,
        outerOffset: Offset(10 * normalizedDepth, 12 * normalizedDepth),
        outerOpacity: 0.28,
        glowBlur: 14 * normalizedDepth,
        glowOffset: Offset(-7 * normalizedDepth, -7 * normalizedDepth),
        glowOpacity: 0.55,
        rimWidth: 10 * normalizedDepth,
        innerBlur: 8 * normalizedDepth,
        innerLightOpacity: 0.28,
        innerDarkOpacity: 0.24,
      ),
      ClayShadowStyle.pressed => ClayShadowSpec(
        outerBlur: 14 * normalizedDepth,
        outerOffset: Offset(5 * normalizedDepth, 7 * normalizedDepth),
        outerOpacity: 0.18,
        glowBlur: 8 * normalizedDepth,
        glowOffset: Offset(-3 * normalizedDepth, -3 * normalizedDepth),
        glowOpacity: 0.32,
        rimWidth: 12 * normalizedDepth,
        innerBlur: 10 * normalizedDepth,
        innerLightOpacity: 0.16,
        innerDarkOpacity: 0.34,
      ),
      ClayShadowStyle.inset => ClayShadowSpec(
        outerBlur: 0,
        outerOffset: Offset.zero,
        outerOpacity: 0,
        glowBlur: 0,
        glowOffset: Offset.zero,
        glowOpacity: 0,
        rimWidth: 10 * normalizedDepth,
        innerBlur: 7 * normalizedDepth,
        innerLightOpacity: 0.18,
        innerDarkOpacity: 0.26,
      ),
      ClayShadowStyle.flat => ClayShadowSpec(
        outerBlur: 8 * normalizedDepth,
        outerOffset: Offset(2 * normalizedDepth, 4 * normalizedDepth),
        outerOpacity: 0.14,
        glowBlur: 6 * normalizedDepth,
        glowOffset: Offset(-2 * normalizedDepth, -2 * normalizedDepth),
        glowOpacity: 0.24,
        rimWidth: 6 * normalizedDepth,
        innerBlur: 5 * normalizedDepth,
        innerLightOpacity: 0.12,
        innerDarkOpacity: 0.16,
      ),
    };
  }

  static List<BoxShadow> floating({
    double blur = 28,
    Offset offset = const Offset(12, 14),
    double depth = 1,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.18 * depth),
        blurRadius: blur,
        offset: offset,
      ),
      BoxShadow(
        color: AppColors.glow.withValues(alpha: 0.78 * depth),
        blurRadius: 16,
        offset: const Offset(-8, -8),
      ),
    ];
  }

  static List<BoxShadow> pressed({double blur = 16, double depth = 1}) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.12 * depth),
        blurRadius: blur,
        offset: const Offset(6, 8),
      ),
      BoxShadow(
        color: AppColors.glow.withValues(alpha: 0.52 * depth),
        blurRadius: 10,
        offset: const Offset(-4, -4),
      ),
    ];
  }

  static List<BoxShadow> flat({double depth = 1}) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.1 * depth),
        blurRadius: 10,
        offset: const Offset(4, 6),
      ),
      BoxShadow(
        color: AppColors.glow.withValues(alpha: 0.42 * depth),
        blurRadius: 6,
        offset: const Offset(-3, -3),
      ),
    ];
  }
}
