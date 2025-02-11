import 'package:flutter/material.dart';
import '../data/geometry_drawing_spec.dart';
import '../models/drawing_spec_models.dart';
import '../widgets/geometry_drawing_painter.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _parseSpecification();

    // Calculate total duration from the last stage's endTime
    totalDuration = stages.isEmpty ? 10.0 : stages.last.endTime;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration.toInt()),
    );

    _controller.forward();
  }

  void _parseSpecification() {
    final jsonMap = json.decode(geometryDrawingSpec);
    final instructionsMap = jsonMap['instructions'];

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
              vertices: (item['vertices'] as List)
                  .map((v) => Offset(
                      (v['x'] as num).toDouble(), (v['y'] as num).toDouble()))
                  .toList(),
              path: item['path'],
              style: item['style'],
              strokeWidth: (item['strokeWidth'] as num).toDouble(),
              color: Color(int.parse(item['color'].substring(1, 7), radix: 16) +
                  0xFF000000),
              fadeInRange: (item['fadeInRange'] as List)
                  .map((v) => (v as num).toDouble())
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
              color: Color(int.parse(item['color'].substring(1, 7), radix: 16) +
                  0xFF000000),
              fadeInRange: (item['fadeInRange'] as List)
                  .map((v) => (v as num).toDouble())
                  .toList(),
            ))
        .toList();
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
          return CustomPaint(
            painter: GeometryDrawingPainter(
              currentTime: _controller.value * totalDuration,
              specification: GeometryDrawingSpec(
                stages: stages,
                shapes: shapes,
                labels: labels,
                speechScript: "Let's explore geometry",
                speechPacing: const {'initialDelay': 1.0},
              ),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
