// handwriting_util.dart
import 'package:flutter/material.dart';
import '../models/drawing_command.dart';

/// Generates drawing commands for a given equation text using the same
/// logic as you use in WhiteboardScreen._initializePaths().
List<DrawingCommand> generateHandwrittenCommands(
    String text, Offset startOffset) {
  double x = startOffset.dx;
  double y = startOffset.dy;
  List<DrawingCommand> commands = [];

  for (var char in text.toLowerCase().split('')) {
    // Check if the character is a multi-digit number
    if (RegExp(r'\d+').hasMatch(char) && char.length > 1) {
      // Handle multi-digit numbers by processing each digit separately
      for (var digit in char.split('')) {
        var digitCommands =
            _generateDigitCommands(digit, x, y, startOffset: startOffset);
        commands.addAll(digitCommands);
        x += 25; // Advance x position for next digit
      }
    } else {
      var charCommands =
          _generateDigitCommands(char, x, y, startOffset: startOffset);
      commands.addAll(charCommands);

      // Adjust x position based on character type
      switch (char) {
        case '^':
        case '(':
        case ')':
          x += 15;
          break;
        case '√':
          x += 30;
          break;
        case ' ':
          x += 10;
          break;
        case '\n':
          y += 50;
          x = startOffset.dx;
          break;
        case '1':
          x += 22.5;
          break;
        case 'w':
          x += 22.5;
          break;
        case 'l':
          x += 12;
          break;
        case 'u':
          x += 15;
          break;
        case 'n':
          x += 15;
          break;
        case 'r':
          x += 13;
          break;
        case 'o':
          x += 16;
          break;
        case 's':
          x += 12.5;
          break;
        case 't':
          x += 13;
          break;
        case 'i':
          x += 12;
          break;
        case 'p':
          x += 15;
          break;

        default:
          x += 20;
      }
    }
  }

  // Add path length information to each command
  for (var command in commands) {
    command.params['pathLength'] = 60.0; // Base path length for animation
  }

  return commands;
}

