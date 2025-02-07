import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

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
    final characters = [
      '1', ' ', '2', ' ', '3', ' ', '4', ' ', '5', ' ', '6', ' ', '7', ' ', '8', ' ', '9',
      '\n',
      '123456789',
      '\n',
      '+', ' ', '-', ' ', '×', ' ', '÷', ' ', '=', ' ', '^', ' ', '(', ' ', ')', ' ', '√'
    ];
    double x = 50; // Starting x position
    double y = 200; // Vertical position
    
    for (var char in characters) {
      final path = Path();
      switch (char) {
        case '1':
          path.moveTo(x + 2, y - 13);   // Start from top-left, slightly lower
          path.lineTo(x + 10, y - 15);  // Angle up to top of stem
          path.lineTo(x + 10, y + 15);  // Vertical line straight down
          path.lineTo(x, y + 15);       // Base left
          path.lineTo(x + 20, y + 15);  // Base right
          x += 25;
          break;
        case '2':
          path.moveTo(x + 3, y - 15);     // Start more left
          path.quadraticBezierTo(x + 20, y - 15, x + 15, y);  // Top curve (peaks left)
          path.quadraticBezierTo(x + 12, y + 10, x, y + 15);  // Bottom curve (more open in middle)
          path.lineTo(x + 17, y + 15);    // Bottom line (aligned with "1")
          x += 25;
          break;
        case '3':
          path.moveTo(x + 2, y - 15);     // Start top left
          path.quadraticBezierTo(x + 18, y - 15, x + 16, y - 8);  // Top bowl curves right
          path.quadraticBezierTo(x + 14, y - 2, x + 8, y);      // Connect to middle point, much more left
          path.quadraticBezierTo(x + 14, y + 2, x + 16, y + 8);  // Start of bottom bowl
          path.quadraticBezierTo(x + 18, y + 15, x + 2, y + 15); // Bottom bowl curves back left
          x += 25;
          break;
        case '4':
          path.moveTo(x + 15, y + 15);  // Bottom of vertical
          path.lineTo(x + 15, y - 15);  // Up vertical
          path.lineTo(x + 3, y + 5);    // Diagonal to left (moved in from x)
          path.lineTo(x + 20, y + 5);   // Horizontal line
          x += 25;
          break;
        case '5':
          path.moveTo(x + 16, y - 15);  // Top right (back to original)
          path.lineTo(x, y - 15);       // Top left (back to original)
          path.lineTo(x, y - 5);        // Down vertical (shorter)
          path.quadraticBezierTo(x + 15, y, x + 15, y + 5);  // Bottom curve start
          path.quadraticBezierTo(x + 15, y + 15, x, y + 15);  // Bottom curve end
          x += 25;
          break;
        case '6':
          // Calculate relative dimensions for the 6
          final width = 20.0;  // Base width for the number
          final height = 30.0; // Base height for the number
          
          // Top curve of 6 - extends further and curves down more
          path.moveTo(x + width / 1.2, y - height/2);  // Start further right
          path.cubicTo(
            x + width / 2 + 12, y - height/2 - 5,  // First control point, higher
            x + width / 5, y - height/4,           // Second control point, more left
            x + width / 6, y + height/6       // End point, much higher to cut off more bottom
          );
          
          // Bottom circle of 6
          path.addArc(
            Rect.fromCenter(
              center: Offset(x + width/2 + 2, y + height/6),
              width: width/1.2,
              height: width/1.2
            ),
            math.pi,
            2 * math.pi
          );
          
          x += width + 5;
          break;
        case '7':
          path.moveTo(x, y - 15);     // Start top left
          path.lineTo(x + 20, y - 15); // Top horizontal
          path.lineTo(x + 10, y + 15); // Angled stem aligned with other numbers
          x += 25;
          break;
        case '8':
          // Top loop (smaller)
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 8),
            width: 14,
            height: 14,
          ));
          // Bottom loop (slightly larger and wider)
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 7),  // Moved down slightly to extend bottom
            width: 16,
            height: 14,  // Made taller
          ));
          x += 25;
          break;
        case '9':
          // Top circle - slightly oval
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 8),
            width: 16,
            height: 14,
          ));
          
          // Straight stem
          path.moveTo(x + 18, y - 8);  // Start from medium height on the circle
          path.lineTo(x + 18, y + 15); // Straight down to baseline
          x += 25;
          break;
        case '0':
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y),
            width: 20,
            height: 30,
          ));
          x += 25;
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
        case '-':
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          x += 30;
          break;
        case '×':
          path.moveTo(x + 10, y - 10);
          path.lineTo(x + 10, y + 10);
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          x += 30;
          break;
        case '÷':
          // Top dot
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 12),
            width: 4,
            height: 4,
          ));
          // Division line
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          // Bottom dot
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 12),
            width: 4,
            height: 4,
          ));
          x += 30;
          break;
        case '=':
          // Two parallel lines with more spacing
          path.moveTo(x, y - 8);
          path.lineTo(x + 20, y - 8);
          path.moveTo(x, y + 8);
          path.lineTo(x + 20, y + 8);
          x += 30;
          break;
        case '^':
          path.moveTo(x, y);
          path.lineTo(x + 5, y - 10);
          path.lineTo(x + 10, y);
          x += 15;
          break;
        case '(':
          path.moveTo(x + 10, y - 15);
          path.lineTo(x + 10, y + 15);
          path.addArc(
            Rect.fromCenter(
              center: Offset(x + 10, y),
              width: 20,
              height: 30,
            ),
            0,
            math.pi
          );
          x += 25;
          break;
        case ')':
          path.moveTo(x + 10, y - 15);
          path.lineTo(x + 10, y + 15);
          path.addArc(
            Rect.fromCenter(
              center: Offset(x + 10, y),
              width: 20,
              height: 30,
            ),
            math.pi,
            math.pi
          );
          x += 25;
          break;
        case '√':
          path.moveTo(x, y - 15);
          path.lineTo(x + 20, y - 15);
          path.moveTo(x + 20, y - 15);
          path.lineTo(x + 10, y + 15);
          x += 25;
          break;
        case '\n':
          y += 50;
          x = 50;
          break;
        case ' ':
          x += 10;
          break;
        default:
          // For numbers longer than 1 digit
          if (char.length > 1) {
            for (var digit in char.split('')) {
              final digitPath = Path();
              switch (digit) {
                case '1':
                  digitPath.moveTo(x + 2, y - 13);   // Start from top-left, slightly lower
                  digitPath.lineTo(x + 10, y - 15);  // Angle up to top of stem
                  digitPath.lineTo(x + 10, y + 15);  // Vertical line straight down
                  digitPath.lineTo(x, y + 15);       // Base left
                  digitPath.lineTo(x + 20, y + 15);  // Base right
                  break;
                case '2':
                  digitPath.moveTo(x + 3, y - 15);     // Start more left
                  digitPath.quadraticBezierTo(x + 20, y - 15, x + 15, y);  // Top curve (peaks left)
                  digitPath.quadraticBezierTo(x + 12, y + 10, x, y + 15);  // Bottom curve (more open in middle)
                  digitPath.lineTo(x + 17, y + 15);    // Bottom line (aligned with "1")
                  break;
                case '3':
                  digitPath.moveTo(x + 2, y - 15);     // Start top left
                  digitPath.quadraticBezierTo(x + 18, y - 15, x + 16, y - 8);  // Top bowl curves right
                  digitPath.quadraticBezierTo(x + 14, y - 2, x + 8, y);      // Connect to middle point, much more left
                  digitPath.quadraticBezierTo(x + 14, y + 2, x + 16, y + 8);  // Start of bottom bowl
                  digitPath.quadraticBezierTo(x + 18, y + 15, x + 2, y + 15); // Bottom bowl curves back left
                  break;
                case '4':
                  digitPath.moveTo(x + 15, y + 15);  // Bottom of vertical
                  digitPath.lineTo(x + 15, y - 15);  // Up vertical
                  digitPath.lineTo(x + 3, y + 5);    // Diagonal to left (moved in from x)
                  digitPath.lineTo(x + 20, y + 5);   // Horizontal line
                  break;
                case '5':
                  digitPath.moveTo(x + 16, y - 15);  // Top right (back to original)
                  digitPath.lineTo(x, y - 15);       // Top left (back to original)
                  digitPath.lineTo(x, y - 5);        // Down vertical (shorter)
                  digitPath.quadraticBezierTo(x + 15, y, x + 15, y + 5);  // Bottom curve start
                  digitPath.quadraticBezierTo(x + 15, y + 15, x, y + 15);  // Bottom curve end
                  break;
                case '6':
                  // Calculate relative dimensions for the 6
                  final width = 20.0;
                  final height = 30.0;
                  
                  digitPath.moveTo(x + width / 1.2, y - height/2);  // Start further right
                  digitPath.cubicTo(
                    x + width / 2 + 12, y - height/2 - 5,
                    x + width / 5, y - height/5.5,
                    x + width / 6, y + height/5.5
                  );
                  
                  digitPath.addArc(
                    Rect.fromCenter(
                      center: Offset(x + width/2 + 2, y + height/6),
                      width: width/1.2,
                      height: width/1.2
                    ),
                    math.pi,
                    2 * math.pi
                  );
                  break;
                case '7':
                  digitPath.moveTo(x, y - 15);     // Start top left
                  digitPath.lineTo(x + 20, y - 15); // Top horizontal
                  digitPath.lineTo(x + 10, y + 15); // Angled stem aligned with other numbers
                  break;
                case '8':
                  // Top loop (smaller)
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y - 8),
                    width: 14,
                    height: 14,
                  ));
                  // Bottom loop (slightly larger and wider)
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y + 7),  // Moved down slightly to extend bottom
                    width: 16,
                    height: 14,  // Made taller
                  ));
                  break;
                case '9':
                  // Top circle - slightly oval
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y - 8),
                    width: 16,
                    height: 14,
                  ));
                  
                  // Straight stem
                  digitPath.moveTo(x + 18, y - 8);  // Start from medium height on the circle
                  digitPath.lineTo(x + 18, y + 15); // Straight down to baseline
                  break;
                case '0':
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y),
                    width: 20,
                    height: 30,
                  ));
                  break;
              }
              _paths.add(digitPath);
              _pathLengths.add(60); // Increased path length for more complex numbers
              _totalLength += 60;
              x += 25;
            }
          }
      }
      
      if (char != ' ' && char != '\n') {
        final pathMetrics = path.computeMetrics();
        double pathLength = 0;
        for (final metric in pathMetrics) {
          pathLength += metric.length;
        }
        if (pathLength > 0) {
          _paths.add(path);
          _pathLengths.add(pathLength);
          _totalLength += pathLength;
        }
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
