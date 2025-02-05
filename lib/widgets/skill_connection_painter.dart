import 'dart:math';
import 'package:flutter/material.dart';
import '../models/skill.dart';

class SkillConnection {
  final Offset start;
  final Offset end;
  final bool isUnlocked;
  final bool isCompleted;

  const SkillConnection({
    required this.start,
    required this.end,
    required this.isUnlocked,
    required this.isCompleted,
  });
}

class SkillConnectionPainter extends CustomPainter {
  final List<SkillConnection> connections;
  final Animation<double>? animation;
  final Color baseColor;
  final Color unlockedColor;
  final Color completedColor;
  final double strokeWidth;

  SkillConnectionPainter({
    required this.connections,
    this.animation,
    this.baseColor = Colors.grey,
    this.unlockedColor = Colors.blue,
    this.completedColor = Colors.green,
    this.strokeWidth = 3.0,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final connection in connections) {
      final progress = animation?.value ?? 1.0;
      final start = connection.start;
      final end = connection.end;

      // Calculate the point along the line based on animation progress
      final currentEnd = Offset(
        start.dx + (end.dx - start.dx) * progress,
        start.dy + (end.dy - start.dy) * progress,
      );

      // Set color based on connection state
      if (connection.isCompleted) {
        paint.color = completedColor;
      } else if (connection.isUnlocked) {
        paint.color = unlockedColor;
      } else {
        paint.color = baseColor;
      }

      // Draw dashed line for locked connections
      if (!connection.isUnlocked) {
        _drawDashedLine(canvas, start, currentEnd, paint);
      } else {
        canvas.drawLine(start, currentEnd, paint);
      }

      // Draw arrow at the end of the line
      if (progress > 0.9) {
        _drawArrow(canvas, currentEnd, end, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy);

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final steps = (distance / (dashWidth + dashSpace)).floor();
    final stepX = dx / steps;
    final stepY = dy / steps;

    var currentX = start.dx;
    var currentY = start.dy;

    for (var i = 0; i < steps; i++) {
      currentX += stepX;
      currentY += stepY;
      if (i % 2 == 0) {
        canvas.drawLine(
          Offset(currentX - stepX, currentY - stepY),
          Offset(currentX, currentY),
          paint,
        );
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = (end - start).direction;
    final arrowSize = strokeWidth * 3;

    final path = Path();
    path.moveTo(
      end.dx - arrowSize * cos(angle - pi / 6),
      end.dy - arrowSize * sin(angle - pi / 6),
    );
    path.lineTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * cos(angle + pi / 6),
      end.dy - arrowSize * sin(angle + pi / 6),
    );
    path.close();

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(SkillConnectionPainter oldDelegate) {
    return oldDelegate.connections != connections ||
           oldDelegate.animation?.value != animation?.value ||
           oldDelegate.baseColor != baseColor ||
           oldDelegate.unlockedColor != unlockedColor ||
           oldDelegate.completedColor != completedColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
} 