import 'package:flutter/material.dart';

class ScalePop extends StatelessWidget {
  const ScalePop({
    super.key,
    required this.child,
    required this.progress,
    this.maxScale = 1.08,
  });

  final Widget child;
  final double progress;
  final double maxScale;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final scale = Tween<double>(
      begin: 1,
      end: maxScale,
    ).transform(eased.clamp(0.0, 1.0));

    return Transform.scale(scale: scale, child: child);
  }
}
