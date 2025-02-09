import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

/// A CustomPainter that handles drawing all elements with human-like animation
class HumanLikeDrawingPainter extends CustomPainter {
  final DrawingSpec spec;
  final double Function(DrawingStage) getStageProgress;
  final bool showDebugInfo;

  const HumanLikeDrawingPainter({
    required this.spec,
    required this.getStageProgress,
    this.showDebugInfo = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply coordinate transformation to match the canvas size
    final transform = _calculateTransform(size);
    canvas.save();
    canvas.transform(transform.storage);

    // Draw each stage's elements sequentially
    for (final stage in spec.stages) {
      final progress = getStageProgress(stage);
      if (progress <= 0) continue; // Skip stages that haven't started

      print(
          '[${DateTime.now()}] Drawing stage: ${stage.name} (progress: ${progress.toStringAsFixed(3)})');

      // Each element in a stage gets its own time slice
      final elementCount = stage.elements.length;
      final elementDuration = 1.0 / elementCount;

      for (int i = 0; i < stage.elements.length; i++) {
        // Calculate sequential timing for this element
        final elementStart = i * elementDuration;
        final elementEnd = (i + 1) * elementDuration;

        // Map the overall stage progress to this element's time window
        final elementProgress =
            ((progress - elementStart) / (elementEnd - elementStart))
                .clamp(0.0, 1.0);
        if (elementProgress <= 0) continue;

        print(
            '[${DateTime.now()}] Drawing element ${i + 1}/${elementCount} of type ${stage.elements[i].type} (progress: ${elementProgress.toStringAsFixed(3)})');

        // Add natural drawing variations
        final naturalProgress = _naturalizeProgress(elementProgress);
        _drawElement(canvas, size, stage.elements[i], naturalProgress);
      }
    }

    canvas.restore();

    if (showDebugInfo) {
      _drawDebugInfo(canvas, size);
    }
  }

  /// Calculate the transformation matrix to map coordinates to canvas size
  Matrix4 _calculateTransform(Size size) {
    // Find the bounds of all elements to determine the scale
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stage in spec.stages) {
      for (final element in stage.elements) {
        final bounds = _getElementBounds(element);
        minX = math.min(minX, bounds.left);
        maxX = math.max(maxX, bounds.right);
        minY = math.min(minY, bounds.top);
        maxY = math.max(maxY, bounds.bottom);
      }
    }

    // Add padding
    const padding = 20.0;
    minX -= padding;
    maxX += padding;
    minY -= padding;
    maxY += padding;

    // Calculate scale to fit the canvas
    final scaleX = size.width / (maxX - minX);
    final scaleY = size.height / (maxY - minY);
    final scale = math.min(scaleX, scaleY);

    // Center the drawing
    final tx = (size.width - (maxX - minX) * scale) / 2 - minX * scale;
    final ty = (size.height - (maxY - minY) * scale) / 2 - minY * scale;

    return Matrix4.identity()
      ..scale(scale, scale)
      ..translate(tx / scale, ty / scale);
  }

