import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

class DrawingSpecParser {
  // Parses the timing stages from the JSON map
  static Future<List<DrawingStage>> parseStages(dynamic jsonMap) async {
    List stagesJson = jsonMap['instructions']['timing'];
    return stagesJson.map((item) {
      return DrawingStage(
        stage: item['stage'],
        startTime: (item['startTime'] as num).toDouble(),
        endTime: (item['endTime'] as num).toDouble(),
        description: item['description'],
        easing: item['easing'],
      );
    }).toList();
  }

  // Parses the triangle drawing spec from the JSON map
  static Future<DrawingSpec> parseTriangleSpec(dynamic jsonMap) async {
    final triangleJson = jsonMap['instructions']['drawing']['triangle'];
    List verticesJson = triangleJson['vertices'];
    return DrawingSpec(
      vertices: verticesJson
          .map<Offset>((v) =>
              Offset((v['x'] as num).toDouble(), (v['y'] as num).toDouble()))
          .toList(),
      strokeWidth: (triangleJson['strokeWidth'] as num).toDouble(),
      color: _hexToColor(triangleJson['color'] ?? "#000000"),
      style: triangleJson['style'],
    );
  }

  // Helper method to convert a hex string to a Flutter Color
  static Color _hexToColor(String hexCode) {
    final buffer = StringBuffer();
    if (hexCode.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexCode.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
