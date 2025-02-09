import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class Triangle {
  final double a, b, c;
  Triangle({required this.a, required this.b, required this.c});

  bool get isValid => a + b > c && a + c > b && b + c > a;

  List<Offset> calculateVertices() {
    // Starting point A and B
    final A = Offset.zero;
    final B = Offset(c, 0);

    // Using the cosine law to determine coordinates for C
    double x = (b * b + c * c - a * a) / (2 * c);
    double temp = b * b - x * x;
    double y = temp > 0 ? sqrt(temp) : 0.0;

    final C = Offset(x, y);
    return [A, B, C];
  }
}

enum AnimationStage {
  drawingTriangle, // 0.0 - 0.25
  drawingRightAngle, // 0.25 - 0.5
  drawingAngleArcs, // 0.5 - 0.75
  drawingLabels // 0.75 - 1.0
}

class AnimatedTrianglePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final List<Offset> vertices;

  AnimatedTrianglePainter({
    required this.progress,
    required this.vertices,
  });

  AnimationStage get currentStage {
    if (progress < 0.25) return AnimationStage.drawingTriangle;
    if (progress < 0.5) return AnimationStage.drawingRightAngle;
    if (progress < 0.75) return AnimationStage.drawingAngleArcs;
    return AnimationStage.drawingLabels;
  }

  double getStageProgress() {
    switch (currentStage) {
      case AnimationStage.drawingTriangle:
        return progress / 0.25;
      case AnimationStage.drawingRightAngle:
        return (progress - 0.25) / 0.25;
      case AnimationStage.drawingAngleArcs:
        return (progress - 0.5) / 0.25;
      case AnimationStage.drawingLabels:
        return (progress - 0.75) / 0.25;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Create the path for the complete triangle
    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    path.lineTo(vertices[1].dx, vertices[1].dy);
    path.lineTo(vertices[2].dx, vertices[2].dy);
    path.close();

    // Calculate the total length of the path
    final PathMetrics pathMetrics = path.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    final double totalLength = pathMetric.length;

    // Always draw the complete triangle after its stage
    if (currentStage == AnimationStage.drawingTriangle) {
      final extractedPath = pathMetric.extractPath(
        0,
        totalLength * getStageProgress(),
      );
      canvas.drawPath(extractedPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw right angle after triangle is complete
    if (currentStage == AnimationStage.drawingRightAngle) {
      _drawRightAngle(
          canvas, vertices[0], vertices[1], vertices[2], getStageProgress());
    } else if (progress >= 0.5) {
      _drawRightAngle(canvas, vertices[0], vertices[1], vertices[2], 1.0);
    }

    // Draw angle arcs
    if (currentStage == AnimationStage.drawingAngleArcs) {
      _drawAngleArc(canvas, vertices[1], vertices[0], vertices[2], 20,
          getStageProgress());
      _drawAngleArc(canvas, vertices[2], vertices[1], vertices[0], 20,
          getStageProgress());
    } else if (progress >= 0.75) {
      _drawAngleArc(canvas, vertices[1], vertices[0], vertices[2], 20, 1.0);
      _drawAngleArc(canvas, vertices[2], vertices[1], vertices[0], 20, 1.0);
    }

    // Draw labels last
    if (currentStage == AnimationStage.drawingLabels) {
      _drawLabels(canvas, getStageProgress());
    }
  }

  void _drawLabels(Canvas canvas, double progress) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Split progress into thirds for A, B, and C
    final labelProgress = progress * 3; // Scale 0-1 to 0-3

    // Draw A
    if (labelProgress > 0) {
      final aProgress = labelProgress > 1 ? 1.0 : labelProgress;
      _drawLetterA(
          canvas, vertices[0] + const Offset(-15, -15), paint, aProgress);
    }

    // Draw B
    if (labelProgress > 1) {
      final bProgress = labelProgress > 2 ? 1.0 : labelProgress - 1;
      _drawLetterB(
          canvas, vertices[1] + const Offset(10, -15), paint, bProgress);
    }

    // Draw C
    if (labelProgress > 2) {
      final cProgress = labelProgress - 2;
      _drawLetterC(
          canvas, vertices[2] + const Offset(10, 10), paint, cProgress);
    }
  }

  void _drawLetterA(
      Canvas canvas, Offset position, Paint paint, double progress) {
    final path = Path();

    // Left line of A
    path.moveTo(position.dx, position.dy + 10);
    path.lineTo(position.dx + 5, position.dy);

    // Right line of A
    path.moveTo(position.dx + 5, position.dy);
    path.lineTo(position.dx + 10, position.dy + 10);

    // Middle line of A
    path.moveTo(position.dx + 2.5, position.dy + 5);
    path.lineTo(position.dx + 7.5, position.dy + 5);

    final PathMetrics pathMetrics = path.computeMetrics();
    final extractedPath = Path();

    double distanceCovered = 0;
    for (final metric in pathMetrics) {
      final double length = metric.length;
      final double targetDistance = progress *
          path.computeMetrics().fold(0.0, (sum, metric) => sum + metric.length);

      if (distanceCovered < targetDistance) {
        final double remainingDistance = targetDistance - distanceCovered;
        final double segmentLength = min(remainingDistance, length);
        extractedPath.addPath(
          metric.extractPath(0, segmentLength),
          Offset.zero,
        );
      }
      distanceCovered += length;
    }

    canvas.drawPath(extractedPath, paint);
  }

  void _drawLetterB(
      Canvas canvas, Offset position, Paint paint, double progress) {
    final path = Path();

    // Vertical line
    path.moveTo(position.dx, position.dy);
    path.lineTo(position.dx, position.dy + 10);

    // Upper loop
    path.moveTo(position.dx, position.dy);
    path.arcTo(
        Rect.fromCenter(
          center: Offset(position.dx + 2.5, position.dy + 2.5),
          width: 5,
          height: 5,
        ),
        -pi / 2,
        pi,
        false);

    // Lower loop
    path.moveTo(position.dx, position.dy + 5);
    path.arcTo(
        Rect.fromCenter(
          center: Offset(position.dx + 2.5, position.dy + 7.5),
          width: 5,
          height: 5,
        ),
        -pi / 2,
        pi,
        false);

    final PathMetrics pathMetrics = path.computeMetrics();
    final extractedPath = Path();

    double distanceCovered = 0;
    for (final metric in pathMetrics) {
      final double length = metric.length;
      final double targetDistance = progress *
          path.computeMetrics().fold(0.0, (sum, metric) => sum + metric.length);

      if (distanceCovered < targetDistance) {
        final double remainingDistance = targetDistance - distanceCovered;
        final double segmentLength = min(remainingDistance, length);
        extractedPath.addPath(
          metric.extractPath(0, segmentLength),
          Offset.zero,
        );
      }
      distanceCovered += length;
    }

    canvas.drawPath(extractedPath, paint);
  }

  void _drawLetterC(
      Canvas canvas, Offset position, Paint paint, double progress) {
    final path = Path();

    path.moveTo(position.dx + 7, position.dy);
    path.arcTo(
        Rect.fromCenter(
          center: Offset(position.dx + 5, position.dy + 5),
          width: 10,
          height: 10,
        ),
        -pi / 4,
        -3 * pi / 2,
        false);

    final PathMetrics pathMetrics = path.computeMetrics();
    final extractedPath = Path();

    double distanceCovered = 0;
    for (final metric in pathMetrics) {
      final double length = metric.length;
      final double targetDistance = progress *
          path.computeMetrics().fold(0.0, (sum, metric) => sum + metric.length);

      if (distanceCovered < targetDistance) {
        final double remainingDistance = targetDistance - distanceCovered;
        final double segmentLength = min(remainingDistance, length);
        extractedPath.addPath(
          metric.extractPath(0, segmentLength),
          Offset.zero,
        );
      }
      distanceCovered += length;
    }

    canvas.drawPath(extractedPath, paint);
  }

  void _drawRightAngle(Canvas canvas, Offset vertex, Offset point1,
      Offset point2, double progress) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Calculate the right angle square size
    final squareSize = 15.0;

    // Calculate unit vectors along both sides of the angle
    final vector1 = point1 - vertex;
    final vector2 = point2 - vertex;
    final unit1 = vector1 / vector1.distance;
    final unit2 = vector2 / vector2.distance;

    // Calculate the two points that form the right angle marker
    final point1OnSquare = vertex + unit1 * squareSize;
    final point2OnSquare = vertex + unit2 * squareSize;

    // Draw the right angle marker progressively
    final path = Path();
    path.moveTo(point1OnSquare.dx, point1OnSquare.dy);

    if (progress > 0.33) {
      path.lineTo(vertex.dx, vertex.dy);
    }

    if (progress > 0.66) {
      path.lineTo(point2OnSquare.dx, point2OnSquare.dy);
    }

    canvas.drawPath(path, paint);

    // Draw "90" with fade in at the end
    if (progress > 0.8) {
      final textOpacity = (progress - 0.8) * 5; // 0.8-1.0 mapped to 0-1
      final textPainter = TextPainter(
        text: TextSpan(
          text: '90°',
          style: TextStyle(
            color: Colors.black.withOpacity(textOpacity),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position the "90" text inside the right angle
      final textOffset = vertex + (unit1 + unit2) * squareSize * 0.4;
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawAngleArc(Canvas canvas, Offset vertex, Offset point1, Offset point2,
      double radius, double progress) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Calculate vectors from vertex to points
    final vector1 = point1 - vertex;
    final vector2 = point2 - vertex;

    // Calculate angles
    final startAngle = atan2(vector1.dy, vector1.dx);
    final endAngle = atan2(vector2.dy, vector2.dx);
    final sweepAngle = endAngle - startAngle;

    // Draw the arc progressively
    final rect = Rect.fromCircle(center: vertex, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(AnimatedTrianglePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
