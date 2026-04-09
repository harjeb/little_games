import 'dart:math' as math;

import 'package:flutter/animation.dart';

class ClaySpringCurve extends Curve {
  const ClaySpringCurve({this.damping = 7.5, this.oscillations = 2.2});

  final double damping;
  final double oscillations;

  @override
  double transformInternal(double t) {
    if (t <= 0) {
      return 0;
    }
    if (t >= 1) {
      return 1;
    }

    final decay = math.exp(-damping * t);
    final wave = math.cos(2 * math.pi * oscillations * t);
    final value = 1 - (decay * wave);
    return value.clamp(0.0, 1.0);
  }
}
