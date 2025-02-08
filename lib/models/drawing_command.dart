/// Represents a drawing command with a type and parameters
class DrawingCommand {
  /// The type of drawing command (e.g., 'moveTo', 'lineTo', 'quadraticBezierTo')
  final String type;

  /// Parameters for the drawing command (e.g., x, y coordinates)
  final Map<String, dynamic> params;

  const DrawingCommand({
    required this.type,
    required this.params,
  });
}
