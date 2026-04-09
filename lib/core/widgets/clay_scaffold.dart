import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ClayScaffold extends StatelessWidget {
  const ClayScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _PlayfulBackdrop(),
          SafeArea(child: body),
        ],
      ),
    );
  }
}

class _PlayfulBackdrop extends StatelessWidget {
  const _PlayfulBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sky, AppColors.haze, AppColors.mintCream],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -40,
            right: -20,
            child: _Blob(color: AppColors.butter, width: 180, height: 180),
          ),
          Positioned(
            top: 160,
            left: -40,
            child: _Blob(color: AppColors.melon, width: 150, height: 180),
          ),
          Positioned(
            bottom: -10,
            right: 30,
            child: _Blob(color: AppColors.blueberry, width: 130, height: 160),
          ),
          Positioned.fill(child: CustomPaint(painter: _ClayDustPainter())),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.width, required this.height});

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.28,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ClayDustPainter extends CustomPainter {
  const _ClayDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final softPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.08);
    final warmPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.coral.withValues(alpha: 0.035);

    for (var index = 0; index < 42; index++) {
      final dx = (size.width * ((index * 37) % 100) / 100).clamp(0, size.width);
      final dy = (size.height * ((index * 19 + 17) % 100) / 100).clamp(
        0,
        size.height,
      );
      final radius = 1.2 + (index % 4) * 0.7;
      canvas.drawCircle(
        Offset(dx.toDouble(), dy.toDouble()),
        radius,
        softPaint,
      );
      if (index.isEven) {
        canvas.drawCircle(
          Offset(dx.toDouble() + 10, dy.toDouble() - 6),
          radius * 0.52,
          warmPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
