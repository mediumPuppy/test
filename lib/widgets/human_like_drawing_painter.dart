import 'dart:ui';
import 'dart:math' show atan2, pi;
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

// HumanLikeDrawingPainter: A CustomPainter that progressively draws a triangle
class HumanLikeDrawingPainter extends CustomPainter {
  final double currentTime; // current time in seconds
  final DrawingSpecification specification;

  HumanLikeDrawingPainter({
    required this.currentTime,
    required this.specification,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Find the current stage based on time
    DrawingStage? currentStage;
    double stageProgress = 0.0;

    for (final stage in specification.stages) {
      if (currentTime >= stage.startTime && currentTime <= stage.endTime) {
        currentStage = stage;
        stageProgress =
            (currentTime - stage.startTime) / (stage.endTime - stage.startTime);
        break;
      }
    }

    if (currentStage == null) return;

    switch (currentStage.stage) {
      case 'triangle_outline':
        _drawTriangle(canvas, size, stageProgress);
        break;
      case 'right_angle_marker':
        // Draw complete triangle
        _drawTriangle(canvas, size, 1.0);
        // Draw right angle marker with progress
        _drawRightAngle(canvas, stageProgress);
        break;
      case 'angle_arcs':
        // Draw complete triangle and right angle
        _drawTriangle(canvas, size, 1.0);
        _drawRightAngle(canvas, 1.0);
        // Draw angle arcs with progress
        _drawAngleArcs(canvas, stageProgress);
        break;
      case 'labels_and_details':
        // Draw everything before labels
        _drawTriangle(canvas, size, 1.0);
        _drawRightAngle(canvas, 1.0);
        _drawAngleArcs(canvas, 1.0);
        // Draw labels with progress
        _drawLabels(canvas, stageProgress);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, Size size, double progress) {
    if (specification.drawing.triangle == null) return;

    final triangle = specification.drawing.triangle!;
    final path = Path();

    // Create the triangle path
    path.moveTo(triangle.vertices[0].dx, triangle.vertices[0].dy);
    path.lineTo(triangle.vertices[1].dx, triangle.vertices[1].dy);
    path.lineTo(triangle.vertices[2].dx, triangle.vertices[2].dy);
    path.close();

    // Extract partial path based on progress
    final metrics = path.computeMetrics();
    final partialPath = Path();
    for (final metric in metrics) {
      final length = metric.length;
      partialPath.addPath(
        metric.extractPath(0, length * progress),
        Offset.zero,
      );
    }

    // Draw the path
    final paint = Paint()
      ..color = triangle.color
      ..strokeWidth = triangle.strokeWidth
      ..style = triangle.style == 'stroke'
          ? PaintingStyle.stroke
          : PaintingStyle.fill;

    canvas.drawPath(partialPath, paint);
  }

  void _drawRightAngle(Canvas canvas, double progress) {
    if (specification.drawing.rightAngle == null) return;

    final marker = specification.drawing.rightAngle!;
    final paint = Paint()
      ..color = marker.color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final vertex = marker.vertex;
    final size = marker.markerLength;

    // Draw the right angle marker
    path.moveTo(vertex.dx, vertex.dy + size);
    path.lineTo(vertex.dx, vertex.dy);
    path.lineTo(vertex.dx + size, vertex.dy);

    // Extract partial path based on progress
    final metrics = path.computeMetrics();
    final partialPath = Path();
    for (final metric in metrics) {
      final length = metric.length;
      partialPath.addPath(
        metric.extractPath(0, length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(partialPath, paint);
  }

  void _drawAngleArcs(Canvas canvas, double progress) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final arc in specification.drawing.angleArcs) {
      paint.color = arc.color;

      // Calculate the angle between the points
      final dx1 = arc.referencePoint.dx - arc.vertex.dx;
      final dy1 = arc.referencePoint.dy - arc.vertex.dy;
      final startAngle = atan2(dy1, dx1);

      // Draw the arc
      final rect = Rect.fromCircle(
        center: arc.vertex,
        radius: arc.radius,
      );

      // For simplicity, we're drawing a quarter circle (π/2 radians)
      canvas.drawArc(
        rect,
        startAngle,
        progress * pi / 2,
        false,
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, double progress) {
    final totalLabels = specification.drawing.labels.length;
    if (totalLabels == 0) return;

    // Calculate how much progress to allocate per label
    final progressPerLabel = 1.0 / totalLabels;

    for (int i = 0; i < totalLabels; i++) {
      final label = specification.drawing.labels[i];
      final labelStartProgress = i * progressPerLabel;
      final labelProgress = (progress - labelStartProgress) / progressPerLabel;

      if (labelProgress <= 0) continue;
      if (labelProgress > 1) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(
            color: label.color.withOpacity(labelProgress),
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, label.position);
    }
  }

  @override
  bool shouldRepaint(covariant HumanLikeDrawingPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}
