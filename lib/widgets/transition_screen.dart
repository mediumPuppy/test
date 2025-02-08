import 'package:flutter/material.dart';

/// A widget that displays a transition screen between videos.
/// Can show a whiteboard or other content during transitions.
class TransitionScreen extends StatefulWidget {
  final Widget? content;
  final Duration duration;
  final VoidCallback? onTransitionComplete;

  const TransitionScreen({
    super.key,
    this.content,
    this.duration = const Duration(seconds: 3),
    this.onTransitionComplete,
  });

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      widget.onTransitionComplete?.call();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.white,
        child: widget.content ?? const WhiteboardContent(),
      ),
    );
  }
}

/// Default whiteboard content widget that can be shown during transitions
class WhiteboardContent extends StatelessWidget {
  const WhiteboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 48.0,
              color: Colors.black54,
            ),
            SizedBox(height: 16.0),
            Text(
              'Whiteboard',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
