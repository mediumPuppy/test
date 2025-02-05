// lib/services/math_expression_service.dart
import 'package:math_expressions/math_expressions.dart';
import '../models/quiz_model.dart';

class MathExpressionService {
  // Parse and evaluate mathematical expressions
  double? evaluateExpression(String expression) {
    try {
      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      return null;
    }
  }

  // Normalize expression for comparison
  String normalizeExpression(String expression) {
    // Remove spaces, convert to lowercase
    expression = expression.replaceAll(' ', '').toLowerCase();
    
    // Standardize operators
    expression = expression
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('^', '**');
    
    return expression;
  }

  // Check if expressions are equivalent
  bool areExpressionsEquivalent(
    String userAnswer, 
    String correctAnswer, 
    MathExpressionFormat format,
    List<String>? acceptableVariations
  ) {
    // First check against acceptable variations if provided
    if (acceptableVariations != null) {
      String normalizedUser = normalizeExpression(userAnswer);
      for (String variation in acceptableVariations) {
        if (normalizedUser == normalizeExpression(variation)) {
          return true;
        }
      }
    }

    // Then check based on format
    switch (format) {
      case MathExpressionFormat.basic:
        return _compareBasicExpressions(userAnswer, correctAnswer);
      
      case MathExpressionFormat.algebraic:
        return _compareAlgebraicExpressions(userAnswer, correctAnswer);
      
      case MathExpressionFormat.geometric:
        return _compareGeometricExpressions(userAnswer, correctAnswer);
      
      case MathExpressionFormat.calculus:
        return _compareCalculusExpressions(userAnswer, correctAnswer);
      
      case MathExpressionFormat.custom:
        // For custom formats, rely on acceptable variations
        return normalizeExpression(userAnswer) == normalizeExpression(correctAnswer);
    }
  }

  // Compare basic arithmetic expressions by evaluating them
  bool _compareBasicExpressions(String expr1, String expr2) {
    double? result1 = evaluateExpression(expr1);
    double? result2 = evaluateExpression(expr2);
    
    if (result1 == null || result2 == null) return false;
    return (result1 - result2).abs() < 1e-10; // Account for floating-point precision
  }

  // Compare algebraic expressions by checking structure
  bool _compareAlgebraicExpressions(String expr1, String expr2) {
    // Normalize variables (e.g., 2x + 3 and 2y + 3 are equivalent)
    String norm1 = _normalizeVariables(expr1);
    String norm2 = _normalizeVariables(expr2);
    
    // Compare normalized forms
    return norm1 == norm2;
  }

  // Compare geometric expressions
  bool _compareGeometricExpressions(String expr1, String expr2) {
    // First try basic evaluation
    if (_compareBasicExpressions(expr1, expr2)) return true;
    
    // Then normalize and compare units and measurements
    String norm1 = _normalizeGeometricExpression(expr1);
    String norm2 = _normalizeGeometricExpression(expr2);
    return norm1 == norm2;
  }

  // Compare calculus expressions
  bool _compareCalculusExpressions(String expr1, String expr2) {
    // For now, just compare normalized forms
    // TODO: Implement more sophisticated calculus expression comparison
    String norm1 = _normalizeCalculusExpression(expr1);
    String norm2 = _normalizeCalculusExpression(expr2);
    return norm1 == norm2;
  }

  String _normalizeVariables(String expr) {
    RegExp varPattern = RegExp(r'[a-zA-Z]');
    String normalized = expr;
    String varPlaceholder = 'VAR';
    int varCount = 0;
    
    Set<String> variables = {};
    for (Match match in varPattern.allMatches(expr)) {
      String var_ = match.group(0)!;
      if (!variables.contains(var_)) {
        variables.add(var_);
        normalized = normalized.replaceAll(
          var_, 
          '$varPlaceholder${varCount++}'
        );
      }
    }
    return normalized;
  }

  String _normalizeGeometricExpression(String expr) {
    // Normalize units and geometric terms
    return expr
      .replaceAll(RegExp(r'square\s+'), 'sq')
      .replaceAll(RegExp(r'cubic\s+'), 'cu')
      .replaceAll(RegExp(r'meters?|m\b'), 'm')
      .replaceAll(RegExp(r'centimeters?|cm\b'), 'cm')
      // Add more geometric normalizations as needed
      .toLowerCase();
  }

  String _normalizeCalculusExpression(String expr) {
    // Normalize calculus notation
    return expr
      .replaceAll(RegExp(r'd/dx'), 'derivative')
      .replaceAll(RegExp(r'\bint\b'), 'integral')
      // Add more calculus normalizations as needed
      .toLowerCase();
  }
}