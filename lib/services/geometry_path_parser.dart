// geometry_path_parser.dart
import 'package:flutter/material.dart';

class GeometryPathParser {
  /// Given a pathData string (e.g. "moveTo(10, 10) lineTo(100, 100) ..."),
  /// parse out commands and build a Flutter [Path].
  /// Supports moveTo, lineTo, quadraticBezierTo, cubicTo, arcTo, close, etc.
  static Path parse(String pathData) {
    final path = Path();

    // Updated regex to allow empty parentheses
    final commandPattern = RegExp(
        r'(moveTo|lineTo|quadraticBezierTo|cubicTo|arcTo|close)\([^)]*\)');

    final matches = commandPattern.allMatches(pathData);

    for (final match in matches) {
      final cmdString = match.group(0)!;

      if (cmdString.startsWith('moveTo')) {
        final coords = _parseCoordinates(cmdString);
        if (coords.length >= 2) {
          path.moveTo(coords[0], coords[1]);
        }
      } else if (cmdString.startsWith('lineTo')) {
        final coords = _parseCoordinates(cmdString);
        if (coords.length >= 2) {
          path.lineTo(coords[0], coords[1]);
        }
      } else if (cmdString.startsWith('quadraticBezierTo')) {
        final coords = _parseCoordinates(cmdString);
        if (coords.length >= 4) {
          path.quadraticBezierTo(coords[0], coords[1], coords[2], coords[3]);
        }
      } else if (cmdString.startsWith('cubicTo')) {
        final coords = _parseCoordinates(cmdString);
        if (coords.length >= 6) {
          path.cubicTo(
            coords[0],
            coords[1],
            coords[2],
            coords[3],
            coords[4],
            coords[5],
          );
        }
      } else if (cmdString.startsWith('arcTo')) {
        final coords = _parseCoordinates(cmdString);
        if (coords.length >= 7) {
          final arcRect = Rect.fromLTWH(
              coords[0] - coords[2] / 2, // Left = centerX - width/2
              coords[1] - coords[3] / 2, // Top = centerY - height/2
              coords[2], // Width
              coords[3] // Height
              );
          path.arcTo(
              arcRect,
              coords[4], // Start angle
              coords[5], // Sweep angle
              true // Changed to true to prevent connecting line
              );
        }
      } else if (cmdString.startsWith('close')) {
        path.close();
      }
    }

    return path;
  }

  /// Extracts the comma-separated numeric values inside parentheses:
  /// e.g. "moveTo(30, 100)" => [30.0, 100.0]
  static List<double> _parseCoordinates(String command) {
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(command);
    if (match == null) return [];

    final inner = match.group(1)!; // e.g. "30, 100" or "30,100,70,200" etc.
    return inner
        .split(',')
        .map((v) => double.tryParse(v.trim()) ?? 0.0)
        .toList();
  }
}
