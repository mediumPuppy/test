import 'package:flutter/material.dart';
import 'whiteboard_screen.dart';
import '../services/explanation_service.dart';

class InteractiveWhiteboardScreen extends StatefulWidget {
  final String? text;
  final List<DrawingCommand>? drawingCommands;
  final Duration duration;
  final VoidCallback? onAnimationComplete;
  final bool showControls;

  const InteractiveWhiteboardScreen({
    super.key,
    this.text,
    this.drawingCommands,
    this.duration = const Duration(seconds: 10),
    this.onAnimationComplete,
    this.showControls = true,
  });

  @override
  State<InteractiveWhiteboardScreen> createState() => _InteractiveWhiteboardScreenState();
}

class _InteractiveWhiteboardScreenState extends State<InteractiveWhiteboardScreen> {
  // Add a key to force rebuild of WhiteboardScreen
  Key _whiteboardKey = UniqueKey();

  void _resetAnimation() {
    setState(() {
      // Generate a new key to force rebuild
      _whiteboardKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WhiteboardScreen(
          key: _whiteboardKey,
          text: widget.text,
          drawingCommands: widget.drawingCommands,
          duration: widget.duration,
          onAnimationComplete: widget.onAnimationComplete,
        ),
        if (widget.showControls)
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetAnimation,
                  tooltip: 'Replay Animation',
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    // TODO: Implement save functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save feature coming soon!')),
                    );
                  },
                  tooltip: 'Save Whiteboard',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
