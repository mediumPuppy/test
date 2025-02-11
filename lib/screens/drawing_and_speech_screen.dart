import 'package:flutter/material.dart';
import '../widgets/human_like_drawing_painter.dart';
import '../models/drawing_spec_models.dart';
import 'dart:math' show max;

// DrawingAndSpeechScreen - integrated with AnimationController and CustomPainter
class DrawingAndSpeechScreen extends StatefulWidget {
  final DrawingSpecification specification;
  final VoidCallback? onAnimationComplete;

  const DrawingAndSpeechScreen({
    super.key,
    required this.specification,
    this.onAnimationComplete,
  });

  @override
  _DrawingAndSpeechScreenState createState() => _DrawingAndSpeechScreenState();
}

class _DrawingAndSpeechScreenState extends State<DrawingAndSpeechScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double totalDuration;

  @override
  void initState() {
    super.initState();

    // Calculate total duration from the last stage's endTime
    totalDuration = widget.specification.stages.isEmpty
        ? 10.0 // Default duration if no stages
        : widget.specification.stages.map((s) => s.endTime).reduce(max);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDuration.toInt()),
    );

    // Add completion callback
    if (widget.onAnimationComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete!();
        }
      });
    }

    _controller.forward();
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
        title: Text(widget.specification.metadata.topicTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () {
              if (_controller.isAnimating) {
                _controller.stop();
              } else {
                _controller.forward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              _controller.reset();
              _controller.forward();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.specification.metadata.topicSubtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.specification.metadata.topicSubtitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Calculate current time in seconds based on the animation controller value
                    double currentTime = _controller.value * totalDuration;
                    return CustomPaint(
                      painter: HumanLikeDrawingPainter(
                        currentTime: currentTime,
                        specification: widget.specification,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _controller.value,
                      onChanged: (value) {
                        setState(() {
                          _controller.value = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
