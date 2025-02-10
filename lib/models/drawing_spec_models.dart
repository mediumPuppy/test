import 'package:flutter/material.dart';

// Models for the whiteboard drawing and speech system

class DrawingStage {
  final String stage;
  final double startTime;
  final double endTime;
  final String description;
  final String? easing; // Optional easing for animation

  DrawingStage({
    required this.stage,
    required this.startTime,
    required this.endTime,
    required this.description,
    this.easing,
  });
}

class DrawingSpec {
  // Keep references to the shapes, arcs, labels, etc.
  // For simplicity, let's define a quick shape structure:
  final List<Offset> vertices;
  final double strokeWidth;
  final Color color;
  final String style; // 'stroke' or 'fill'

  DrawingSpec({
    required this.vertices,
    required this.strokeWidth,
    required this.color,
    required this.style,
  });
}

// More classes for RightAngleMarker, AngleArc, Label, etc.
// ...
