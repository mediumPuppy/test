import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

/// A widget that displays animated speech text overlay
class SpeechOverlay extends StatefulWidget {
  final SpeechSpec spec;
  final double Function(DrawingStage) getStageProgress;
  final List<DrawingStage> stages;
  final bool isPlaying;
  final VoidCallback? onTap;

  const SpeechOverlay({
    super.key,
    required this.spec,
    required this.getStageProgress,
    required this.stages,
    required this.isPlaying,
    this.onTap,
  });

  @override
  State<SpeechOverlay> createState() => _SpeechOverlayState();
}

class _SpeechOverlayState extends State<SpeechOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  String _currentText = '';

  @override
  void initState() {
    super.initState();

    // Set up fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Calculate the current text to display based on stages progress
  String _calculateCurrentText() {
    // Find the current active stage
    DrawingStage? activeStage;
    double maxProgress = 0;

    for (final stage in widget.stages) {
      final progress = widget.getStageProgress(stage);
      if (progress > 0 && progress > maxProgress) {
        maxProgress = progress;
        activeStage = stage;
      }
    }

    if (activeStage == null) {
      return widget.isPlaying ? 'Starting...' : 'Tap to begin';
    }

    return activeStage.description;
  }

  @override
  void didUpdateWidget(SpeechOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newText = _calculateCurrentText();
    if (newText != _currentText) {
      // Fade out current text
      _fadeController.reverse().then((_) {
        setState(() {
          _currentText = newText;
        });
        // Fade in new text
        _fadeController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeController.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isPlaying ? 'Tap to pause' : 'Tap to resume',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
