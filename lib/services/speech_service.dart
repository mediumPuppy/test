import 'package:flutter_tts/flutter_tts.dart';
import '../models/drawing_spec_models.dart';

/// Service for handling text-to-speech functionality
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentScript;

  /// Initialize the TTS engine with default settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('[${DateTime.now()}] Initializing TTS engine');
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slower default rate
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
    print('[${DateTime.now()}] TTS engine initialized');
  }

  /// Speak the text for a specific stage
  Future<void> speakStage(DrawingStage stage, {double rate = 0.5}) async {
    if (!_isInitialized) {
      await initialize();
    }

    print('[${DateTime.now()}] Speaking stage: ${stage.name} (rate: $rate)');
    print('[${DateTime.now()}] Text: "${stage.description}"');

    if (_isSpeaking) {
      await stop();
    }

    _currentScript = stage.description;
    // Adjust rate to be within reasonable bounds
    final adjustedRate = rate.clamp(0.3, 0.8);
    await _tts.setSpeechRate(adjustedRate);
    _isSpeaking = true;
    await _tts.speak(stage.description);
  }

  /// Speak the entire script
  Future<void> speakScript(SpeechSpec spec) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stop();
    }

    _currentScript = spec.script;
    // Convert the speechRate from the spec to a reasonable range (0.3 to 0.5)
    final adjustedRate = 0.3 + (spec.speechRate * 0.2).clamp(0.0, 0.2);
    print(
        '[${DateTime.now()}] Speaking full script (original rate: ${spec.speechRate}, adjusted rate: ${adjustedRate.toStringAsFixed(2)})');
    print('[${DateTime.now()}] Script: "${spec.script}"');
    print(
        '[${DateTime.now()}] Delays - Initial: ${spec.initialDelay}s, Between: ${spec.betweenStagesDelay}s, Final: ${spec.finalDelay}s');

    await _tts.setSpeechRate(adjustedRate);

    // Add initial delay if specified
    if (spec.initialDelay > 0) {
      await Future.delayed(
          Duration(milliseconds: (spec.initialDelay * 1000).round()));
    }

    _isSpeaking = true;
    await _tts.speak(spec.script);
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;

    print('[${DateTime.now()}] Stopping speech');
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Pause speaking
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;

    print('[${DateTime.now()}] Pausing speech');
    _isSpeaking = false;
    await _tts.pause();
  }

  /// Resume speaking
  Future<void> resume() async {
    if (!_isInitialized || _isSpeaking) return;

    print('[${DateTime.now()}] Resuming speech: "${_currentScript ?? ''}"');
    _isSpeaking = true;
    await _tts.speak(_currentScript ?? '');
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    print('[${DateTime.now()}] Disposing speech service');
    await stop();
    _isInitialized = false;
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
