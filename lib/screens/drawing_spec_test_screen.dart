import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';
import 'drawing_and_speech_screen.dart';

class DrawingSpecTestScreen extends StatelessWidget {
  const DrawingSpecTestScreen({Key? key}) : super(key: key);

  DrawingSpecification _createTestSpec() {
    // Create a right triangle with vertices at (100,300), (300,300), and (100,100)
    return DrawingSpecification(
      metadata: Metadata(
        topicTitle: "Right Triangle Properties",
        topicSubtitle: "Understanding the basic elements of a right triangle",
        author: "Math Instructor AI",
        estimatedDurationSeconds: 8,
      ),
      stages: [
        DrawingStage(
          stage: 'triangle_outline',
          startTime: 0,
          endTime: 2,
          description: "Drawing the triangle outline",
          easing: 'easeInOut',
        ),
        DrawingStage(
          stage: 'right_angle_marker',
          startTime: 2,
          endTime: 4,
          description: "Adding the right angle marker",
          easing: 'linear',
        ),
        DrawingStage(
          stage: 'angle_arcs',
          startTime: 4,
          endTime: 6,
          description: "Drawing the angle arcs",
          easing: 'easeIn',
        ),
        DrawingStage(
          stage: 'labels_and_details',
          startTime: 6,
          endTime: 8,
          description: "Adding labels A, B, and C",
          easing: 'easeOut',
        ),
      ],
      drawing: DrawingInstruction(
        triangle: DrawingSpec(
          vertices: [
            Offset(100, 300), // A - right angle
            Offset(300, 300), // B - base
            Offset(100, 100), // C - height
          ],
          strokeWidth: 3,
          color: Colors.blue,
          style: 'stroke',
        ),
        rightAngle: RightAngleMarker(
          vertex: Offset(100, 300),
          markerLength: 20,
          color: Colors.red,
        ),
        angleArcs: [
          AngleArc(
            vertex: Offset(300, 300),
            referencePoint: Offset(100, 300),
            radius: 30,
            progressMapping: 'stageProgress',
            color: Colors.green,
          ),
          AngleArc(
            vertex: Offset(100, 100),
            referencePoint: Offset(100, 300),
            radius: 30,
            progressMapping: 'stageProgress',
            color: Colors.green,
          ),
        ],
        labels: [
          Label(
            text: 'A',
            position: Offset(80, 320),
            color: Colors.black,
          ),
          Label(
            text: 'B',
            position: Offset(310, 320),
            color: Colors.black,
          ),
          Label(
            text: 'C',
            position: Offset(80, 90),
            color: Colors.black,
          ),
        ],
      ),
      speechScript: "Let's explore the properties of a right triangle. "
          "We start by drawing the triangle's outline. "
          "Notice the right angle at point A, marked by a small square. "
          "The other two angles are acute angles, shown by the arcs. "
          "Finally, we label our vertices as A, B, and C.",
      speechPacing: {
        'initialDelay': 0.5,
        'betweenStages': 1.0,
        'finalDelay': 1.0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DrawingAndSpeechScreen(
      specification: _createTestSpec(),
      onAnimationComplete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animation Complete!')),
        );
      },
    );
  }
}
