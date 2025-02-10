import 'dart:ui';
import 'package:flutter/material.dart';

// HumanLikeDrawingPainter: A CustomPainter that progressively draws a triangle
class HumanLikeDrawingPainter extends CustomPainter {
  final double currentTime; // current time in seconds

  HumanLikeDrawingPainter({required this.currentTime});

  @override
  void paint(Canvas canvas, Size size) {
    _drawTriangle(canvas, size);
    // Additional drawing methods can be added here
  }

  void _drawTriangle(Canvas canvas, Size size) {
    // Calculate the fraction of progress for the triangle drawing stage (from 0 to 2 seconds)
    double start = 0.0;
    double end = 2.0;
    double fraction = 0.0;
    if (currentTime <= start) {
      fraction = 0.0;
    } else if (currentTime >= end) {
      fraction = 1.0;
    } else {
      fraction = (currentTime - start) / (end - start);
    }

    // Build a path for the triangle
    Path trianglePath = Path();
    trianglePath.moveTo(0, 0);
    trianglePath.lineTo(60, 0);
    trianglePath.lineTo(30, 40);
    trianglePath.close();

    // Extract a partial path based on the current fraction
    PathMetrics metrics = trianglePath.computeMetrics();
    Path partialPath = Path();
    for (PathMetric metric in metrics) {
      double lengthToReveal = metric.length * fraction;
      partialPath.addPath(metric.extractPath(0, lengthToReveal), Offset.zero);
    }

    // Draw the partial path
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(partialPath, paint);
  }

  @override
  bool shouldRepaint(covariant HumanLikeDrawingPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}
