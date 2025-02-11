import 'package:flutter/material.dart';

// Models for the whiteboard drawing and speech system

class Metadata {
  final String topicTitle;
  final String topicSubtitle;
  final String author;
  final int estimatedDurationSeconds;

  Metadata({
    required this.topicTitle,
    required this.topicSubtitle,
    required this.author,
    required this.estimatedDurationSeconds,
  });
}

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

class FadeInRange {
  final double start;
  final double end;

  FadeInRange({
    required this.start,
    required this.end,
  });
}

class DrawingSpec {
  final List<Offset> vertices;
  final double strokeWidth;
  final Color color;
  final String style; // 'stroke' or 'fill'
  final FadeInRange? fadeInRange;

  DrawingSpec({
    required this.vertices,
    required this.strokeWidth,
    required this.color,
    required this.style,
    this.fadeInRange,
  });
}

class RightAngleMarker {
  final Offset vertex;
  final double markerLength;
  final FadeInRange? fadeInRange;
  final Color color;

  RightAngleMarker({
    required this.vertex,
    required this.markerLength,
    required this.color,
    this.fadeInRange,
  });
}

class AngleArc {
  final Offset vertex;
  final Offset referencePoint;
  final double radius;
  final String progressMapping; // e.g., 'stageProgress'
  final Color color;

  AngleArc({
    required this.vertex,
    required this.referencePoint,
    required this.radius,
    required this.progressMapping,
    required this.color,
  });
}

class Label {
  final String text;
  final Offset position;
  final Color color;
  final FadeInRange? fadeInRange;

  Label({
    required this.text,
    required this.position,
    required this.color,
    this.fadeInRange,
  });
}

class DrawingInstruction {
  final DrawingSpec? triangle;
  final RightAngleMarker? rightAngle;
  final List<AngleArc> angleArcs;
  final List<Label> labels;

  DrawingInstruction({
    this.triangle,
    this.rightAngle,
    required this.angleArcs,
    required this.labels,
  });
}

class DrawingSpecification {
  final Metadata metadata;
  final List<DrawingStage> stages;
  final DrawingInstruction drawing;
  final String speechScript;
  final Map<String, double> speechPacing;

  DrawingSpecification({
    required this.metadata,
    required this.stages,
    required this.drawing,
    required this.speechScript,
    required this.speechPacing,
  });
}

class GeometryShape {
  final String id;
  final List<Offset> vertices;
  final String path;
  final String style;
  final double strokeWidth;
  final Color color;
  final List<double> fadeInRange;

  GeometryShape({
    required this.id,
    required this.vertices,
    required this.path,
    required this.style,
    required this.strokeWidth,
    required this.color,
    required this.fadeInRange,
  });
}

class GeometryLabel {
  final String id;
  final String text;
  final Offset position;
  final Color color;
  final List<double> fadeInRange;

  GeometryLabel({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    required this.fadeInRange,
  });
}

class GeometryDrawingSpec {
  final List<DrawingStage> stages;
  final List<GeometryShape> shapes;
  final List<GeometryLabel> labels;
  final String speechScript;
  final Map<String, double> speechPacing;

  GeometryDrawingSpec({
    required this.stages,
    required this.shapes,
    required this.labels,
    required this.speechScript,
    required this.speechPacing,
  });
}

// More classes for RightAngleMarker, AngleArc, Label, etc.
// ...
