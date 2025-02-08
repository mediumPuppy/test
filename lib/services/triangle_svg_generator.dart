import 'dart:math';

/// A simple model representing a triangle with sides a, b, and c.
/// We define:
///   - a: side between vertices B and C
///   - b: side between vertices A and C
///   - c: side between vertices A and B
class Triangle {
  final double a, b, c;

  Triangle({required this.a, required this.b, required this.c});

  /// Check if the three sides can form a valid triangle.
  bool get isValid => a + b > c && a + c > b && b + c > a;

  /// Calculate the triangle's vertex coordinates.
  ///
  /// Places A = (0,0) and B = (c,0) along the x-axis.
  /// Computes C = (x, y) using the cosine law:
  ///   x = (b^2 + c^2 - a^2) / (2*c)
  ///   y = sqrt(b^2 - x^2)
  ///
  /// Returns a list of vertices: [A, B, C],
  /// where each vertex is a list of its [x, y] coordinates.
  List<List<double>> calculateVertices() {
    // Starting point A and B
    final A = [0.0, 0.0];
    final B = [c, 0.0];

    // Using the cosine law to determine coordinates for C.
    double x = (b * b + c * c - a * a) / (2 * c);
    double temp = b * b - x * x;
    double y = temp > 0 ? sqrt(temp) : 0.0;

    final C = [x, y];
    return [A, B, C];
  }
}

/// Generates an SVG string for the given triangle defined by side lengths a, b, and c.
/// The function computes the triangle's vertices, then constructs the SVG polygon.
/// It also annotates the vertices with labels A, B, and C.
String generateTriangleSvg(double a, double b, double c) {
  final triangle = Triangle(a: a, b: b, c: c);

  if (!triangle.isValid) {
    return '<svg xmlns="http://www.w3.org/2000/svg"><text x="10" y="20" fill="red">Invalid triangle sides provided</text></svg>';
  }

  // Calculate the vertices
  final vertices = triangle.calculateVertices();

  // Build the points attribute for the polygon element.
  final pointsAttribute =
      vertices.map((vertex) => '${vertex[0]},${vertex[1]}').join(' ');

  // Optionally, you could apply scale factors here if needed.
  // For this example, we assume that the triangle will fit into the viewBox.
  final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="-10 -20 ${c + 30} ${triangle.calculateVertices()[2][1] + 30}">
  <polygon points="$pointsAttribute" fill="none" stroke="black" stroke-width="2" stroke-dasharray="2000"/>
  <!-- Annotate vertices with a small offset -->
  <text x="${vertices[0][0] - 5}" y="${vertices[0][1] - 5}" font-size="12" fill="red">A</text>
  <text x="${vertices[1][0] + 5}" y="${vertices[1][1] - 5}" font-size="12" fill="red">B</text>
  <text x="${vertices[2][0] + 5}" y="${vertices[2][1] + 15}" font-size="12" fill="red">C</text>
</svg>
''';
  return svg;
}
