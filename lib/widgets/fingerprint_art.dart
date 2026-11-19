import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class FingerprintArt extends StatelessWidget {
  const FingerprintArt({
    super.key,
    required this.progress,
    required this.scanning,
    this.color = AppColors.blue,
  });

  final double progress;
  final bool scanning;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FingerprintPainter(
        progress: progress,
        scanning: scanning,
        color: color,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  _FingerprintPainter({
    required this.progress,
    required this.scanning,
    required this.color,
  });

  final double progress;
  final bool scanning;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * 0.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.018;

    for (var ridge = 1; ridge <= 7; ridge++) {
      final radius = maxRadius * (ridge / 7);
      final fade = scanning
          ? (0.25 + 0.75 * (progress.clamp(0, 1)))
          : 0.45 + 0.35 * (0.5 + 0.5 * math.sin(progress * math.pi * 2));
      paint.color = color.withValues(alpha: (0.18 + ridge * 0.08) * fade);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -2.55,
        scanning ? 2.2 + (progress * 2.4) : 4.4,
        false,
        paint,
      );
    }

    if (scanning) {
      final angle = -math.pi / 2 + progress * math.pi * 2;
      final sweep = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final end = center +
          Offset(math.cos(angle), math.sin(angle)) * maxRadius;
      canvas.drawLine(center, end, sweep);
    }

    canvas.drawCircle(
      center,
      size.shortestSide * 0.035,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scanning != scanning ||
        oldDelegate.color != color;
  }
}
