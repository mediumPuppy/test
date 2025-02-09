import 'dart:ui';

/// Represents a point in 2D space
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };
}

/// Base class for all drawing elements
abstract class DrawingElement {
  final String type;
  final Map<String, dynamic> attributes;

  const DrawingElement({
    required this.type,
    required this.attributes,
  });

  factory DrawingElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final attributes = json['attributes'] as Map<String, dynamic>;

    switch (type) {
      case 'grid':
        return GridElement.fromJson(attributes);
      case 'axes':
        return AxesElement.fromJson(attributes);
      case 'line':
        return LineElement.fromJson(attributes);
      case 'slope_indicator':
        return SlopeIndicatorElement.fromJson(attributes);
      case 'label':
        return LabelElement.fromJson(attributes);
      default:
        throw ArgumentError('Unknown element type: $type');
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'attributes': attributes,
      };
}

/// Represents a grid element with customizable appearance
class GridElement extends DrawingElement {
  double get spacing => attributes['spacing'] as double;
  Color get color => Color(attributes['color'] as int);
  double get lineWidth => attributes['lineWidth'] as double;
  double get opacity => attributes['opacity'] as double;
  bool get isDashed => attributes['isDashed'] as bool;

  GridElement({
    required double spacing,
    required Color color,
    required double lineWidth,
    required double opacity,
    bool isDashed = false,
  }) : super(
          type: 'grid',
          attributes: {
            'spacing': spacing,
            'color': color.value,
            'lineWidth': lineWidth,
            'opacity': opacity,
            'isDashed': isDashed,
          },
        );

