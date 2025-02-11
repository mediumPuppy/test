import 'package:flutter/material.dart';
import 'dart:math' as math;

// Model classes to represent our JSON drawing instructions
class DrawingStage {
  final String id;
  final double startTime;
  final double endTime;
  final String description;

  DrawingStage({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.description,
  });
}

class ShapeSpec {
  final String id;
  final List<Offset>? vertices; // For polygon-style shapes
  final String? pathData; // For SVG-style paths
  final String style; // "stroke" or "fill"
  final double strokeWidth;
  final Color color;
  final List<double> fadeInRange;

  ShapeSpec({
    required this.id,
    this.vertices,
    this.pathData,
    required this.style,
    required this.strokeWidth,
    required this.color,
    required this.fadeInRange,
  });
}

class LabelSpec {
  final String text;
  final Offset position;
  final Color color;
  final List<double> fadeInRange;
  final double fontSize;

  LabelSpec({
    required this.text,
    required this.position,
    required this.color,
    required this.fadeInRange,
    this.fontSize = 16,
  });
}

class TriangleSvgScreen extends StatefulWidget {
  const TriangleSvgScreen({super.key});

  @override
  State<TriangleSvgScreen> createState() => _TriangleSvgScreenState();
}

class _TriangleSvgScreenState extends State<TriangleSvgScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<ShapeSpec> shapes;
  late final List<LabelSpec> labels;

  @override
  void initState() {
    super.initState();

    shapes = [
      ShapeSpec(
        id: 'triangle_outline',
        vertices: [
          Offset(100, 200), // Point A (left)
          Offset(100, 100), // Point B (top)
          Offset(200, 200), // Point C (right)
        ],
        style: 'stroke',
        strokeWidth: 2,
        color: Colors.blue,
        fadeInRange: [0, 0.5],
      ),
      ShapeSpec(
        id: 'right_angle_marker',
        pathData:
            'M 110 190 L 110 170 L 130 170', // Small square for right angle
        style: 'stroke',
        strokeWidth: 2,
        color: Colors.red,
        fadeInRange: [0.5, 0.7],
      ),
      ShapeSpec(
        id: 'angle_arc_B',
        pathData: 'M 100 110 A 20 20 0 0 1 115 100', // Arc at B
        style: 'stroke',
        strokeWidth: 2,
        color: Colors.red,
        fadeInRange: [0.7, 0.8],
      ),
      ShapeSpec(
        id: 'angle_arc_C',
        pathData: 'M 190 200 A 20 20 0 0 1 200 185', // Arc at C
        style: 'stroke',
        strokeWidth: 2,
        color: Colors.red,
        fadeInRange: [0.8, 0.9],
      ),
    ];

    labels = [
      LabelSpec(
        text: 'A',
        position: const Offset(85, 205),
        color: Colors.black,
        fadeInRange: [0.9, 1.0],
        fontSize: 16,
      ),
      LabelSpec(
        text: 'B',
        position: const Offset(85, 95),
        color: Colors.black,
        fadeInRange: [0.9, 1.0],
        fontSize: 16,
      ),
      LabelSpec(
        text: 'C',
        position: const Offset(210, 205),
        color: Colors.black,
        fadeInRange: [0.9, 1.0],
        fontSize: 16,
      ),
      LabelSpec(
        text: '90°',
        position: const Offset(115, 180),
        color: Colors.red,
        fadeInRange: [0.5, 0.7],
        fontSize: 14,
      ),
    ];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Animation'),
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: GenericShapePainter(
                  progress: _controller.value,
                  shapes: shapes,
                  labels: labels,
                ),
                size: const Size(300, 300),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.status == AnimationStatus.completed) {
            _controller.reset();
            _controller.forward();
          }
        },
        child: const Icon(Icons.replay),
      ),
    );
  }
}

class GenericShapePainter extends CustomPainter {
  final double progress;
  final List<ShapeSpec> shapes;
  final List<LabelSpec> labels;

