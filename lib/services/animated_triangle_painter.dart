import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class Triangle {
  final double a, b, c;
  Triangle({required this.a, required this.b, required this.c});

  bool get isValid => a + b > c && a + c > b && b + c > a;

  List<Offset> calculateVertices() {
    // Starting point A and B
    final A = Offset.zero;
    final B = Offset(c, 0);

    // Using the cosine law to determine coordinates for C
    double x = (b * b + c * c - a * a) / (2 * c);
    double temp = b * b - x * x;
    double y = temp > 0 ? sqrt(temp) : 0.0;

    final C = Offset(x, y);
    return [A, B, C];
  }
}

class AnimatedTrianglePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final List<Offset> vertices;

  AnimatedTrianglePainter({
    required this.progress,
    required this.vertices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Create the path for the complete triangle
    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    path.lineTo(vertices[1].dx, vertices[1].dy);
    path.lineTo(vertices[2].dx, vertices[2].dy);
    path.close();

    // Calculate the total length of the path
    final PathMetrics pathMetrics = path.computeMetrics();
    final PathMetric pathMetric = pathMetrics.first;
    final double totalLength = pathMetric.length;

    // Extract the portion of the path based on progress
    final extractedPath = pathMetric.extractPath(
      0,
      totalLength * progress,
    );

    // Draw the path
    canvas.drawPath(extractedPath, paint);

    // Draw vertex labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw A, B, C labels
    final labels = ['A', 'B', 'C'];
    final offsets = [
      Offset(-15, -15), // A offset
      Offset(10, -15), // B offset
      Offset(10, 10), // C offset
    ];

    for (int i = 0; i < vertices.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        vertices[i] + offsets[i],
      );
    }
  }

  @override
  bool shouldRepaint(AnimatedTrianglePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
