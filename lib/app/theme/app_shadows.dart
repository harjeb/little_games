import 'package:flutter/material.dart';

import 'app_colors.dart';

final class AppShadows {
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
