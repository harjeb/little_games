import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'clay_die.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && widget.rollToken != oldWidget.rollToken) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(_controller.value);
          final shownValue = progress < 0.72 && widget.previousValue != null
              ? widget.previousValue!
              : widget.value;

          return Transform.translate(
            offset: Offset(0, _liftFor(progress)),
            child: Transform.rotate(
              angle: _rotationFor(progress),
              child: Transform.scale(
                scale: _scaleFor(progress),
                child: ClayDie(
                  value: shownValue,
                  held: widget.held,
                  isRolling: widget.isRolling,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _liftFor(double progress) {
    if (progress < 0.35) {
      return -18 * (progress / 0.35);
    }
    if (progress < 0.8) {
      return -18 + (progress - 0.35) * 28 / 0.45;
    }
    return -4 * (1 - progress) / 0.2;
  }

  double _rotationFor(double progress) {
    final twistDirection = widget.twistSeed.isEven ? 1.0 : -1.0;
    final peakRotation = (10 + widget.twistSeed * 2) * math.pi / 180;
    return peakRotation * twistDirection * math.sin(progress * math.pi * 2.2);
  }

  double _scaleFor(double progress) {
    if (progress < 0.2) {
      return 1 + progress * 0.08 / 0.2;
    }
    if (progress > 0.8) {
      return 1.03 - (progress - 0.8) * 0.09 / 0.2;
    }
    return 1.03;
  }
}
