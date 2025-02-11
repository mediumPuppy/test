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
    final path = Path();
    final vertex = marker.vertex;
    final size = marker.markerLength;
    final offset = size * 0.4;

    // Adjust based on the actual right angle position (point A)
    path.moveTo(vertex.dx, vertex.dy); // Start at vertex
    path.lineTo(vertex.dx + size, vertex.dy); // Go right
    path.lineTo(vertex.dx + size, vertex.dy - size); // Go up

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

    canvas.drawPath(
        partialPath,
        Paint()
          ..color = marker.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
  }

  void _drawAngleArcs(Canvas canvas, double progress) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final arc in specification.drawing.angleArcs) {
      // Calculate start angle from reference point
      final dx1 = arc.referencePoint.dx - arc.vertex.dx;
      final dy1 = arc.referencePoint.dy - arc.vertex.dy;
      final startAngle = atan2(dy1, dx1);

      // Calculate end angle from next vertex
      final dx2 = arc.vertex.dx - arc.referencePoint.dx;
      final dy2 = arc.vertex.dy - arc.referencePoint.dy;
      final endAngle = atan2(dy2, dx2);

      canvas.drawArc(
        Rect.fromCircle(center: arc.vertex, radius: arc.radius),
        startAngle,
        (endAngle - startAngle) * progress,
        false,
        paint..color = arc.color,
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
