import 'package:flutter/foundation.dart';

enum ExplanationStatus {
  idle,
  listening,      // When microphone is active
  processing,     // When sending to AI and waiting for response
  explaining,     // When playing back the explanation
  paused,         // When explanation playback is paused
  completed,      // When explanation is finished
  error,          // When an error occurs
}

class DrawingCommand {
  final String type;      // Type of drawing command (e.g., 'path', 'text', 'clear')
  final Map<String, dynamic> params;  // Parameters for the drawing command
  
  DrawingCommand({
    required this.type,
    required this.params,
  });
}

class ExplanationState extends ChangeNotifier {
  ExplanationStatus _status = ExplanationStatus.idle;
  String _questionText = '';
  String _explanationText = '';
  List<DrawingCommand> _drawingCommands = [];
  String _error = '';
  bool _isSaved = false;
  
  // Getters
  ExplanationStatus get status => _status;
  String get questionText => _questionText;
  String get explanationText => _explanationText;
  List<DrawingCommand> get drawingCommands => List.unmodifiable(_drawingCommands);
  String get error => _error;
  bool get isSaved => _isSaved;
  
  // State update methods
  void startListening() {
    _status = ExplanationStatus.listening;
    notifyListeners();
  }
  
  void stopListening() {
    _status = ExplanationStatus.idle;
    notifyListeners();
  }
  
  void updateQuestionText(String text) {
    _questionText = text;
    notifyListeners();
  }
  
  void startProcessing() {
    _status = ExplanationStatus.processing;
    _explanationText = '';
    _drawingCommands = [];
    notifyListeners();
  }
  
  void startExplanation({
    required String explanationText,
    required List<DrawingCommand> drawingCommands,
  }) {
    _status = ExplanationStatus.explaining;
    _explanationText = explanationText;
    _drawingCommands = drawingCommands;
    notifyListeners();
  }
  
  void pauseExplanation() {
    if (_status == ExplanationStatus.explaining) {
      _status = ExplanationStatus.paused;
      notifyListeners();
    }
  }
  
  void resumeExplanation() {
    if (_status == ExplanationStatus.paused) {
      _status = ExplanationStatus.explaining;
      notifyListeners();
    }
  }
  
  void completeExplanation() {
    _status = ExplanationStatus.completed;
    notifyListeners();
  }
  
  void setError(String errorMessage) {
    _status = ExplanationStatus.error;
    _error = errorMessage;
    notifyListeners();
  }
  
  void saveExplanation() {
    _isSaved = true;
    notifyListeners();
  }
  
  void reset() {
    _status = ExplanationStatus.idle;
    _questionText = '';
    _explanationText = '';
    _drawingCommands = [];
    _error = '';
    _isSaved = false;
    notifyListeners();
  }
}
