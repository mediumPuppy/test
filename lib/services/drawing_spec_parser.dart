import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

class DrawingSpecParser {
  /// Parses the complete drawing specification from JSON
  static Future<DrawingSpecification> parseDrawingSpec(
      String jsonString) async {
    final jsonMap = json.decode(jsonString);

    return DrawingSpecification(
      metadata: await _parseMetadata(jsonMap),
      stages: await parseStages(jsonMap),
      drawing: await _parseDrawingInstruction(jsonMap),
      speechScript: jsonMap['instructions']['speech']['script'],
      speechPacing:
          _parseSpeechPacing(jsonMap['instructions']['speech']['pacing']),
    );
  }

  /// Parses the metadata section
  static Future<Metadata> _parseMetadata(dynamic jsonMap) async {
    final metadataJson = jsonMap['metadata'];
    return Metadata(
      topicTitle: metadataJson['topicTitle'],
      topicSubtitle: metadataJson['topicSubtitle'],
      author: metadataJson['author'],
      estimatedDurationSeconds: metadataJson['estimatedDurationSeconds'],
    );
  }

  /// Parses the timing stages
  static Future<List<DrawingStage>> parseStages(dynamic jsonMap) async {
    List stagesJson = jsonMap['instructions']['timing'];
    return stagesJson.map<DrawingStage>((item) {
      return DrawingStage(
        stage: item['stage'],
        startTime: (item['startTime'] as num).toDouble(),
        endTime: (item['endTime'] as num).toDouble(),
        description: item['description'],
        easing: item['easing'],
      );
    }).toList();
  }

  /// Parses the complete drawing instruction
  static Future<DrawingInstruction> _parseDrawingInstruction(
      dynamic jsonMap) async {
    final drawingJson = jsonMap['instructions']['drawing'];

    return DrawingInstruction(
      triangle: await _parseTriangleSpec(drawingJson),
      rightAngle: _parseRightAngleMarker(drawingJson),
      angleArcs: _parseAngleArcs(drawingJson),
      labels: _parseLabels(drawingJson),
    );
  }

  /// Parses the triangle specification
  static Future<DrawingSpec?> _parseTriangleSpec(dynamic drawingJson) async {
    if (!drawingJson.containsKey('triangle')) return null;

    final triangleJson = drawingJson['triangle'];
    List verticesJson = triangleJson['vertices'];

    return DrawingSpec(
      vertices: verticesJson
          .map<Offset>((v) => Offset(
                (v['x'] as num).toDouble(),
                (v['y'] as num).toDouble(),
              ))
          .toList(),
      strokeWidth: (triangleJson['strokeWidth'] as num).toDouble(),
      color: _hexToColor(triangleJson['color'] ?? "#000000"),
      style: triangleJson['style'],
      fadeInRange: triangleJson['fadeInRange'] != null
          ? _parseFadeInRange(triangleJson['fadeInRange'])
          : null,
    );
  }

  /// Parses the right angle marker
  static RightAngleMarker? _parseRightAngleMarker(dynamic drawingJson) {
    if (!drawingJson.containsKey('rightAngle')) return null;

    final rightAngleJson = drawingJson['rightAngle'];
    return RightAngleMarker(
      vertex: Offset(
        (rightAngleJson['vertex']['x'] as num).toDouble(),
        (rightAngleJson['vertex']['y'] as num).toDouble(),
      ),
      markerLength: (rightAngleJson['markerLength'] as num).toDouble(),
      color: _hexToColor(rightAngleJson['color']),
      fadeInRange: rightAngleJson['fadeInRange'] != null
          ? _parseFadeInRange(rightAngleJson['fadeInRange'])
          : null,
    );
  }

  /// Parses the angle arcs
  static List<AngleArc> _parseAngleArcs(dynamic drawingJson) {
    if (!drawingJson.containsKey('angleArcs')) return [];

    List arcsJson = drawingJson['angleArcs'];
    return arcsJson.map<AngleArc>((arcJson) {
      return AngleArc(
        vertex: Offset(
          (arcJson['vertex']['x'] as num).toDouble(),
          (arcJson['vertex']['y'] as num).toDouble(),
        ),
        referencePoint: Offset(
          (arcJson['referencePoint']['x'] as num).toDouble(),
          (arcJson['referencePoint']['y'] as num).toDouble(),
        ),
        radius: (arcJson['radius'] as num).toDouble(),
        progressMapping: arcJson['progressMapping'],
        color: _hexToColor(arcJson['color']),
      );
    }).toList();
  }

  /// Parses the labels
  static List<Label> _parseLabels(dynamic drawingJson) {
    if (!drawingJson.containsKey('labels')) return [];

    List labelsJson = drawingJson['labels'];
    return labelsJson.map<Label>((labelJson) {
      return Label(
        text: labelJson['text'],
        position: Offset(
          (labelJson['position']['x'] as num).toDouble(),
          (labelJson['position']['y'] as num).toDouble(),
        ),
        color: _hexToColor(labelJson['color']),
        fadeInRange: labelJson['fadeInRange'] != null
            ? _parseFadeInRange(labelJson['fadeInRange'])
            : null,
      );
    }).toList();
  }

  /// Parses a fade-in range
  static FadeInRange _parseFadeInRange(dynamic rangeJson) {
    return FadeInRange(
      start: (rangeJson['start'] as num).toDouble(),
      end: (rangeJson['end'] as num).toDouble(),
    );
  }

  /// Parses speech pacing configuration
  static Map<String, double> _parseSpeechPacing(dynamic pacingJson) {
    Map<String, double> pacing = {};
    pacingJson.forEach((key, value) {
      pacing[key] = (value as num).toDouble();
    });
    return pacing;
  }

  /// Helper method to convert a hex string to a Flutter Color
  static Color _hexToColor(String hexCode) {
    final buffer = StringBuffer();
    if (hexCode.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexCode.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
