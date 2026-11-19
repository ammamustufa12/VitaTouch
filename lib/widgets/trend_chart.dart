import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_card.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.title,
    required this.values,
    required this.color,
    required this.unit,
    this.startLabel,
    this.endLabel,
  });

  final String title;
  final List<double> values;
  final Color color;
  final String unit;
  final String? startLabel;
  final String? endLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            values.isEmpty ? 'No demo readings yet' : unit,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: values.isEmpty
                ? const Center(
                    child: Text(
                      'Complete a demo scan to draw this chart.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : CustomPaint(
                    painter: _TrendPainter(values: values, color: color),
                  ),
          ),
          if (values.length == 1)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'One demo reading so far.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          if (values.length > 1 && startLabel != null && endLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(startLabel!, style: Theme.of(context).textTheme.bodySmall),
                  Text(endLabel!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.01) {
      minValue -= 1;
      maxValue += 1;
    }
    final span = maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height -
          ((values[index] - minValue) / span) * (size.height - 8) -
          4;
      points.add(Offset(x, y));
    }

    final fill = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fill.lineTo(point.dx, point.dy);
    }
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    if (points.length > 1) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final dot = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