  GenericShapePainter({
    required this.progress,
    required this.shapes,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw shapes
    for (final shape in shapes) {
      final opacity = _calculateOpacity(progress, shape.fadeInRange);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = shape.color.withOpacity(opacity)
        ..strokeWidth = shape.strokeWidth
        ..style =
            shape.style == 'stroke' ? PaintingStyle.stroke : PaintingStyle.fill;

      if (shape.vertices != null) {
        _drawPolygon(canvas, shape.vertices!, paint, opacity);
      } else if (shape.pathData != null) {
        _drawPath(canvas, shape.pathData!, paint, opacity);
      }
    }

    // Draw labels
    for (final label in labels) {
      final opacity = _calculateOpacity(progress, label.fadeInRange);
      if (opacity <= 0) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color.withOpacity(opacity),
            fontSize: label.fontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, label.position);
    }
  }

  double _calculateOpacity(double currentTime, List<double> fadeInRange) {
    final start = fadeInRange[0];
    final end = fadeInRange[1];

    if (currentTime < start) return 0;
    if (currentTime > end) return 1;

    return (currentTime - start) / (end - start);
  }

  void _drawPolygon(
      Canvas canvas, List<Offset> vertices, Paint paint, double progress) {
    if (vertices.isEmpty) return;

    final path = Path()..moveTo(vertices[0].dx, vertices[0].dy);

    double totalLength = 0;
    final segments = <double>[];

    // Calculate total length and segment lengths
    for (int i = 0; i < vertices.length; i++) {
      final next = vertices[(i + 1) % vertices.length];
      final current = vertices[i];
      final length = (next - current).distance;
      totalLength += length;
      segments.add(length);
    }

    double drawnLength = 0;
    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];

      if (drawnLength / totalLength > progress) break;

      final segmentProgress =
          ((progress * totalLength) - drawnLength) / segments[i];
      if (segmentProgress <= 0) break;

      if (segmentProgress >= 1) {
        path.lineTo(next.dx, next.dy);
      } else {
        final x = current.dx + (next.dx - current.dx) * segmentProgress;
        final y = current.dy + (next.dy - current.dy) * segmentProgress;
        path.lineTo(x, y);
      }

      drawnLength += segments[i];
    }

    canvas.drawPath(path, paint);
  }

  void _drawPath(Canvas canvas, String pathData, Paint paint, double progress) {
    final path = Path();
    Offset currentPoint = Offset.zero; // Track current point manually

    // Simple SVG path parser for M, L, and A commands
    final commands = pathData.split(' ');
    int i = 0;
    while (i < commands.length) {
      switch (commands[i]) {
        case 'M':
          currentPoint = Offset(
            double.parse(commands[i + 1]),
            double.parse(commands[i + 2]),
          );
          path.moveTo(currentPoint.dx, currentPoint.dy);
          i += 3;
          break;
        case 'L':
          currentPoint = Offset(
            double.parse(commands[i + 1]),
            double.parse(commands[i + 2]),
          );
          path.lineTo(currentPoint.dx, currentPoint.dy);
          i += 3;
          break;
        case 'A':
          // Simple arc implementation (radius x, radius y, rotation, large-arc-flag, sweep-flag, x, y)
          final rx = double.parse(commands[i + 1]);
          final ry = double.parse(commands[i + 2]);
          final rotation = double.parse(commands[i + 3]);
          final largeArc = int.parse(commands[i + 4]);
          final sweep = int.parse(commands[i + 5]);
          final endX = double.parse(commands[i + 6]);
          final endY = double.parse(commands[i + 7]);

          // For simplicity, we're drawing a quadratic curve instead of a proper arc
          path.quadraticBezierTo(
            currentPoint.dx + (endX - currentPoint.dx) / 2,
            currentPoint.dy + (endY - currentPoint.dy) / 2,
            endX,
            endY,
          );
          currentPoint = Offset(endX, endY);
          i += 8;
          break;
        default:
          i++;
      }
    }

    // Draw the path progressively based on progress
    final pathMetrics = path.computeMetrics();
    final progressPath = Path();

    for (final metric in pathMetrics) {
      progressPath.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(progressPath, paint);
  }

  @override
  bool shouldRepaint(GenericShapePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
