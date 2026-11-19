import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoadingRing extends StatelessWidget {
  const LoadingRing({super.key, required this.turn});

  final double turn;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LoadingRingPainter(turn),
      child: const Center(
        child: Text(
          'LOADING',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
          ),
        ),
      ),
    );
  }
}

class _LoadingRingPainter extends CustomPainter {
  const _LoadingRingPainter(this.turn);

  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final dots = Paint()..color = const Color(0xFF3E6270).withValues(alpha: 0.45);
    const spots = <(double, double, double)>[
      (-0.72, -0.15, 10),
      (-0.55, 0.42, 7),
      (0.62, -0.38, 14),
      (0.78, 0.22, 8),
      (0.2, 0.7, 6),
      (-0.2, -0.68, 5),
    ];
    for (final spot in spots) {
      canvas.drawCircle(
        center + Offset(spot.$1 * size.width, spot.$2 * size.height),
        spot.$3,
        dots,
      );
    }

    final rings = <(double, double, double, bool)>[
      (0.46, 7, 0.62, false),
      (0.34, 6, 0.55, true),
      (0.22, 5, 0.48, false),
    ];
    for (final ring in rings) {
      final radius = size.shortestSide * ring.$1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.$2
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF1AA3C4),
            Color(0xFF3ED0E0),
            Color(0xFF147E9A),
          ],
          transform: GradientRotation(turn * math.pi * 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      final start = (ring.$4 ? -turn : turn) * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi * ring.$3,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + math.pi,
        math.pi * ring.$3 * 0.72,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingRingPainter oldDelegate) {
    return oldDelegate.turn != turn;
  }
}
