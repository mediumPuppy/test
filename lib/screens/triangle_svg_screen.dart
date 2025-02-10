import 'package:flutter/material.dart';
import '../services/animated_triangle_painter.dart';

class TriangleSvgScreen extends StatefulWidget {
  const TriangleSvgScreen({super.key});

  @override
  State<TriangleSvgScreen> createState() => _TriangleSvgScreenState();
}

class _TriangleSvgScreenState extends State<TriangleSvgScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Offset> vertices;

  @override
  void initState() {
    super.initState();

    // Define side lengths for the triangle
    const double a = 80;
    const double b = 100;
    const double c = 60;

    // Calculate vertices
    final triangle = Triangle(a: a, b: b, c: c);
    vertices = triangle.calculateVertices();

    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
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
        title: const Text('Triangle Animation'),
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: AnimatedTrianglePainter(
                  progress: _controller.value,
                  vertices: vertices,
                ),
                size: const Size(300, 300),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_controller.status == AnimationStatus.completed) {
            _controller.reset();
            _controller.forward();
          }
        },
        child: const Icon(Icons.replay),
      ),
    );
  }
}
