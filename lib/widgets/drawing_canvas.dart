import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';
import '../painters/human_like_drawing_painter.dart';

/// A widget that displays and animates the drawing specification
class DrawingCanvas extends StatefulWidget {
  final DrawingSpec spec;
  final VoidCallback? onAnimationComplete;
  final bool autoStart;
  final bool loop;

  const DrawingCanvas({
    super.key,
    required this.spec,
    this.onAnimationComplete,
    this.autoStart = true,
    this.loop = false,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

/// The state for the DrawingCanvas widget
/// Exposed to allow external control of the animation
class DrawingCanvasState extends State<DrawingCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Use fixed duration like triangle implementation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 3), // Slightly longer than triangle for more elements
    );

    // Set up completion callback
    _controller.addStatusListener(_handleAnimationStatus);

    // Auto-start if specified
    if (widget.autoStart) {
      play();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update autoStart behavior
    if (!oldWidget.autoStart && widget.autoStart && !_isPlaying) {
      play();
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isPlaying = false;
      });
      widget.onAnimationComplete?.call();

      if (widget.loop) {
        play();
      }
    }
  }

  /// Start or resume the animation
  void play() {
    print(
        '[${DateTime.now()}] Starting animation - Duration: ${_controller.duration?.inMilliseconds}ms');
    setState(() {
      _isPlaying = true;
    });
    _controller.forward(
        from: _controller.value == 1.0 ? 0.0 : _controller.value);
  }

  /// Pause the animation
  void pause() {
    setState(() {
      _isPlaying = false;
    });
    _controller.stop();
  }

  /// Reset the animation to the beginning
  void reset() {
    setState(() {
      _isPlaying = false;
    });
    _controller.reset();
  }

  /// Calculate the progress of a specific stage
  double getStageProgress(DrawingStage stage) {
    // Use the raw animation value directly
    final animationValue =
        _controller.value * 3.0; // Scale to match our 3-second total duration

    print('[${DateTime.now()}] Stage ${stage.name} timing - ' +
        'Stage window: ${stage.startTime.toStringAsFixed(3)} to ${stage.endTime.toStringAsFixed(3)}, ' +
        'Current time: ${animationValue.toStringAsFixed(3)}');

    // Calculate progress for this stage
    if (animationValue < stage.startTime) return 0.0;
    if (animationValue >= stage.endTime) return 1.0;

    // Calculate progress within stage's time window
    return ((animationValue - stage.startTime) /
            (stage.endTime - stage.startTime))
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (_) {
            if (_isPlaying) {
              pause();
            } else {
              play();
            }
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: HumanLikeDrawingPainter(
              spec: widget.spec,
              getStageProgress: getStageProgress,
            ),
          ),
        );
      },
    );
  }
}