  /// Get the bounding rectangle of an element
  Rect _getElementBounds(DrawingElement element) {
    switch (element.runtimeType) {
      case GridElement:
        return const Rect.fromLTRB(-100, -100, 100, 100); // Default grid size
      case AxesElement:
        return const Rect.fromLTRB(-100, -100, 100, 100); // Default axes size
      case LineElement:
        final line = element as LineElement;
        final points = line.points;
        final xs = points.map((p) => p.x);
        final ys = points.map((p) => p.y);
        return Rect.fromLTRB(
          xs.reduce(math.min),
          ys.reduce(math.min),
          xs.reduce(math.max),
          ys.reduce(math.max),
        );
      case SlopeIndicatorElement:
        final slope = element as SlopeIndicatorElement;
        return Rect.fromPoints(
          Offset(slope.startPoint.x, slope.startPoint.y),
          Offset(slope.endPoint.x, slope.endPoint.y),
        );
      case LabelElement:
        final label = element as LabelElement;
        final pos = label.position;
        // Estimate text bounds
        return Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: label.text.length * label.fontSize * 0.6,
          height: label.fontSize * 1.2,
        );
      default:
        return Rect.zero;
    }
  }

  /// Draw a single element with the given progress
  void _drawElement(
      Canvas canvas, Size size, DrawingElement element, double progress) {
    switch (element.runtimeType) {
      case GridElement:
        _drawGrid(canvas, element as GridElement, progress);
        break;
      case AxesElement:
        _drawAxes(canvas, element as AxesElement, progress);
        break;
      case LineElement:
        _drawLine(canvas, element as LineElement, progress);
        break;
      case SlopeIndicatorElement:
        _drawSlopeIndicator(canvas, element as SlopeIndicatorElement, progress);
        break;
      case LabelElement:
        _drawLabel(canvas, element as LabelElement, progress);
        break;
    }
  }

  /// Draw a grid with dashed or solid lines
  void _drawGrid(Canvas canvas, GridElement grid, double progress) {
    print(
        '[${DateTime.now()}] Starting grid drawing with progress: ${progress.toStringAsFixed(3)}');

    final paint = Paint()
      ..color = grid.color.withOpacity(grid.opacity * progress)
      ..strokeWidth = grid.lineWidth
      ..style = PaintingStyle.stroke;

    // Calculate grid lines based on spacing
    final bounds = _getElementBounds(grid);
    final xStart = (bounds.left / grid.spacing).floor() * grid.spacing;
    final xEnd = (bounds.right / grid.spacing).ceil() * grid.spacing;
    final yStart = (bounds.top / grid.spacing).floor() * grid.spacing;
    final yEnd = (bounds.bottom / grid.spacing).ceil() * grid.spacing;

    // Draw vertical lines
    for (double x = xStart; x <= xEnd; x += grid.spacing) {
      canvas.drawLine(
        Offset(x, bounds.top),
        Offset(x, bounds.bottom),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = yStart; y <= yEnd; y += grid.spacing) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        paint,
      );
    }

    print('[${DateTime.now()}] Completed grid drawing');
  }

  /// Draw coordinate axes with optional arrowheads
  void _drawAxes(Canvas canvas, AxesElement axes, double progress) {
    print(
        '[${DateTime.now()}] Drawing axes with progress: ${progress.toStringAsFixed(3)}');

    final paint = Paint()
      ..color = axes.color.withOpacity(progress)
      ..strokeWidth = axes.lineWidth
      ..style = PaintingStyle.stroke;

    final bounds = _getElementBounds(axes);

    // Draw x-axis first (0 to 0.5 progress)
    if (progress <= 0.5) {
      final xProgress = progress * 2;
      canvas.drawLine(
        Offset(bounds.left, 0),
        Offset(bounds.left + (bounds.right - bounds.left) * xProgress, 0),
        paint,
      );
    } else {
      // X-axis is complete
      canvas.drawLine(
        Offset(bounds.left, 0),
        Offset(bounds.right, 0),
        paint,
      );

      // Draw y-axis (0.5 to 1.0 progress)
      final yProgress = (progress - 0.5) * 2;
      canvas.drawLine(
        Offset(0, bounds.bottom),
        Offset(0, bounds.bottom + (bounds.top - bounds.bottom) * yProgress),
        paint,
      );
    }

    // Draw arrowheads when their respective axes are complete
    if (axes.showArrowheads) {
      if (progress > 0.45) {
        _drawArrowhead(canvas, paint, Offset(bounds.right, 0), 0);
      }
      if (progress > 0.95) {
        _drawArrowhead(canvas, paint, Offset(0, bounds.top), math.pi / 2);
      }
    }
  }

  /// Draw a line connecting multiple points
  void _drawLine(Canvas canvas, LineElement line, double progress) {
    print(
        '[${DateTime.now()}] Drawing line with progress: ${progress.toStringAsFixed(3)}');

    final paint = Paint()
      ..color = line.color.withOpacity(progress)
      ..strokeWidth = line.lineWidth
      ..style = PaintingStyle.stroke;

    final points = line.points;
    if (points.length < 2) return;

    if (line.isDashed) {
      for (int i = 0; i < points.length - 1; i++) {
        final start = points[i];
        final end = points[i + 1];
        _drawDashedLine(
          canvas,
          paint,
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          progress,
        );
      }
    } else {
      final path = Path();
      path.moveTo(points.first.x, points.first.y);

      for (int i = 1; i < points.length; i++) {
        final start = points[i - 1];
        final end = points[i];
        final currentEnd = Offset(
          start.x + (end.x - start.x) * progress,
          start.y + (end.y - start.y) * progress,
        );
        path.lineTo(currentEnd.dx, currentEnd.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  /// Draw rise and run arrows for slope visualization
  void _drawSlopeIndicator(
      Canvas canvas, SlopeIndicatorElement slope, double progress) {
    final start = slope.startPoint;
    final end = slope.endPoint;

    // Draw rise arrow first (0 to 0.5 progress)
    if (progress <= 0.5) {
      final riseProgress = progress * 2;
      final risePaint = Paint()
        ..color = slope.riseColor
        ..strokeWidth = slope.lineWidth
        ..style = PaintingStyle.stroke;

      final riseStart = Offset(start.x, start.y);
      final riseEnd = Offset(start.x, end.y);
      _drawArrowLine(canvas, risePaint, riseStart, riseEnd, riseProgress);
    } else {
      // Rise arrow is complete
      final risePaint = Paint()
        ..color = slope.riseColor
        ..strokeWidth = slope.lineWidth
        ..style = PaintingStyle.stroke;

      final riseStart = Offset(start.x, start.y);
      final riseEnd = Offset(start.x, end.y);
      _drawArrowLine(canvas, risePaint, riseStart, riseEnd, 1.0);

      // Draw run arrow (0.5 to 1.0 progress)
      final runProgress = (progress - 0.5) * 2;
      final runPaint = Paint()
        ..color = slope.runColor
        ..strokeWidth = slope.lineWidth
        ..style = PaintingStyle.stroke;

      final runStart = Offset(start.x, end.y);
      final runEnd = Offset(end.x, end.y);
      _drawArrowLine(canvas, runPaint, runStart, runEnd, runProgress);
    }
  }

  /// Draw text labels with fade-in animation
  void _drawLabel(Canvas canvas, LabelElement label, double progress) {
    // Calculate fade based on progress and label's fade timing
    final fadeProgress = progress.clamp(label.fadeInStart, label.fadeInEnd);
    final opacity = (fadeProgress - label.fadeInStart) /
        (label.fadeInEnd - label.fadeInStart);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label.text,
        style: TextStyle(
          color: label.color.withOpacity(opacity.clamp(0.0, 1.0)),
          fontSize: label.fontSize,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        label.position.x - textPainter.width / 2,
        label.position.y - textPainter.height / 2,
      ),
    );
  }

  /// Helper method to draw a dashed line
  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
    double progress,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final dest = Path();
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    final metrics = path.computeMetrics().first;
    final maxLength = metrics.length * progress;

    var distance = 0.0;
    var draw = true;
    while (distance < maxLength) {
      final nextDistance = distance + (draw ? dashWidth : dashSpace);
      if (nextDistance > maxLength) {
        dest.addPath(
          metrics.extractPath(distance, maxLength),
          Offset.zero,
        );
        break;
      }
      dest.addPath(
        metrics.extractPath(distance, nextDistance),
        Offset.zero,
      );
      distance = nextDistance;
      draw = !draw;
    }

    canvas.drawPath(dest, paint);
  }

  /// Helper method to draw an arrowhead
  void _drawArrowhead(Canvas canvas, Paint paint, Offset tip, double angle) {
    const arrowSize = 10.0;
    final path = Path();

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - math.pi / 6),
      tip.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + math.pi / 6),
      tip.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  /// Helper method to draw a line with an arrowhead
  void _drawArrowLine(
      Canvas canvas, Paint paint, Offset start, Offset end, double progress) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // Draw the line
    final actualEnd = Offset(
      start.dx + dx * progress,
      start.dy + dy * progress,
    );
    canvas.drawLine(start, actualEnd, paint);

    // Draw the arrowhead when progress is near completion
    if (progress > 0.9) {
      _drawArrowhead(canvas, paint, end, angle);
    }
  }

  /// Add natural variation to the progress
  double _naturalizeProgress(double progress) {
    // Add a slight ease-in-out curve with more pronounced start and end
    final p = progress < 0.5
        ? 4 * progress * progress * progress
        : 1 - math.pow(-2 * progress + 2, 3) / 2;

    // Add subtle speed variations that mimic human drawing
    final variation = math.sin(progress * math.pi * 3) * 0.08 * (1 - progress);
    return (p + variation).clamp(0.0, 1.0);
  }

  /// Draw debug information if enabled
  void _drawDebugInfo(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Debug Info:\n' +
            spec.stages
                .map((s) => '${s.name}: ${getStageProgress(s)}')
                .join('\n'),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(HumanLikeDrawingPainter oldDelegate) {
    return true; // Always repaint while animating
  }
}
