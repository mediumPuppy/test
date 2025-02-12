// geometry_drawing_painter.dart
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';
import '../services/geometry_path_parser.dart';
import '../models/drawing_command.dart';

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

    // Draw labels with support for handwriting
    for (final label in specification.labels) {
      if (currentTime < label.fadeInRange[0]) continue;

      if (label.drawingCommands != null && label.drawingCommands!.isNotEmpty) {
        final double start = label.fadeInRange[0];
        final double end = label.fadeInRange[1];
        final double fraction = currentTime < start
            ? 0.0
            : (currentTime > end ? 1.0 : (currentTime - start) / (end - start));
        _drawHandwrittenLabel(
            canvas, label.drawingCommands!, label.color, fraction);
      } else {
        _drawTextLabel(canvas, label.text, label.position, label.color);
      }
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

  void _drawHandwrittenLabel(Canvas canvas, List<DrawingCommand> commands,
      Color color, double fraction) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (final cmd in commands) {
      switch (cmd.type) {
        case 'moveTo':
          path.moveTo(cmd.params['x'], cmd.params['y']);
          break;
        case 'lineTo':
          path.lineTo(cmd.params['x'], cmd.params['y']);
          break;
        case 'quadraticBezierTo':
          path.quadraticBezierTo(
            cmd.params['controlX'],
            cmd.params['controlY'],
            cmd.params['endX'],
            cmd.params['endY'],
          );
          break;
        case 'cubicTo':
          path.cubicTo(
            cmd.params['controlX1'],
            cmd.params['controlY1'],
            cmd.params['controlX2'],
            cmd.params['controlY2'],
            cmd.params['endX'],
            cmd.params['endY'],
          );
          break;
        case 'addOval':
          final rect = Rect.fromCenter(
            center: Offset(cmd.params['centerX'], cmd.params['centerY']),
            width: cmd.params['width'],
            height: cmd.params['height'],
          );
          path.addOval(rect);
          break;
        default:
          break;
      }
    }

    if (fraction >= 1.0) {
      canvas.drawPath(path, paint);
    } else {
      double totalLength = 0.0;
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        totalLength += metric.length;
      }

      final targetLength = totalLength * fraction;
      double currentLength = 0.0;
      final partialPath = Path();

      for (final metric in path.computeMetrics()) {
        if (currentLength + metric.length < targetLength) {
          partialPath.addPath(
              metric.extractPath(0, metric.length), Offset.zero);
          currentLength += metric.length;
        } else {
          final remaining = targetLength - currentLength;
          partialPath.addPath(metric.extractPath(0, remaining), Offset.zero);
          break;
        }
      }

      canvas.drawPath(partialPath, paint);
    }
  }

  void _drawTextLabel(
      Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant GeometryDrawingPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}
