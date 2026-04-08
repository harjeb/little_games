import 'package:flutter/material.dart';

import 'app_colors.dart';

final class AppShadows {
  static List<BoxShadow> floating({
    double blur = 28,
    Offset offset = const Offset(12, 14),
  }) {
    return <BoxShadow>[
      BoxShadow(color: AppColors.shadow, blurRadius: blur, offset: offset),
      const BoxShadow(
        color: AppColors.glow,
        blurRadius: 16,
        offset: Offset(-8, -8),
      ),
    ];
  }

  static List<BoxShadow> pressed({double blur = 16}) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.shadow.withValues(alpha: 0.12),
        blurRadius: blur,
        offset: const Offset(6, 8),
      ),
      const BoxShadow(
        color: AppColors.glow,
        blurRadius: 10,
        offset: Offset(-4, -4),
      ),
    ];
  }
}
