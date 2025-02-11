// geometry_drawing_test_screen.dart
// Just make sure you've replaced references to the old path logic
// with the new painter that uses GeometryPathParser.
import 'package:flutter/material.dart';
import 'dart:convert';
import '../data/geometry_drawing_spec.dart';
import '../models/drawing_spec_models.dart';
import '../widgets/geometry_drawing_painter.dart';

class GeometryDrawingTestScreen extends StatefulWidget {
  const GeometryDrawingTestScreen({super.key});

  @override
  State<GeometryDrawingTestScreen> createState() =>
      _GeometryDrawingTestScreenState();
}

class _GeometryDrawingTestScreenState extends State<GeometryDrawingTestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double totalDuration;
  late List<DrawingStage> stages;
  late List<GeometryShape> shapes;
  late List<GeometryLabel> labels;
  late Map<String, dynamic> instructionsMap;

  @override
  void initState() {
    super.initState();
    _parseSpecification();

    // totalDuration = lastStage.endTime, etc.
    totalDuration = stages.isEmpty ? 10.0 : stages.last.endTime;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration.toInt()),
    );

    _controller.forward();
  }

  void _parseSpecification() {
    final jsonMap = json.decode(geometryDrawingSpec);
    instructionsMap = jsonMap['instructions'];

    // Parse stages
    final List stagesJson = instructionsMap['timing'];
    stages = stagesJson
        .map((item) => DrawingStage(
              stage: item['stage'],
              startTime: (item['startTime'] as num).toDouble(),
              endTime: (item['endTime'] as num).toDouble(),
              description: item['description'],
              easing: item['easing'],
            ))
        .toList();

    // Parse shapes
    final List shapesJson = instructionsMap['drawing']['shapes'];
    shapes = shapesJson
        .map((item) => GeometryShape(
              id: item['id'],
              vertices: item.containsKey('vertices')
                  ? (item['vertices'] as List)
                      .map((v) => Offset(
                            (v['x'] as num).toDouble(),
                            (v['y'] as num).toDouble(),
                          ))
                      .toList()
                  : [],
              path: item['path'],
              style: item['style'],
              strokeWidth: (item['strokeWidth'] as num).toDouble(),
              color: _hexToColor(item['color']),
              fadeInRange: (item['fadeInRange'] as List)
                  .map<double>((v) => (v as num).toDouble())
                  .toList(),
            ))
        .toList();

    // Parse labels
    final List labelsJson = instructionsMap['drawing']['labels'];
    labels = labelsJson
        .map((item) => GeometryLabel(
              id: item['id'],
              text: item['text'],
              position: Offset(
                (item['position']['x'] as num).toDouble(),
                (item['position']['y'] as num).toDouble(),
              ),
              color: _hexToColor(item['color']),
              fadeInRange: (item['fadeInRange'] as List)
                  .map<double>((v) => (v as num).toDouble())
                  .toList(),
            ))
        .toList();
  }

  Color _hexToColor(String hexColor) {
    // e.g. "#000000" => 0xFF000000
    final buffer = StringBuffer();
    if (hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
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
        title: const Text('Geometry Drawing Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              _controller.reset();
              _controller.forward();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final currentTime = _controller.value * totalDuration;
          return CustomPaint(
            painter: GeometryDrawingPainter(
              currentTime: currentTime,
              specification: GeometryDrawingSpec(
                stages: stages,
                shapes: shapes,
                labels: labels,
                speechScript: instructionsMap['speech']['script'] ?? '',
                speechPacing: Map<String, double>.from(
                  (instructionsMap['speech']['pacing'] ?? {}).map(
                      (key, value) => MapEntry(key, (value as num).toDouble())),
                ),
              ),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
