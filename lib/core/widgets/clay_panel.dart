import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'clay_container.dart';

class ClayPanel extends StatelessWidget {
  const ClayPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = AppColors.white,
    this.borderRadius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      shadowStyle: ClayShadowStyle.floating,
      child: child,
    );
  }
}
