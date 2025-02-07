import 'package:flutter/material.dart';
import 'whiteboard_screen.dart';
import '../services/explanation_service.dart';

class InteractiveWhiteboardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WhiteboardScreen(
          text: text,
          drawingCommands: drawingCommands,
          duration: duration,
          onAnimationComplete: onAnimationComplete,
        ),
        if (showControls)
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Rebuild the whiteboard to restart animation
                    if (context.mounted) {
                      final state = context.findAncestorStateOfType<State>();
                      if (state != null) {
                        state.setState(() {});
                      }
                    }
                  },
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
