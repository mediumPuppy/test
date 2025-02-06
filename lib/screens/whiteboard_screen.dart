import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Path> _paths = [];
  final List<double> _pathLengths = [];
  double _totalLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Adjust duration as needed
    );
    
    _initializePaths();
    _controller.forward();
  }

  void _initializePaths() {
    // Create paths for each character/symbol in the equation
    final characters = ['1', 'x', ' ', '+', ' ', 'y', ' ', '=', ' ', '1234', ' ', '-', ' ', '10', ' ', '/', ' ', '22', '^', '3'];
    double x = 50; // Starting x position
    double y = 200; // Vertical position
    
    for (var char in characters) {
      final path = Path();
      switch (char) {
        case '1':
          path.moveTo(x + 5, y - 20);
          path.lineTo(x + 5, y + 20);
          x += 20;
          break;
        case 'x':
          path.moveTo(x, y - 15);
          path.lineTo(x + 15, y + 15);
          path.moveTo(x, y + 15);
          path.lineTo(x + 15, y - 15);
          x += 25;
          break;
        case '+':
          path.moveTo(x + 10, y - 15);
          path.lineTo(x + 10, y + 15);
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          x += 30;
          break;
        case 'y':
          path.moveTo(x, y - 15);
          path.lineTo(x + 7, y);
          path.lineTo(x + 14, y - 15);
          path.moveTo(x + 7, y);
          path.lineTo(x + 7, y + 15);
          x += 24;
          break;
        case '=':
          path.moveTo(x, y - 5);
          path.lineTo(x + 20, y - 5);
          path.moveTo(x, y + 5);
          path.lineTo(x + 20, y + 5);
          x += 30;
          break;
        case '-':
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          x += 30;
          break;
        case '/':
          path.moveTo(x, y - 15);
          path.lineTo(x + 15, y + 15);
          x += 25;
          break;
        case '^':
          path.moveTo(x, y);
          path.lineTo(x + 5, y - 10);
          path.lineTo(x + 10, y);
          x += 15;
          break;
        case ' ':
          x += 10;
          break;
        default:
          // For numbers longer than 1 digit
          if (char.length > 1) {
            for (var digit in char.split('')) {
              final digitPath = Path();
              digitPath.moveTo(x, y - 20);
              digitPath.lineTo(x, y + 20);
              _paths.add(digitPath);
              _pathLengths.add(40);
              _totalLength += 40;
              x += 20;
            }
          } else {
            // Single digit
            path.moveTo(x, y - 20);
            path.lineTo(x, y + 20);
            x += 20;
          }
      }
      
      if (char != ' ') {
        final pathMetrics = path.computeMetrics();
        double pathLength = 0;
        for (final metric in pathMetrics) {
          pathLength += metric.length;
        }
        _paths.add(path);
        _pathLengths.add(pathLength);
        _totalLength += pathLength;
      }
    }
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
        title: const Text('Whiteboard'),
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
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: EquationPainter(
              paths: _paths,
              pathLengths: _pathLengths,
              totalLength: _totalLength,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class EquationPainter extends CustomPainter {
  final List<Path> paths;
  final List<double> pathLengths;
  final double totalLength;
  final double progress;

  EquationPainter({
    required this.paths,
    required this.pathLengths,
    required this.totalLength,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double currentProgress = progress * totalLength;
    
    for (int i = 0; i < paths.length; i++) {
      if (currentProgress <= 0) break;
      
      final path = paths[i];
      final pathLength = pathLengths[i];
      
      final pathProgress = (currentProgress / pathLength).clamp(0.0, 1.0);
      
      if (pathProgress > 0) {
        final metrics = path.computeMetrics();
        for (final metric in metrics) {
          final extractPath = metric.extractPath(
            0,
            metric.length * pathProgress,
          );
          canvas.drawPath(extractPath, paint);
        }
      }
      
      currentProgress -= pathLength;
    }
  }

  @override
  bool shouldRepaint(covariant EquationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
