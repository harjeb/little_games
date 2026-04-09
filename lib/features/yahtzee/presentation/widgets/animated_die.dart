import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'clay_cube_3d.dart';

class AnimatedDie extends StatefulWidget {
  const AnimatedDie({
    super.key,
    required this.value,
    required this.previousValue,
    required this.held,
    required this.isRolling,
    required this.rollToken,
    required this.twistSeed,
    required this.onTap,
  });

  final int value;
  final int? previousValue;
  final bool held;
  final bool isRolling;
  final int rollToken;
  final int twistSeed;
  final VoidCallback? onTap;

  @override
  State<AnimatedDie> createState() => _AnimatedDieState();
}

class _AnimatedDieState extends State<AnimatedDie>
    with TickerProviderStateMixin {
  late final AnimationController _rollController;
  late final AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    _syncIdleAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && widget.rollToken != oldWidget.rollToken) {
      _rollController
        ..reset()
        ..forward();
    }
    if (widget.held != oldWidget.held ||
        widget.isRolling != oldWidget.isRolling) {
      _syncIdleAnimation();
    }
  }

  @override
  void dispose() {
    _rollController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _rollController,
          _idleController,
        ]),
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(
            _rollController.value,
          );
          final shownValue = _shownValue(progress);
          final idleScale = widget.held && !_rollController.isAnimating
              ? lerpDouble(
                      1,
                      1.015,
                      Curves.easeInOut.transform(_idleController.value),
                    ) ??
                    1
              : 1.0;

          return Transform.translate(
            offset: Offset(0, _liftFor(progress)),
            child: Transform.scale(
              scale: _scaleFor(progress) * idleScale,
              child: ClayCube3D(
                value: shownValue,
                held: widget.held,
                isRolling: widget.isRolling,
                rotateX: _rotationXFor(progress),
                rotateY: _rotationYFor(progress),
                rotateZ: _rotationZFor(progress),
                size: 72,
              ),
            ),
          );
        },
      ),
    );
  }

  void _syncIdleAnimation() {
    if (widget.held && !widget.isRolling) {
      _idleController.repeat(reverse: true);
    } else {
      _idleController
        ..stop()
        ..value = 0;
    }
  }

  int _shownValue(double progress) {
    if (!_rollController.isAnimating) {
      return widget.value;
    }

    final previous = widget.previousValue ?? widget.value;
    if (progress >= 0.82) {
      return widget.value;
    }

    final sequence = <int>[
      previous,
      ((widget.twistSeed + previous) % 6) + 1,
      ((widget.twistSeed * 2 + 3) % 6) + 1,
      ((widget.twistSeed * 3 + 5) % 6) + 1,
      widget.value,
    ];
    final bucket = (progress * (sequence.length - 1)).floor().clamp(
      0,
      sequence.length - 2,
    );
    return sequence[bucket];
  }

  double _liftFor(double progress) {
    if (progress < 0.15) {
      return -6 * Curves.easeIn.transform(progress / 0.15);
    }
    if (progress < 0.75) {
      final normalized = (progress - 0.15) / 0.6;
      return -6 - math.sin(normalized * math.pi) * 28;
    }
    if (progress < 0.92) {
      final normalized = (progress - 0.75) / 0.17;
      return lerpDouble(-10, 4, Curves.easeOutBack.transform(normalized)) ?? 0;
    }
    final normalized = (progress - 0.92) / 0.08;
    return lerpDouble(4, 0, Curves.easeOut.transform(normalized)) ?? 0;
  }

  double _rotationXFor(double progress) {
    final turns = 1.7 + (widget.twistSeed % 3) * 0.45;
    final tumble = turns * math.pi * 2;
    if (progress < 0.14) {
      return 0;
    }
    if (progress < 0.76) {
      final normalized = (progress - 0.14) / 0.62;
      return tumble * normalized;
    }
    final normalized = ((progress - 0.76) / 0.24).clamp(0, 1).toDouble();
    final remaining = 1 - Curves.easeOutBack.transform(normalized);
    return tumble * remaining;
  }

  double _rotationYFor(double progress) {
    final direction = widget.twistSeed.isEven ? 1.0 : -1.0;
    final peak = (0.55 + (widget.twistSeed % 5) * 0.08) * direction;
    if (progress < 0.16) {
      return 0;
    }
    if (progress < 0.74) {
      final normalized = (progress - 0.16) / 0.58;
      return math.sin(normalized * math.pi) * peak;
    }
    final normalized = ((progress - 0.74) / 0.26).clamp(0, 1).toDouble();
    return (1 - Curves.easeOut.transform(normalized)) * peak * 0.35;
  }

  double _rotationZFor(double progress) {
    final base = (widget.twistSeed % 2 == 0 ? 1 : -1) * 0.28;
    if (progress < 0.75) {
      return math.sin(progress * math.pi * 3.4) * base;
    }
    final normalized = ((progress - 0.75) / 0.25).clamp(0, 1).toDouble();
    return (1 - Curves.elasticOut.transform(normalized)) * base * 0.5;
  }

  double _scaleFor(double progress) {
    if (progress < 0.14) {
      return lerpDouble(1, 0.93, Curves.easeIn.transform(progress / 0.14)) ?? 1;
    }
    if (progress < 0.74) {
      final normalized = (progress - 0.14) / 0.6;
      return lerpDouble(0.97, 1.03, math.sin(normalized * math.pi)) ?? 1;
    }
    if (progress < 0.9) {
      final normalized = (progress - 0.74) / 0.16;
      return lerpDouble(1.03, 1.08, Curves.easeOut.transform(normalized)) ?? 1;
    }
    final normalized = ((progress - 0.9) / 0.1).clamp(0, 1).toDouble();
    return lerpDouble(1.04, 1, Curves.easeOut.transform(normalized)) ?? 1;
  }
}
