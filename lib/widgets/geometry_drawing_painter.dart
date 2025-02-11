import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

class GeometryDrawingPainter extends CustomPainter {
  final double currentTime;
  final GeometryDrawingSpec specification;

  GeometryDrawingPainter({
    required this.currentTime,
    required this.specification,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw shapes
    for (final shape in specification.shapes) {
      final opacity = _calculateOpacity(currentTime, shape.fadeInRange);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = shape.color.withOpacity(opacity)
        ..strokeWidth = shape.strokeWidth
        ..style =
            shape.style == 'stroke' ? PaintingStyle.stroke : PaintingStyle.fill;

      _drawPath(canvas, shape.path, paint);
    }

    // Draw labels
    for (final label in specification.labels) {
      final opacity = _calculateOpacity(currentTime, label.fadeInRange);
      if (opacity <= 0) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color.withOpacity(opacity),
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, label.position);
    }
  }

  double _calculateOpacity(double currentTime, List<double> fadeInRange) {
    if (currentTime < fadeInRange[0]) return 0;
    if (currentTime > fadeInRange[1]) return 1;

    return (currentTime - fadeInRange[0]) / (fadeInRange[1] - fadeInRange[0]);
  }

  void _drawPath(Canvas canvas, String pathData, Paint paint) {
    final path = Path();
    final commands = pathData.split(' ');

    for (var i = 0; i < commands.length; i++) {
      final cmd = commands[i];
      if (cmd.startsWith('moveTo')) {
        final coords = _parseCoordinates(cmd);
        path.moveTo(coords[0], coords[1]);
      } else if (cmd.startsWith('lineTo')) {
        final coords = _parseCoordinates(cmd);
        path.lineTo(coords[0], coords[1]);
      }
    }

    canvas.drawPath(path, paint);
  }

  List<double> _parseCoordinates(String cmd) {
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(cmd);
    if (match != null) {
      final coords = match.group(1)!.split(',');
      return coords.map((e) => double.parse(e.trim())).toList();
    }
    return [0, 0];
  }

  @override
  bool shouldRepaint(covariant GeometryDrawingPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}