List<DrawingCommand> _generateDigitCommands(String char, double x, double y,
    {required Offset startOffset}) {
  List<DrawingCommand> commands = [];

  switch (char) {
    case '1':
      // Start from top-left, slightly lower
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 2.0, 'y': y - 13.0}));
      // Angle up to top of stem
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y - 15.0}));
      // Vertical line straight down
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));
      // Base left
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x, 'y': y + 15.0}));
      // Base right
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y + 15.0}));
      break;
    case '2':
      // Start more left
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 3.0, 'y': y - 15.0}));
      // Top curve (peaks left)
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 20.0,
        'controlY': y - 15.0,
        'endX': x + 15.0,
        'endY': y
      }));
      // Bottom curve (more open in middle)
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 12.0,
        'controlY': y + 10.0,
        'endX': x,
        'endY': y + 15.0
      }));
      // Bottom line (aligned with "1")
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 17.0, 'y': y + 15.0}));
      break;
    case '3':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 2.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 18.0,
        'controlY': y - 15.0,
        'endX': x + 16.0,
        'endY': y - 8.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 14.0,
        'controlY': y - 2.0,
        'endX': x + 8.0,
        'endY': y
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 14.0,
        'controlY': y + 2.0,
        'endX': x + 16.0,
        'endY': y + 8.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 18.0,
        'controlY': y + 15.0,
        'endX': x + 2.0,
        'endY': y + 15.0
      }));
      break;
    case '+':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 10.0, 'y': y - 10.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 10.0}));
      commands.add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 20.0, 'y': y}));
      break;
    case '=':
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y - 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y - 3.0}));
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y + 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y + 3.0}));
      break;

    case '4':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 15.0, 'y': y + 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y - 15.0}));
      commands.add(
          DrawingCommand(type: 'lineTo', params: {'x': x + 3.0, 'y': y + 5.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y + 5.0}));
      break;
    case '5':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 16.0, 'y': y - 15.0}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x, 'y': y - 15.0}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x, 'y': y - 5.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 15.0,
        'controlY': y,
        'endX': x + 15.0,
        'endY': y + 5.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 15.0,
        'controlY': y + 15.0,
        'endX': x,
        'endY': y + 15.0
      }));
      break;
    case '6':
      // Calculate relative dimensions for the 6
      final width = 20.0; // Base width for the number
      final height = 30.0; // Base height for the number

      // Top curve of 6 - extends further and curves down more
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + width / 1.2, 'y': y - height / 2}));

      // Main curve from top to bottom
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + width / 2 + 12,
        'controlY1': y - height / 2 - 5, // First control point, higher
        'controlX2': x + width / 5,
        'controlY2': y - height / 4, // Second control point, more left
        'endX': x + width / 6,
        'endY': y + height / 6 // End point, much higher to cut off more bottom
      }));

      // Bottom circle of 6 using addOval like other circular numbers
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + width / 2 + 2,
        'centerY': y + height / 6,
        'width': width / 1.2,
        'height': width / 1.2
      }));
      break;
    case '7':
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));
      break;
    case '8':
      // existing "8" with two ovals is left unchanged
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y - 8.0,
        'width': 14.0,
        'height': 14.0,
      }));
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 7.0,
        'width': 16.0,
        'height': 14.0,
      }));
      break;
    case '9':
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y - 8.0,
        'width': 16.0,
        'height': 14.0
      }));
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 18.0, 'y': y - 8.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 18.0, 'y': y + 15.0}));
      break;
    case '0':
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y,
        'width': 20.0,
        'height': 30.0
      }));
      break;
    case 'x':
      // Drawing for lowercase 'x' with two crossing lines at x-height
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y + 14.0}));
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 15.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 14.0}));
      break;
    case '-':
      commands.add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 15.0, 'y': y}));
      break;
    case '×':
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y - 5.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y + 5.0}));
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 15.0, 'y': y - 5.0}));
      commands.add(
          DrawingCommand(type: 'lineTo', params: {'x': x + 5.0, 'y': y + 5.0}));
      break;
    case '÷':
      commands.add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 20.0, 'y': y}));
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y - 5.0,
        'width': 3.0,
        'height': 3.0
      }));
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 5.0,
        'width': 3.0,
        'height': 3.0
      }));
      break;
    case '^':
      commands.add(DrawingCommand(type: 'moveTo', params: {'x': x, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y - 10.0}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 10.0, 'y': y}));
      break;
    case '(':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 10.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 2.0,
        'controlY': y,
        'endX': x + 10.0,
        'endY': y + 15.0
      }));
      break;
    case ')':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 5.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 13.0,
        'controlY': y,
        'endX': x + 5.0,
        'endY': y + 15.0
      }));
      break;
    case '√':
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 2.0, 'y': y - 10.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y - 10.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 7.0,
        'controlY': y - 8.0,
        'endX': x + 8.0,
        'endY': y - 5.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 10.0,
        'controlY': y + 3.0,
        'endX': x + 12.0,
        'endY': y + 5.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 14.0,
        'controlY': y + 6.0,
        'endX': x + 25.0,
        'endY': y + 6.0
      }));
      break;
    case 'a':
      // Draw the circular part of the lowercase 'a' (smaller and lower)
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 9.0,
        'width': 14.0,
        'height': 14.0,
      }));
      // Draw the tail
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 17.0, 'y': y + 8.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 19.0,
        'controlY': y + 24.0,
        'endX': x + 17.0,
        'endY': y + 11.0,
      }));
      break;
    case 'b':
      // Draw the vertical stem of the 'b'
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 5.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw the bowl on the right side
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 12.0,
        'centerY': y + 8.0,
        'width': 14.0,
        'height': 14.0,
      }));
      break;
    case 'c':
      // Custom drawing for lowercase 'c' with more pronounced end curves
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 18.0, 'y': y + 1.0}));
      // Top curve with more pronounced hook
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 12.0,
        'controlY1': y + 1.0,
        'controlX2': x + 5.0,
        'controlY2': y + 1.0,
        'endX': x + 5.0,
        'endY': y + 8.0,
      }));
      // Bottom curve with more pronounced hook
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 5.0,
        'controlY1': y + 15.0,
        'controlX2': x + 12.0,
        'controlY2': y + 15.0,
        'endX': x + 18.0,
        'endY': y + 15.0,
      }));
      break;
    case 'd':
      // Draw the bowl for the 'd' on the left side
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 13.0,
        'centerY': y + 8.0,
        'width': 14.0,
        'height': 14.0
      }));
      // Draw the vertical stem on the right side
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 20.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 20.0, 'y': y + 15.0}));
      break;
    case 'e':
      // Start at the right side of the top curve
      commands.add(DrawingCommand(
          type: 'moveTo',
          params: {'x': x + 18.0, 'y': y + 8.0})); // Up from y + 10.0

      // Draw top half of 'e' - curves from right to left
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 18.0,
        'controlY1': y - 1.0, // Up from y + 1.0
        'controlX2': x + 3.0,
        'controlY2': y - 1.0, // Up from y + 1.0
        'endX': x + 3.0,
        'endY': y + 8.0, // Up from y + 10.0
      }));

      // Draw bottom half of 'e' - curves back from left to right
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 3.0,
        'controlY1': y + 17.0, // Up from y + 19.0
        'controlX2': x + 18.0,
        'controlY2': y + 17.0, // Up from y + 19.0
        'endX': x + 17.0,
        'endY': y + 11.0, // Up from y + 13.0
      }));

      // Add the middle horizontal line that characterizes the 'e'
      commands.add(DrawingCommand(
          type: 'moveTo',
          params: {'x': x + 3.0, 'y': y + 8.0})); // Up from y + 10.0
      commands.add(DrawingCommand(
          type: 'lineTo',
          params: {'x': x + 18.0, 'y': y + 8.0})); // Up from y + 10.0
      break;
    case 'f':
      // Draw the top curve starting from left edge
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 8.0, 'y': y - 4.0}));
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 8.0,
        'controlY1': y - 10.0,
        'controlX2': x + 17.0,
        'controlY2': y - 12.0,
        'endX': x + 17.0,
        'endY': y - 4.0,
      }));

      // Draw the vertical stem
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 8.0, 'y': y - 4.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 8.0, 'y': y + 16.0}));

      // Draw the crossbar
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 2.0, 'y': y + 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 14.0, 'y': y + 3.0}));
      break;
    case 'g':
      // Draw the circular bowl
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 8.0,
        'width': 13.0,
        'height': 13.0
      }));
      // Draw the descender tail
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 17.0, 'y': y + 8.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 20.0,
        'controlY': y + 30.0,
        'endX': x + 5.0,
        'endY': y + 25.0
      }));
      break;

    case 'h':
      // Draw the vertical stem
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 5.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw the arch
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 16.0,
        'controlY': y,
        'endX': x + 15.0,
        'endY': y + 15.0
      }));
      break;

    case 'i':
      // Draw the vertical stroke
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 10.0, 'y': y - 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));
      // Draw the dot
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y - 10.0,
        'width': 4.0,
        'height': 4.0
      }));
      break;

    case 'j':
      // Draw the vertical stem (starting lower)
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 10.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));

      // Draw the bottom curve (similar to 'e' curve but inverted)
      commands.add(DrawingCommand(type: 'cubicTo', params: {
        'controlX1': x + 10.0, // First control point X - starts at stem
        'controlY1': y + 19.0, // First control point Y - pulls curve down
        'controlX2': x + 2.0, // Second control point X - pulls left
        'controlY2': y + 19.0, // Second control point Y - keeps curve smooth
        'endX': x + 2.0, // End point X - ends at left
        'endY': y + 15.0, // End point Y - curves back up slightly
      }));

      // Draw the dot
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y - 7.0,
        'width': 4.0,
        'height': 4.0
      }));
      break;

    case 'k':
      // Draw the vertical stem
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 5.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw the upper angled arm
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y + 4.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 12.0, 'y': y - 5.0}));
      // Draw the lower angled arm
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y + 4.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y + 15.0}));
      break;

    case 'l':
      // Simple vertical stroke
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 10.0, 'y': y - 10.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));
      break;

    case 'm':
      // Draw the vertical stem
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y - 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw first hump
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 10.0,
        'controlY': y,
        'endX': x + 12.0,
        'endY': y + 3.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 14.0,
        'controlY': y + 6.0,
        'endX': x + 15.0,
        'endY': y + 15.0
      }));
      // Draw second hump
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 12.0, 'y': y + 3.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 17.0,
        'controlY': y,
        'endX': x + 19.0,
        'endY': y + 3.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 21.0,
        'controlY': y + 6.0,
        'endX': x + 22.0,
        'endY': y + 15.0
      }));
      break;

    case 'n':
      // Draw the vertical stem
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y - 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw the arch
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 16.0,
        'controlY': y,
        'endX': x + 15.0,
        'endY': y + 15.0
      }));
      break;

    case 'o':
      // Perfect circle (matching 'a' dimensions)
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 9.0, // Matched to 'a' circle position
        'width': 14.0, // Matched to 'a' circle width
        'height': 14.0, // Matched to 'a' circle height
      }));
      break;

    case 'p':
      // Draw the vertical stem
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 25.0}));
      // Draw the bowl
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 12.0,
        'centerY': y + 8.0,
        'width': 14.0,
        'height': 14.0
      }));
      break;

    case 'q':
      // Draw the bowl on the left side
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 8.0,
        'centerY': y + 8.0,
        'width': 14.0,
        'height': 14.0
      }));
      // Draw the vertical stem on the right, starting slightly lower
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 15.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y + 25.0}));
      break;

    case 'r':
      // Draw the vertical stem
      commands.add(
          DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y - 3.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 15.0}));
      // Draw the small arch
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 12.0,
        'controlY': y,
        'endX': x + 15.0,
        'endY': y + 5.0
      }));
      break;

    case 's':
      // Draw the top curve
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 13.0, 'y': y}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 13.0,
        'controlY': y - 3.0,
        'endX': x + 8.0,
        'endY': y - 3.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 4.0,
        'controlY': y - 3.0,
        'endX': x + 4.0,
        'endY': y + 2.0
      }));
      // Draw the middle connecting curve
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 4.0,
        'controlY': y + 7.0,
        'endX': x + 8.0,
        'endY': y + 7.0
      }));
      // Draw the bottom curve with matching curvature to top
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 13.0,
        'controlY': y + 7.0,
        'endX': x + 13.0,
        'endY': y + 12.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 13.0,
        'controlY': y + 15.0,
        'endX': x + 8.0,
        'endY': y + 15.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 4.0,
        'controlY': y + 15.0,
        'endX': x + 4.0,
        'endY': y + 12.0
      }));
      break;

    case 't':
      // Draw the vertical stem
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 10.0, 'y': y - 10.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 10.0, 'y': y + 15.0}));
      // Draw the crossbar
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 15.0, 'y': y}));
      break;

    case 'u':
      // Draw the left stem
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 12.0}));
      // Draw the curved bottom
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 10.0,
        'controlY': y + 17.0,
        'endX': x + 15.0,
        'endY': y + 12.0
      }));
      // Draw the right stem
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 15.0, 'y': y}));
      break;

    case 'v':
      // Simple angled strokes, slightly shorter
      commands.add(DrawingCommand(
          type: 'moveTo',
          params: {'x': x + 5.0, 'y': y})); // Raised from y - 3.0
      commands.add(DrawingCommand(
          type: 'lineTo',
          params: {'x': x + 10.0, 'y': y + 12.0})); // Reduced from y + 15.0
      commands.add(DrawingCommand(
          type: 'lineTo',
          params: {'x': x + 15.0, 'y': y})); // Raised from y - 3.0
      break;

    case 'w':
      // First V shape, slightly shorter
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 3.0, 'y': y}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 8.0, 'y': y + 12.0}));
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 13.0, 'y': y + 3.0}));
      // Second V shape
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 18.0, 'y': y + 12.0}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 23.0, 'y': y}));
      break;

    case 'y':
      // Draw the right stem and tail (shorter)
      commands.add(DrawingCommand(
          type: 'moveTo',
          params: {'x': x + 15.0, 'y': y})); // Raised from y - 3.0
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 15.0,
        'controlY': y + 18.0, // Reduced from y + 20.0
        'endX': x + 5.0,
        'endY': y + 22.0 // Reduced from y + 25.0
      }));
      // Draw the left stem with curved connection (shorter)
      commands.add(DrawingCommand(
          type: 'moveTo',
          params: {'x': x + 5.0, 'y': y})); // Raised from y - 3.0
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 10.0,
        'controlY': y + 10.0, // Reduced from y + 12.0
        'endX': x + 15.0,
        'endY': y + 10.0 // Reduced from y + 12.0
      }));
      break;

    case 'z':
      // Top horizontal line
      commands
          .add(DrawingCommand(type: 'moveTo', params: {'x': x + 5.0, 'y': y}));
      commands
          .add(DrawingCommand(type: 'lineTo', params: {'x': x + 15.0, 'y': y}));
      // Diagonal line
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 5.0, 'y': y + 14.0}));
      // Bottom horizontal line
      commands.add(DrawingCommand(
          type: 'lineTo', params: {'x': x + 15.0, 'y': y + 14.0}));
      break;

    case '?':
      // Draw the top curve
      commands.add(DrawingCommand(
          type: 'moveTo', params: {'x': x + 5.0, 'y': y - 15.0}));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 5.0,
        'controlY': y - 20.0,
        'endX': x + 10.0,
        'endY': y - 20.0
      }));
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 15.0,
        'controlY': y - 20.0,
        'endX': x + 15.0,
        'endY': y - 15.0
      }));

      // Draw the curved stem
      commands.add(DrawingCommand(type: 'quadraticBezierTo', params: {
        'controlX': x + 15.0,
        'controlY': y - 10.0,
        'endX': x + 10.0,
        'endY': y - 5.0
      }));

      // Draw the dot
      commands.add(DrawingCommand(type: 'addOval', params: {
        'centerX': x + 10.0,
        'centerY': y + 10.0,
        'width': 4.0,
        'height': 4.0
      }));
      break;
  }

  return commands;
}
