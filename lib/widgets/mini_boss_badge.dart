import 'package:flutter/material.dart';

class MiniBossBadge extends StatelessWidget {
  final double size;
  final bool isUnlocked;
  final bool isCompleted;
  final Color? color;

  const MiniBossBadge({
    Key? key,
    this.size = 32.0,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.primaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Colors.green
            : isUnlocked
                ? badgeColor
                : Colors.grey[400],
        border: Border.all(
          color: Colors.white,
          width: size * 0.1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : badgeColor).withOpacity(0.3),
            blurRadius: size * 0.2,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isCompleted
              ? Icons.check
              : isUnlocked
                  ? Icons.star
                  : Icons.lock,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  // Factory constructor for a pulsing version of the badge
  static Widget pulsing({
    Key? key,
    double size = 32.0,
    bool isUnlocked = false,
    bool isCompleted = false,
    Color? color,
    Duration duration = const Duration(seconds: 2),
  }) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.8, end: 1.2),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: MiniBossBadge(
            size: size,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            color: color,
          ),
        );
      },
    );
  }
} 