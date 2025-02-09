import 'dart:math';
import 'package:flutter/animation.dart';

/// Utility class for mapping string-based easing function names to Flutter Curves
class CurvesMapping {
  /// Maps a string name to a Flutter Curve
  static Curve getCurve(String name) {
    switch (name.toLowerCase()) {
      case 'linear':
        return Curves.linear;
      case 'easein':
        return Curves.easeIn;
      case 'easeout':
        return Curves.easeOut;
      case 'easeinout':
        return Curves.easeInOut;
      case 'elasticin':
        return Curves.elasticIn;
      case 'elasticout':
        return Curves.elasticOut;
      case 'elasticinout':
        return Curves.elasticInOut;
      case 'bouncein':
        return Curves.bounceIn;
      case 'bounceout':
        return Curves.bounceOut;
      case 'bounceinout':
        return Curves.bounceInOut;
      // Custom human-like drawing curves
      case 'drawingslow':
        return const _DrawingSlowCurve();
      case 'drawingnatural':
        return const _DrawingNaturalCurve();
      case 'drawingquick':
        return const _DrawingQuickCurve();
      default:
        return Curves.easeInOut; // Default to easeInOut if unknown
    }
  }
}

/// Custom curve that simulates slow, careful drawing
/// Starts slow, maintains steady pace, ends gently
class _DrawingSlowCurve extends Curve {
  const _DrawingSlowCurve();

  @override
  double transformInternal(double t) {
    // Start slow (quadratic), maintain steady pace, end gently
    if (t < 0.3) {
      return 3.33 * t * t; // Slow start
    } else if (t < 0.7) {
      return 0.3 + (t - 0.3) * 0.8; // Steady middle
    } else {
      final x = (t - 0.7) / 0.3;
      return 0.62 + 0.38 * (1 - (1 - x) * (1 - x)); // Gentle end
    }
  }
}

/// Custom curve that simulates natural, human-like drawing
/// Has slight variations in speed to appear more natural
class _DrawingNaturalCurve extends Curve {
  const _DrawingNaturalCurve();

  @override
  double transformInternal(double t) {
    // Add subtle variations to make it feel more natural
    final base = t * t * (3 - 2 * t); // Smooth base curve
    final variation = 0.1 * sin(t * 3.14159 * 2) * t * (1 - t);
    return (base + variation).clamp(0.0, 1.0);
  }
}

/// Custom curve that simulates quick but controlled drawing
/// Starts with momentum, maintains speed, ends with control
class _DrawingQuickCurve extends Curve {
  const _DrawingQuickCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.2) {
      return 2.5 * t * t; // Quick start
    } else if (t < 0.8) {
      return 0.1 + (t - 0.2) * 1.25; // Fast middle
    } else {
      final x = (t - 0.8) / 0.2;
      return 0.85 + 0.15 * x; // Controlled end
    }
  }
}