  factory GridElement.fromJson(Map<String, dynamic> json) {
    return GridElement(
      spacing: (json['spacing'] as num).toDouble(),
      color: Color(json['color'] as int),
      lineWidth: (json['lineWidth'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
      isDashed: json['isDashed'] as bool? ?? false,
    );
  }
}

/// Represents coordinate axes with optional arrowheads
class AxesElement extends DrawingElement {
  Color get color => Color(attributes['color'] as int);
  double get lineWidth => attributes['lineWidth'] as double;
  bool get showArrowheads => attributes['showArrowheads'] as bool;

  AxesElement({
    required Color color,
    required double lineWidth,
    bool showArrowheads = true,
  }) : super(
          type: 'axes',
          attributes: {
            'color': color.value,
            'lineWidth': lineWidth,
            'showArrowheads': showArrowheads,
          },
        );

  factory AxesElement.fromJson(Map<String, dynamic> json) {
    return AxesElement(
      color: Color(json['color'] as int),
      lineWidth: (json['lineWidth'] as num).toDouble(),
      showArrowheads: json['showArrowheads'] as bool? ?? true,
    );
  }
}

/// Represents a line connecting multiple points
class LineElement extends DrawingElement {
  List<Point> get points => (attributes['points'] as List)
      .map((p) => Point.fromJson(p as Map<String, dynamic>))
      .toList();
  Color get color => Color(attributes['color'] as int);
  double get lineWidth => attributes['lineWidth'] as double;
  bool get isDashed => attributes['isDashed'] as bool;

  LineElement({
    required List<Point> points,
    required Color color,
    required double lineWidth,
    bool isDashed = false,
  }) : super(
          type: 'line',
          attributes: {
            'points': points.map((p) => p.toJson()).toList(),
            'color': color.value,
            'lineWidth': lineWidth,
            'isDashed': isDashed,
          },
        );

  factory LineElement.fromJson(Map<String, dynamic> json) {
    return LineElement(
      points: (json['points'] as List)
          .map((p) => Point.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      lineWidth: (json['lineWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool? ?? false,
    );
  }
}

/// Represents rise/run arrows for slope visualization
class SlopeIndicatorElement extends DrawingElement {
  Point get startPoint =>
      Point.fromJson(attributes['startPoint'] as Map<String, dynamic>);
  Point get endPoint =>
      Point.fromJson(attributes['endPoint'] as Map<String, dynamic>);
  Color get riseColor => Color(attributes['riseColor'] as int);
  Color get runColor => Color(attributes['runColor'] as int);
  double get lineWidth => attributes['lineWidth'] as double;

  SlopeIndicatorElement({
    required Point startPoint,
    required Point endPoint,
    required Color riseColor,
    required Color runColor,
    required double lineWidth,
  }) : super(
          type: 'slope_indicator',
          attributes: {
            'startPoint': startPoint.toJson(),
            'endPoint': endPoint.toJson(),
            'riseColor': riseColor.value,
            'runColor': runColor.value,
            'lineWidth': lineWidth,
          },
        );

  factory SlopeIndicatorElement.fromJson(Map<String, dynamic> json) {
    return SlopeIndicatorElement(
      startPoint: Point.fromJson(json['startPoint'] as Map<String, dynamic>),
      endPoint: Point.fromJson(json['endPoint'] as Map<String, dynamic>),
      riseColor: Color(json['riseColor'] as int),
      runColor: Color(json['runColor'] as int),
      lineWidth: (json['lineWidth'] as num).toDouble(),
    );
  }
}

/// Represents text labels and annotations
class LabelElement extends DrawingElement {
  String get text => attributes['text'] as String;
  Point get position =>
      Point.fromJson(attributes['position'] as Map<String, dynamic>);
  Color get color => Color(attributes['color'] as int);
  double get fontSize => attributes['fontSize'] as double;
  double get fadeInStart => attributes['fadeInStart'] as double;
  double get fadeInEnd => attributes['fadeInEnd'] as double;

  LabelElement({
    required String text,
    required Point position,
    required Color color,
    required double fontSize,
    required double fadeInStart,
    required double fadeInEnd,
  }) : super(
          type: 'label',
          attributes: {
            'text': text,
            'position': position.toJson(),
            'color': color.value,
            'fontSize': fontSize,
            'fadeInStart': fadeInStart,
            'fadeInEnd': fadeInEnd,
          },
        );

  factory LabelElement.fromJson(Map<String, dynamic> json) {
    return LabelElement(
      text: json['text'] as String,
      position: Point.fromJson(json['position'] as Map<String, dynamic>),
      color: Color(json['color'] as int),
      fontSize: (json['fontSize'] as num).toDouble(),
      fadeInStart: (json['fadeInStart'] as num).toDouble(),
      fadeInEnd: (json['fadeInEnd'] as num).toDouble(),
    );
  }
}

/// Represents a stage in the drawing animation
class DrawingStage {
  final String name;
  final String description;
  final double startTime;
  final double endTime;
  final String easingFunction;
  final List<DrawingElement> elements;

  const DrawingStage({
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.easingFunction,
    required this.elements,
  });

  factory DrawingStage.fromJson(Map<String, dynamic> json) {
    return DrawingStage(
      name: json['name'] as String,
      description: json['description'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      easingFunction: json['easingFunction'] as String,
      elements: (json['elements'] as List)
          .map((e) => DrawingElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'easingFunction': easingFunction,
        'elements': elements.map((e) => e.toJson()).toList(),
      };
}

/// Represents the speech/narration specification
class SpeechSpec {
  final String script;
  final double initialDelay;
  final double betweenStagesDelay;
  final double finalDelay;
  final double speechRate;

  const SpeechSpec({
    required this.script,
    this.initialDelay = 0.0,
    this.betweenStagesDelay = 0.5,
    this.finalDelay = 1.0,
    this.speechRate = 1.0,
  });

  factory SpeechSpec.fromJson(Map<String, dynamic> json) {
    return SpeechSpec(
      script: json['script'] as String,
      initialDelay: (json['initialDelay'] as num?)?.toDouble() ?? 0.0,
      betweenStagesDelay:
          (json['betweenStagesDelay'] as num?)?.toDouble() ?? 0.5,
      finalDelay: (json['finalDelay'] as num?)?.toDouble() ?? 1.0,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'script': script,
        'initialDelay': initialDelay,
        'betweenStagesDelay': betweenStagesDelay,
        'finalDelay': finalDelay,
        'speechRate': speechRate,
      };
}

/// The main drawing specification that contains all stages and speech
class DrawingSpec {
  final List<DrawingStage> stages;
  final SpeechSpec speech;
  final Map<String, dynamic> metadata;

  const DrawingSpec({
    required this.stages,
    required this.speech,
    this.metadata = const {},
  });

  factory DrawingSpec.fromJson(Map<String, dynamic> json) {
    return DrawingSpec(
      stages: (json['stages'] as List)
          .map((s) => DrawingStage.fromJson(s as Map<String, dynamic>))
          .toList(),
      speech: SpeechSpec.fromJson(json['speech'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'stages': stages.map((s) => s.toJson()).toList(),
        'speech': speech.toJson(),
        'metadata': metadata,
      };
}
