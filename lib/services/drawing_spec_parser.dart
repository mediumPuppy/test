import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';

/// Service for parsing and validating drawing specifications from JSON
class DrawingSpecParser {
  /// Parse a JSON string into a DrawingSpec object
  static DrawingSpec parseFromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return DrawingSpec.fromJson(json);
    } catch (e) {
      throw FormatException('Failed to parse drawing specification: $e');
    }
  }

  /// Validate the drawing specification for required fields and logical consistency
  static void validate(DrawingSpec spec) {
    // Validate stages
    if (spec.stages.isEmpty) {
      throw ValidationException(
          'Drawing specification must have at least one stage');
    }

    // Validate stage timing
    double lastEndTime = 0;
    for (final stage in spec.stages) {
      if (stage.startTime < 0 || stage.endTime < 0) {
        throw ValidationException('Stage times cannot be negative');
      }
      if (stage.endTime <= stage.startTime) {
        throw ValidationException(
            'Stage end time must be greater than start time: ${stage.name}');
      }
      if (stage.startTime < lastEndTime) {
        throw ValidationException(
            'Stages must be sequential: ${stage.name} overlaps with previous stage');
      }
      lastEndTime = stage.endTime;

      // Validate elements in stage
      _validateElements(stage.elements);
    }

    // Validate speech
    if (spec.speech.script.isEmpty) {
      throw ValidationException('Speech script cannot be empty');
    }
    if (spec.speech.initialDelay < 0 ||
        spec.speech.betweenStagesDelay < 0 ||
        spec.speech.finalDelay < 0) {
      throw ValidationException('Speech delays cannot be negative');
    }
    if (spec.speech.speechRate <= 0) {
      throw ValidationException('Speech rate must be positive');
    }
  }

  /// Validate individual drawing elements
  static void _validateElements(List<DrawingElement> elements) {
    for (final element in elements) {
      switch (element.type) {
        case 'grid':
          _validateGridElement(element as GridElement);
          break;
        case 'axes':
          _validateAxesElement(element as AxesElement);
          break;
        case 'line':
          _validateLineElement(element as LineElement);
          break;
        case 'slope_indicator':
          _validateSlopeIndicatorElement(element as SlopeIndicatorElement);
          break;
        case 'label':
          _validateLabelElement(element as LabelElement);
          break;
        default:
          throw ValidationException('Unknown element type: ${element.type}');
      }
    }
  }

  static void _validateGridElement(GridElement element) {
    if (element.spacing <= 0) {
      throw ValidationException('Grid spacing must be positive');
    }
    if (element.lineWidth <= 0) {
      throw ValidationException('Grid line width must be positive');
    }
    if (element.opacity < 0 || element.opacity > 1) {
      throw ValidationException('Grid opacity must be between 0 and 1');
    }
  }

  static void _validateAxesElement(AxesElement element) {
    if (element.lineWidth <= 0) {
      throw ValidationException('Axes line width must be positive');
    }
  }

  static void _validateLineElement(LineElement element) {
    if (element.points.length < 2) {
      throw ValidationException('Line must have at least two points');
    }
    if (element.lineWidth <= 0) {
      throw ValidationException('Line width must be positive');
    }
  }

  static void _validateSlopeIndicatorElement(SlopeIndicatorElement element) {
    if (element.lineWidth <= 0) {
      throw ValidationException('Slope indicator line width must be positive');
    }
  }

  static void _validateLabelElement(LabelElement element) {
    if (element.text.isEmpty) {
      throw ValidationException('Label text cannot be empty');
    }
    if (element.fontSize <= 0) {
      throw ValidationException('Label font size must be positive');
    }
    if (element.fadeInEnd <= element.fadeInStart) {
      throw ValidationException(
          'Label fade-in end time must be greater than start time');
    }
  }

  /// Convert a color string (hex format) to a Color object
  static Color parseColor(String colorString) {
    if (!colorString.startsWith('#')) {
      throw ValidationException('Color must be in hex format (e.g., #RRGGBB)');
    }

    String hex = colorString.substring(1);
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add full opacity if not specified
    } else if (hex.length != 8) {
      throw ValidationException('Invalid color format: $colorString');
    }

    return Color(int.parse(hex, radix: 16));
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
