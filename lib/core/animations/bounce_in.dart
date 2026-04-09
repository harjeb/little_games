import 'package:flutter/material.dart';

import 'clay_spring.dart';

class BounceIn extends StatelessWidget {
  const BounceIn({
    super.key,
    required this.child,
    required this.animation,
    this.beginScale = 0.92,
    this.beginOffset = const Offset(0, 0.04),
  });

  final Widget child;
  final Animation<double> animation;
  final double beginScale;
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const ClaySpringCurve(),
    );

    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) {
          final value = curved.value.clamp(0.0, 1.0);
          final scale = Tween<double>(
            begin: beginScale,
            end: 1,
          ).transform(value);
          final offset = Offset.lerp(beginOffset, Offset.zero, value)!;
          return Transform.translate(
            offset: Offset(offset.dx * 120, offset.dy * 120),
            child: Transform.scale(scale: scale, child: child),
          );
        },
      ),
    );
  }
}
