// geometry_drawing_painter.dart
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';
import '../services/geometry_path_parser.dart';

class GeometryDrawingPainter extends CustomPainter {
  final double currentTime;
  final GeometryDrawingSpec specification;

  GeometryDrawingPainter({
    required this.currentTime,
    required this.specification,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw shapes with progressive stroke
    for (final shape in specification.shapes) {
      final double start = shape.fadeInRange[0];
      final double end = shape.fadeInRange[1];

      // Compute fraction of the path to draw
      double fraction;
      if (currentTime < start) {
        fraction = 0.0;
      } else if (currentTime > end) {
        fraction = 1.0;
      } else {
        fraction = (currentTime - start) / (end - start);
      }

      if (fraction <= 0) continue;

      final paint = Paint()
        ..color = shape.color
        ..strokeWidth = shape.strokeWidth
        ..style =
            shape.style == 'stroke' ? PaintingStyle.stroke : PaintingStyle.fill;

      final fullPath = GeometryPathParser.parse(shape.path);

      if (fraction >= 1) {
        canvas.drawPath(fullPath, paint);
        continue;
      }

      _drawPartialPath(canvas, fullPath, paint, fraction);
    }

    // Draw labels (keeping the instant appear for simplicity)
    for (final label in specification.labels) {
      if (currentTime < label.fadeInRange[0]) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, label.position);
    }
  }

  void _drawPartialPath(
      Canvas canvas, Path fullPath, Paint paint, double fraction) {
    final metrics = fullPath.computeMetrics();
    final totalLength = metrics.fold<double>(
      0.0,
      (sum, metric) => sum + metric.length,
    );

    final targetLength = totalLength * fraction;
    final metrics2 = fullPath.computeMetrics();
    double currentLength = 0.0;
    final partialPath = Path();

    for (final metric in metrics2) {
      final length = metric.length;

      if ((currentLength + length) < targetLength) {
        partialPath.addPath(
          metric.extractPath(0, length),
          Offset.zero,
        );
        currentLength += length;
      } else {
        final remaining = targetLength - currentLength;
        partialPath.addPath(
          metric.extractPath(0, remaining),
          Offset.zero,
        );
        break;
      }
    }

    canvas.drawPath(partialPath, paint);
  }

  @override
  bool shouldRepaint(covariant GeometryDrawingPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}
