import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

final class StaggeredAnimation {
  const StaggeredAnimation._();

  static Animation<double> curved({
    required Animation<double> parent,
    required int index,
    required int itemCount,
    Curve curve = Curves.easeInOut,
    double span = 0.42,
  }) {
    final clampedSpan = span.clamp(0.05, 1.0);
    if (itemCount <= 1) {
      return CurvedAnimation(parent: parent, curve: curve);
    }

    final start = (index / itemCount) * (1 - clampedSpan);
    final end = (start + clampedSpan).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: curve),
    );
  }
}
