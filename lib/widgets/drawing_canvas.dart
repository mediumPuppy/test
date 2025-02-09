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

    // Calculate total duration from the last stage's end time
    final duration = widget.spec.stages.isEmpty
        ? const Duration(seconds: 1)
        : Duration(
            milliseconds: (widget.spec.stages.last.endTime * 1000).round(),
          );

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: duration,
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

    // Update duration if spec changed
    if (oldWidget.spec != widget.spec) {
      final newDuration = widget.spec.stages.isEmpty
          ? const Duration(seconds: 1)
          : Duration(
              milliseconds: (widget.spec.stages.last.endTime * 1000).round(),
            );
      _controller.duration = newDuration;
    }

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
    final currentTime =
        _controller.value * _controller.duration!.inMilliseconds / 1000;

    // Before stage starts
    if (currentTime < stage.startTime) return 0;
    // After stage ends
    if (currentTime > stage.endTime) return 1;

    // During stage
    final stageProgress =
        (currentTime - stage.startTime) / (stage.endTime - stage.startTime);
    return stageProgress.clamp(0.0, 1.0);
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
