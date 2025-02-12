import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/drawing_command.dart';

class WhiteboardScreen extends StatefulWidget {
  final List<DrawingCommand>? drawingCommands;
  final String? text;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const WhiteboardScreen({
    super.key,
    this.drawingCommands,
    this.text,
    this.duration = const Duration(seconds: 2),
    this.onAnimationComplete,
  });

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Path> _paths = [];
  final List<double> _pathLengths = [];
  double _totalLength = 0;
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.text ??
        "abcdefghijk\n"
            "lmnopqrstuvwxyz";

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    if (widget.drawingCommands != null) {
      _initializeFromCommands();
    } else {
      _initializePaths();
    }

    _controller.forward();

    if (widget.onAnimationComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete!();
        }
      });
    }
  }

  void _initializeFromCommands() {
    if (widget.drawingCommands == null) return;

    double x = 50;
    double y = 200;

    for (final command in widget.drawingCommands!) {
      final path = Path();

      switch (command.type) {
        case 'moveTo':
          final params = command.params;
          path.moveTo(params['x'].toDouble(), params['y'].toDouble());
          break;
        case 'lineTo':
          final params = command.params;
          path.lineTo(params['x'].toDouble(), params['y'].toDouble());
          break;
        case 'quadraticBezierTo':
          final params = command.params;
          path.quadraticBezierTo(
            params['controlX'].toDouble(),
            params['controlY'].toDouble(),
            params['endX'].toDouble(),
            params['endY'].toDouble(),
          );
          break;
        // Add more command types as needed
      }

      _paths.add(path);
      final length = _computePathLength(path);
      _pathLengths.add(length);
      _totalLength += length;
    }
  }

  void _initializePaths() {
    // Create paths for each character/symbol in the equation
    final characters = _text.split('');
    double x = 50; // Starting x position
    double y = 200; // Vertical position

    for (var char in characters) {
      final path = Path();
      switch (char) {
        case '1':
          path.moveTo(x + 2, y - 13); // Start from top-left, slightly lower
          path.lineTo(x + 10, y - 15); // Angle up to top of stem
          path.lineTo(x + 10, y + 15); // Vertical line straight down
          path.lineTo(x, y + 15); // Base left
          path.lineTo(x + 20, y + 15); // Base right
          x += 20;
          break;
        case '2':
          path.moveTo(x + 3, y - 15); // Start more left
          path.quadraticBezierTo(
              x + 20, y - 15, x + 15, y); // Top curve (peaks left)
          path.quadraticBezierTo(
              x + 12, y + 10, x, y + 15); // Bottom curve (more open in middle)
          path.lineTo(x + 17, y + 15); // Bottom line (aligned with "1")
          x += 20;
          break;
        case '3':
          path.moveTo(x + 2, y - 15); // Start top left
          path.quadraticBezierTo(
              x + 18, y - 15, x + 16, y - 8); // Top bowl curves right
          path.quadraticBezierTo(x + 14, y - 2, x + 8,
              y); // Connect to middle point, much more left
          path.quadraticBezierTo(
              x + 14, y + 2, x + 16, y + 8); // Start of bottom bowl
          path.quadraticBezierTo(
              x + 18, y + 15, x + 2, y + 15); // Bottom bowl curves back left
          x += 20;
          break;
        case '4':
          path.moveTo(x + 15, y + 15); // Bottom of vertical
          path.lineTo(x + 15, y - 15); // Up vertical
          path.lineTo(x + 3, y + 5); // Diagonal to left (moved in from x)
          path.lineTo(x + 20, y + 5); // Horizontal line
          x += 20;
          break;
        case '5':
          path.moveTo(x + 16, y - 15); // Top right (back to original)
          path.lineTo(x, y - 15); // Top left (back to original)
          path.lineTo(x, y - 5); // Down vertical (shorter)
          path.quadraticBezierTo(
              x + 15, y, x + 15, y + 5); // Bottom curve start
          path.quadraticBezierTo(x + 15, y + 15, x, y + 15); // Bottom curve end
          x += 20;
          break;
        case '6':
          // Calculate relative dimensions for the 6
          final width = 20.0; // Base width for the number
          final height = 30.0; // Base height for the number

          // Top curve of 6 - extends further and curves down more
          path.moveTo(x + width / 1.2, y - height / 2); // Start further right
          path.cubicTo(
              x + width / 2 + 12,
              y - height / 2 - 5, // First control point, higher
              x + width / 5,
              y - height / 4, // Second control point, more left
              x + width / 6,
              y + height / 6 // End point, much higher to cut off more bottom
              );

          // Bottom circle of 6
          path.addArc(
              Rect.fromCenter(
                  center: Offset(x + width / 2 + 2, y + height / 6),
                  width: width / 1.2,
                  height: width / 1.2),
              math.pi,
              2 * math.pi);

          x += width + 5;
          break;
        case '7':
          path.moveTo(x, y - 15); // Start top left
          path.lineTo(x + 20, y - 15); // Top horizontal
          path.lineTo(x + 10, y + 15); // Angled stem aligned with other numbers
          x += 20;
          break;
        case '8':
          // Top loop (smaller)
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 8),
            width: 14,
            height: 14,
          ));
          // Bottom loop (slightly larger and wider)
          path.addOval(Rect.fromCenter(
            center:
                Offset(x + 10, y + 7), // Moved down slightly to extend bottom
            width: 16,
            height: 14, // Made taller
          ));
          x += 20;
          break;
        case '9':
          // Top circle - slightly oval
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 8),
            width: 16,
            height: 14,
          ));

          // Straight stem
          path.moveTo(x + 18, y - 8); // Start from medium height on the circle
          path.lineTo(x + 18, y + 15); // Straight down to baseline
          x += 20;
          break;
        case '0':
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y),
            width: 20,
            height: 30,
          ));
          x += 20;
          break;
        case 'x':
          // Drawing for lowercase 'x' with two crossing lines at x-height
          path.moveTo(x + 5, y);
          path.lineTo(x + 15, y + 14); // Reduced height difference
          path.moveTo(x + 15, y);
          path.lineTo(x + 5, y + 14); // Reduced height difference
          x += 20;
          break;
        case '+':
          path.moveTo(x + 10, y - 10);
          path.lineTo(x + 10, y + 10);
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          x += 20;
          break;
        case '-':
          path.moveTo(x, y);
          path.lineTo(x + 15, y); // Made less wide
          x += 20;
          break;
        case '=':
          path.moveTo(x, y - 3); // Top line, closer to middle
          path.lineTo(x + 20, y - 3);
          path.moveTo(x, y + 3); // Bottom line, closer to middle
          path.lineTo(x + 20, y + 3);
          x += 20;
          break;
        case '×':
          // First diagonal (top-left to bottom-right)
          path.moveTo(x + 5, y - 5);
          path.lineTo(x + 15, y + 5);
          // Second diagonal (top-right to bottom-left)
          path.moveTo(x + 15, y - 5);
          path.lineTo(x + 5, y + 5);
          x += 20;
          break;
        case '÷':
          path.moveTo(x, y);
          path.lineTo(x + 20, y);
          // Top dot closer to line
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y - 5),
            width: 3,
            height: 3,
          ));
          // Bottom dot closer to line
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 5),
            width: 3,
            height: 3,
          ));
          x += 20;
          break;
        case '^':
          path.moveTo(x, y);
          path.lineTo(x + 5, y - 10);
          path.lineTo(x + 10, y);
          x += 15;
          break;
        case '(':
          // Left parenthesis with natural curve
          path.moveTo(x + 10, y - 15);
          path.quadraticBezierTo(
              x + 2,
              y, // Control point
              x + 10,
              y + 15 // End point
              );
          x += 15;
          break;
        case ')':
          // Right parenthesis with natural curve
          path.moveTo(x + 5, y - 15);
          path.quadraticBezierTo(
              x + 13,
              y, // Control point
              x + 5,
              y + 15 // End point
              );
          x += 15;
          break;
        case '√':
          // Short, precise vincula at top
          path.moveTo(x + 2, y - 10);
          path.lineTo(x + 5, y - 10);

          // Graceful diagonal with slight curve
          path.quadraticBezierTo(
              x + 7,
              y - 8, // Control point to start curve
              x + 8,
              y - 5 // End of initial curve
              );

          // Main diagonal stroke
          path.quadraticBezierTo(
              x + 10,
              y + 3, // Control point for main descent
              x + 12,
              y + 5 // Where we start the bottom curve
              );

          // The beautiful asymptotic curve
          path.quadraticBezierTo(
              x + 14,
              y + 6, // Control point for transition
              x + 25,
              y + 6 // Extended end point with slight lift
              );
          x += 30;
          break;

        // New case for lowercase 'a'
        case 'a':
          // Custom drawing for lowercase 'a'
          // Draw the circular part of the lowercase 'a' at the same vertical level as 'b' and 'd'
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10,
                y + 5), // Center is now aligned with the bowls of 'b' and 'd'
            width: 16,
            height: 16,
          ));
          // Draw a shortened tail for the 'a'
          path.moveTo(x + 18, y + 5);
          path.quadraticBezierTo(
            x + 20, y + 25, // Control point for the tail curve (shorter)
            x + 18, y + 10, // End point for the tail curve (shorter)
          );
          x += 20;
          break;

        // New case for lowercase 'b'
        case 'b':
          // Custom drawing for lowercase 'b'
          // Draw the vertical stem of the 'b'
          path.moveTo(x + 5, y - 15);
          path.lineTo(x + 5, y + 15);
          // Draw the bowl on the right side, now merged with the stem and lowered a tad
          // Setting center x to 12 ensures the bowl's left edge meets the stem (5 + 7 = 12)
          path.addOval(Rect.fromCenter(
            center: Offset(x + 12, y + 8), // Lowered compared to before
            width: 14,
            height: 14,
          ));
          x += 20;
          break;

        // New case for lowercase 'c' with more pronounced end curves
        case 'c':
          // Custom drawing for lowercase 'c' with more pronounced end curves
          path.moveTo(x + 18, y + 1); // shifted down by 3 from y-2
          // Top curve with more pronounced hook
          path.cubicTo(
            x + 12, y + 1, // First control point - shifted down
            x + 5, y + 1, // Second control point - shifted down
            x + 5, y + 8, // End point - shifted down
          );
          // Bottom curve with more pronounced hook
          path.cubicTo(
            x + 5, y + 15, // First control point - shifted down
            x + 12, y + 15, // Second control point - shifted down
            x + 18, y + 15, // End point - shifted down
          );
          x += 20;
          break;

        // New case for lowercase 'd'
        case 'd':
          // Custom drawing for lowercase 'd'
          // Draw the bowl for the 'd' on the left side, now merged with the stem and lowered a tad
          // Setting center x to 13 ensures the bowl's right edge meets the stem (13 + 7 = 20)
          path.addOval(Rect.fromCenter(
            center: Offset(x + 13, y + 8), // Lowered compared to before
            width: 14,
            height: 14,
          ));
          // Draw the vertical stem on the right side, mirroring the 'b' stroke
          path.moveTo(x + 20, y - 15);
          path.lineTo(x + 20, y + 15);
          x += 30;
          break;

        case 'e':
          // For easy adjustments, define a radius (r).
          // Adjust as needed to match your other letters in size/position.
          final double r = 7.5;

          // We'll define two bounding boxes:
          //  - one for the top half-circle
          //  - one for the bottom (partial) circle
          // Each box is 2*r wide/high, starting at (x, y) for the top and
          // (x, y + 2*r) for the bottom so they stack vertically.

          Rect topBox = Rect.fromLTWH(x, y, 2 * r, 2 * r);
          Rect bottomBox = Rect.fromLTWH(x, y, 2 * r, 2 * r);

          // 1) Draw the TOP half circle.
          //
          //    We'll start at π (180°) and sweep +π (180°) to get a clockwise top arch
          //    from left to right. If you want the arc reversed, flip signs or angles:
          //
          //    - Start angle: math.pi means "left side" of the circle
          //    - Sweep angle: math.pi (positive) means 180° in the clockwise direction
          //
          //    NOTE: addArc jumps to the start-angle automatically.
          path.addArc(topBox, math.pi, math.pi);

          // 2) Draw the HORIZONTAL LINE (the crossbar).
          //
          //    After the top arc, our path is at the circle's right edge (x + 2*r, y + r).
          //    We move further to the right for a short crossbar.
          path.lineTo(x - 1.6 * r + 16, y + r);

          // 3) Draw the BOTTOM partial circle, but only ~150 degrees so it's "cut off" on the right.
          //
          //    - Start angle: math.pi means start on the left side of bottomBox
          //    - Sweep angle: 5*math.pi/6 is ~150° (in radians)
          //
          //    This will not complete the full half-circle, ending short on the right side.
          path.addArc(bottomBox, math.pi, (-1) * 5 * math.pi / 6);

          // Move 'pen' so the next character won't overlap.
          x += 20;
          break;

        // New case for lowercase 'f'
        case 'f':
          // Drawing for lowercase 'f' with a curved top and vertical stem
          path.moveTo(x + 12, y - 15);
          // Add the curved top arc
          path.addArc(
            Rect.fromCenter(
              center: Offset(x + 17, y - 15),
              width: 10,
              height: 10,
            ),
            math.pi,
            math.pi,
          );
          // Continue with the vertical stem
          path.moveTo(x + 12, y - 15);
          path.lineTo(x + 12, y + 15);
          // Draw the crossbar
          path.moveTo(x + 5, y - 5);
          path.lineTo(x + 19, y - 5);
          x += 20;
          break;

        // New case for lowercase 'g'
        case 'g':
          // Drawing for lowercase 'g' featuring a circular bowl and a descender tail.
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 8),
            width: 13,
            height: 13,
          ));
          // Draw a tail that descends below the baseline to give 'g' its characteristic shape.
          path.moveTo(x + 17, y + 8);
          path.quadraticBezierTo(
            x + 20, y + 30, // Control point deepening the descender
            x + 5, y + 25, // End point which sits below the normal bottom line
          );
          x += 25;
          break;

        // New case for lowercase 'h'
        case 'h':
          // Drawing for lowercase 'h' with a vertical stem and a gentle curved arch.
          // Draw the vertical stem on the left.
          path.moveTo(x + 5, y - 15);
          path.lineTo(x + 5, y + 15);
          // Draw an arch from the mid-line curving out to the right before joining the bottom.
          path.moveTo(x + 5, y);
          path.quadraticBezierTo(
            x + 16, y, // Control point creating the arch
            x + 15, y + 15, // Ends at the bottom right of the letter
          );
          x += 20;
          break;

        // New case for lowercase 'i'
        case 'i':
          // Drawing for lowercase 'i' with a vertical stroke and a dot above.
          // Draw the vertical stroke centered horizontally.
          path.moveTo(x + 10, y - 3);
          path.lineTo(x + 10, y + 15);
          // Draw the dot above the stroke.
          path.addOval(Rect.fromCircle(
            center: Offset(x + 10, y - 10),
            radius: 2,
          ));
          x += 20;
          break;

        // New case for lowercase 'j'
        case 'j':
          // Drawing for lowercase 'j' with a vertical stroke, a dot above, and a descender tail.
          path.moveTo(x + 10, y - 3); // Match 'i' stem start
          path.lineTo(x + 10, y + 15); // Match 'i' stem end
          // Draw the dot above the stroke, matching 'i' dot position
          path.addOval(Rect.fromCircle(
            center: Offset(x + 10, y - 10), // Match 'i' dot position
            radius: 2,
          ));
          // Draw the bottom arc similar to 'f' top arc but inverted
          path.addArc(
            Rect.fromCenter(
              center: Offset(x + 5, y + 15),
              width: 10,
              height: 10,
            ),
            0,
            math.pi,
          );
          x += 20;
          break;

        // New case for lowercase 'k'
        case 'k':
          // Drawing for lowercase 'k' with a vertical stem and two angled arms.
          // Draw the vertical stem on the left.
          path.moveTo(x + 5, y - 15);
          path.lineTo(x + 5, y + 15);
          // Draw the upper angled arm.
          path.moveTo(x + 5, y + 4);
          path.lineTo(x + 12, y - 5);
          // Draw the lower angled arm.
          path.moveTo(x + 5, y + 4);
          path.lineTo(x + 15, y + 15);
          x += 15;
          break;
        case 'l':
          // Drawing for lowercase 'l' with a simple vertical stroke
          path.moveTo(x + 10, y - 10); // Reduced height from -15
          path.lineTo(x + 10, y + 15);
          x += 12;
          break;

        // New case for lowercase 'm'
        case 'm':
          // Drawing for lowercase 'm' with vertical stem and two connected humps
          // Draw the vertical stem on the left
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 5, y + 15);
          // Draw first hump, starting from the stem
          path.moveTo(x + 5, y);
          path.quadraticBezierTo(
            x + 10, y, // Control point for first rise
            x + 12, y + 3, // Peak of first hump
          );
          path.quadraticBezierTo(
            x + 14, y + 6, // Control point for first descent
            x + 15, y + 15, // Bottom of first hump
          );
          // Draw second hump, continuing from the first
          path.moveTo(x + 12, y + 3); // Start from peak of first hump
          path.quadraticBezierTo(
            x + 17, y, // Control point for second rise
            x + 19, y + 3, // Peak of second hump
          );
          path.quadraticBezierTo(
            x + 21, y + 6, // Control point for second descent
            x + 22, y + 15, // Bottom of second hump
          );
          x += 25;
          break;

        // New case for lowercase 'n'
        case 'n':
          // Drawing for lowercase 'n' with vertical stem and one arch
          // Draw the vertical stem on the left
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 5, y + 15);
          // Draw the arch
          path.moveTo(x + 5, y);
          path.quadraticBezierTo(
            x + 16, y, // Control point creating the arch
            x + 15, y + 15, // Ends at the bottom right of the letter
          );
          x += 20;
          break;

        // New case for lowercase 'o'
        case 'o':
          // Drawing for lowercase 'o' with a perfect circle
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 8),
            width: 16,
            height: 16,
          ));
          x += 20;
          break;

        // New case for lowercase 'p'
        case 'p':
          // Drawing for lowercase 'p' with stem and bowl, descending below baseline
          // Draw the vertical stem, starting slightly lower
          path.moveTo(x + 5, y); // Changed from y - 3 to y
          path.lineTo(x + 5, y + 25);
          // Draw the bowl on the right side
          path.addOval(Rect.fromCenter(
            center: Offset(x + 12, y + 8),
            width: 14,
            height: 14,
          ));
          x += 25;
          break;

        // New case for lowercase 'q'
        case 'q':
          // Drawing for lowercase 'q', mirroring 'p' but with tail on right
          // Draw the bowl on the left side
          path.addOval(Rect.fromCenter(
            center: Offset(x + 8, y + 8),
            width: 14,
            height: 14,
          ));
          // Draw the vertical stem on the right, starting slightly lower
          path.moveTo(x + 15, y); // Changed from y - 3 to y
          path.lineTo(x + 15, y + 25);
          x += 20;
          break;

        // New case for lowercase 'r'
        case 'r':
          // Drawing for lowercase 'r' with stem and small arch
          // Draw the vertical stem
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 5, y + 15);
          // Draw the small arch
          path.moveTo(x + 5, y);
          path.quadraticBezierTo(
            x + 12, y, // Control point for arch
            x + 15, y + 5, // End point curves up slightly
          );
          x += 20;
          break;

        // New case for lowercase 's'
        case 's':
          // Drawing for lowercase 's' with a perfect circle
          path.addOval(Rect.fromCenter(
            center: Offset(x + 10, y + 8),
            width: 16,
            height: 16,
          ));
          x += 20;
          break;

        // New case for lowercase 't'
        case 't':
          // Drawing for lowercase 't' with vertical stem and crossbar
          // Draw the vertical stem
          path.moveTo(x + 10, y - 15);
          path.lineTo(x + 10, y + 15);
          // Draw the crossbar
          path.moveTo(x + 4, y);
          path.lineTo(x + 16, y);
          x += 20;
          break;

        // New case for lowercase 'u'
        case 'u':
          // Drawing for lowercase 'u' with two stems and connecting curve
          // Left stem
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 5, y + 10);
          // Curved bottom
          path.quadraticBezierTo(
            x + 10, y + 15, // Control point
            x + 15, y + 10, // End point
          );
          // Right stem
          path.lineTo(x + 15, y - 3);
          x += 20;
          break;

        // New case for lowercase 'v'
        case 'v':
          // Drawing for lowercase 'v' with two angled lines
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 10, y + 15);
          path.lineTo(x + 15, y - 3);
          x += 20;
          break;

        // New case for lowercase 'w'
        case 'w':
          // Drawing for lowercase 'w' with four angled lines
          path.moveTo(x + 3, y - 3);
          path.lineTo(x + 8, y + 15);
          path.lineTo(x + 13, y - 3);
          path.lineTo(x + 18, y + 15);
          path.lineTo(x + 23, y - 3);
          x += 25;
          break;

        // New case for lowercase 'y'
        case 'y':
          // Drawing for lowercase 'y' with two lines, one descending
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 10, y + 15);
          path.moveTo(x + 15, y - 3);
          path.lineTo(x + 5, y + 25);
          x += 20;
          break;

        // New case for lowercase 'z'
        case 'z':
          // Drawing for lowercase 'z' with top line, diagonal, and bottom line
          path.moveTo(x + 5, y - 3);
          path.lineTo(x + 15, y - 3);
          path.lineTo(x + 5, y + 15);
          path.lineTo(x + 15, y + 15);
          x += 20;
          break;

        case '\n':
          y += 50;
          x = 50;
          break;
        case ' ':
          x += 10;
          break;
        default:
          // For numbers longer than 1 digit
          if (char.length > 1) {
            for (var digit in char.split('')) {
              final digitPath = Path();
              switch (digit) {
                case '1':
                  digitPath.moveTo(
                      x + 2, y - 13); // Start from top-left, slightly lower
                  digitPath.lineTo(x + 10, y - 15); // Angle up to top of stem
                  digitPath.lineTo(
                      x + 10, y + 15); // Vertical line straight down
                  digitPath.lineTo(x, y + 15); // Base left
                  digitPath.lineTo(x + 20, y + 15); // Base right
                  break;
                case '2':
                  digitPath.moveTo(x + 3, y - 15); // Start more left
                  digitPath.quadraticBezierTo(
                      x + 20, y - 15, x + 15, y); // Top curve (peaks left)
                  digitPath.quadraticBezierTo(x + 12, y + 10, x,
                      y + 15); // Bottom curve (more open in middle)
                  digitPath.lineTo(
                      x + 17, y + 15); // Bottom line (aligned with "1")
                  break;
                case '3':
                  digitPath.moveTo(x + 2, y - 15); // Start top left
                  digitPath.quadraticBezierTo(
                      x + 18, y - 15, x + 16, y - 8); // Top bowl curves right
                  digitPath.quadraticBezierTo(x + 14, y - 2, x + 8,
                      y); // Connect to middle point, much more left
                  digitPath.quadraticBezierTo(
                      x + 14, y + 2, x + 16, y + 8); // Start of bottom bowl
                  digitPath.quadraticBezierTo(x + 18, y + 15, x + 2,
                      y + 15); // Bottom bowl curves back left
                  break;
                case '4':
                  digitPath.moveTo(x + 15, y + 15); // Bottom of vertical
                  digitPath.lineTo(x + 15, y - 15); // Up vertical
                  digitPath.lineTo(
                      x + 3, y + 5); // Diagonal to left (moved in from x)
                  digitPath.lineTo(x + 20, y + 5); // Horizontal line
                  break;
                case '5':
                  digitPath.moveTo(
                      x + 16, y - 15); // Top right (back to original)
                  digitPath.lineTo(x, y - 15); // Top left (back to original)
                  digitPath.lineTo(x, y - 5); // Down vertical (shorter)
                  digitPath.quadraticBezierTo(
                      x + 15, y, x + 15, y + 5); // Bottom curve start
                  digitPath.quadraticBezierTo(
                      x + 15, y + 15, x, y + 15); // Bottom curve end
                  break;
                case '6':
                  // Calculate relative dimensions for the 6
                  final width = 20.0;
                  final height = 30.0;

                  digitPath.moveTo(
                      x + width / 1.2, y - height / 2); // Start further right
                  digitPath.cubicTo(
                      x + width / 2 + 12,
                      y - height / 2 - 5,
                      x + width / 5,
                      y - height / 5.5,
                      x + width / 6,
                      y + height / 5.5);

                  digitPath.addArc(
                      Rect.fromCenter(
                          center: Offset(x + width / 2 + 2, y + height / 6),
                          width: width / 1.2,
                          height: width / 1.2),
                      math.pi,
                      2 * math.pi);
                  break;
                case '7':
                  digitPath.moveTo(x, y - 15); // Start top left
                  digitPath.lineTo(x + 20, y - 15); // Top horizontal
                  digitPath.lineTo(
                      x + 10, y + 15); // Angled stem aligned with other numbers
                  break;
                case '8':
                  // Top loop (smaller)
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y - 8),
                    width: 14,
                    height: 14,
                  ));
                  // Bottom loop (slightly larger and wider)
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(
                        x + 10, y + 7), // Moved down slightly to extend bottom
                    width: 16,
                    height: 14, // Made taller
                  ));
                  break;
                case '9':
                  // Top circle - slightly oval
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y - 8),
                    width: 16,
                    height: 14,
                  ));

                  // Straight stem
                  digitPath.moveTo(
                      x + 18, y - 8); // Start from medium height on the circle
                  digitPath.lineTo(x + 18, y + 15); // Straight down to baseline
                  break;
                case '0':
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y),
                    width: 20,
                    height: 30,
                  ));
                  break;
                case '+':
                  digitPath.moveTo(x + 10, y - 10);
                  digitPath.lineTo(x + 10, y + 10);
                  digitPath.moveTo(x, y);
                  digitPath.lineTo(x + 20, y);
                  break;
                case '-':
                  digitPath.moveTo(x, y);
                  digitPath.lineTo(x + 15, y); // Made less wide
                  break;
                case '=':
                  digitPath.moveTo(x, y - 3); // Top line, closer to middle
                  digitPath.lineTo(x + 20, y - 3);
                  digitPath.moveTo(x, y + 3); // Bottom line, closer to middle
                  digitPath.lineTo(x + 20, y + 3);
                  break;
                case '÷':
                  digitPath.moveTo(x, y);
                  digitPath.lineTo(x + 20, y);
                  // Top dot closer to line
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y - 5),
                    width: 3,
                    height: 3,
                  ));
                  // Bottom dot closer to line
                  digitPath.addOval(Rect.fromCenter(
                    center: Offset(x + 10, y + 5),
                    width: 3,
                    height: 3,
                  ));
                  break;
                case '(':
                  // Left parenthesis with natural curve
                  digitPath.moveTo(x + 10, y - 15);
                  digitPath.quadraticBezierTo(
                      x + 2,
                      y, // Control point
                      x + 10,
                      y + 15 // End point
                      );
                  break;
                case ')':
                  // Right parenthesis with natural curve
                  digitPath.moveTo(x + 5, y - 15);
                  digitPath.quadraticBezierTo(
                      x + 13,
                      y, // Control point
                      x + 5,
                      y + 15 // End point
                      );
                  break;
                case '√':
                  // Short, precise vincula at top
                  digitPath.moveTo(x + 2, y - 10);
                  digitPath.lineTo(x + 5, y - 10);

                  // Graceful diagonal with slight curve
                  digitPath.quadraticBezierTo(
                      x + 7,
                      y - 8, // Control point to start curve
                      x + 8,
                      y - 5 // End of initial curve
                      );

                  // Main diagonal stroke
                  digitPath.quadraticBezierTo(
                      x + 10,
                      y + 3, // Control point for main descent
                      x + 12,
                      y + 5 // Where we start the bottom curve
                      );

                  // The beautiful asymptotic curve
                  digitPath.quadraticBezierTo(
                      x + 14,
                      y + 6, // Control point for transition
                      x + 25,
                      y + 6 // Extended end point with slight lift
                      );
                  break;
                case '×':
                  // First diagonal (top-left to bottom-right)
                  digitPath.moveTo(x + 5, y - 5);
                  digitPath.lineTo(x + 15, y + 5);
                  // Second diagonal (top-right to bottom-left)
                  digitPath.moveTo(x + 15, y - 5);
                  digitPath.lineTo(x + 5, y + 5);
                  break;
              }
              _paths.add(digitPath);
              _pathLengths
                  .add(60); // Increased path length for more complex numbers
              _totalLength += 60;
              x += 20;
            }
          }
      }

      if (char != ' ' && char != '\n') {
        final pathMetrics = path.computeMetrics();
        double pathLength = 0;
        for (final metric in pathMetrics) {
          pathLength += metric.length;
        }
        if (pathLength > 0) {
          _paths.add(path);
          _pathLengths.add(pathLength);
          _totalLength += pathLength;
        }
      }
    }
  }

  double _computePathLength(Path path) {
    final pathMetrics = path.computeMetrics();
    double pathLength = 0;
    for (final metric in pathMetrics) {
      pathLength += metric.length;
    }
    return pathLength;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whiteboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () {
              _controller.reset();
              _controller.forward();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: EquationPainter(
              paths: _paths,
              pathLengths: _pathLengths,
              totalLength: _totalLength,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class EquationPainter extends CustomPainter {
  final List<Path> paths;
  final List<double> pathLengths;
  final double totalLength;
  final double progress;

  EquationPainter({
    required this.paths,
    required this.pathLengths,
    required this.totalLength,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double currentProgress = progress * totalLength;

    for (int i = 0; i < paths.length; i++) {
      if (currentProgress <= 0) break;

      final path = paths[i];
      final pathLength = pathLengths[i];

      final pathProgress = (currentProgress / pathLength).clamp(0.0, 1.0);

      if (pathProgress > 0) {
        final metrics = path.computeMetrics();
        for (final metric in metrics) {
          final extractPath = metric.extractPath(
            0,
            metric.length * pathProgress,
          );
          canvas.drawPath(extractPath, paint);
        }
      }

      currentProgress -= pathLength;
    }
  }

  @override
  bool shouldRepaint(covariant EquationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
