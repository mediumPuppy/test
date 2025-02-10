import 'package:flutter/material.dart';
import '../widgets/human_like_drawing_painter.dart';

// DrawingAndSpeechScreen - integrated with AnimationController and CustomPainter
class DrawingAndSpeechScreen extends StatefulWidget {
  const DrawingAndSpeechScreen({Key? key}) : super(key: key);

  @override
  _DrawingAndSpeechScreenState createState() => _DrawingAndSpeechScreenState();
}

class _DrawingAndSpeechScreenState extends State<DrawingAndSpeechScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double totalDuration =
      2.0; // seconds; matches the drawing stage for the triangle

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration.toInt()),
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
        title: Text('Drawing & Speech Demo'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Calculate current time in seconds based on the animation controller value
          double currentTime = _controller.value * totalDuration;
          return CustomPaint(
            painter: HumanLikeDrawingPainter(currentTime: currentTime),
            child: Container(),
          );
        },
      ),
    );
  }
}
