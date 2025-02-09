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

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(1.0);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Speak the text for a specific stage
  Future<void> speakStage(DrawingStage stage, {double rate = 1.0}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stop();
    }

    _currentScript = stage.description;
    await _tts.setSpeechRate(rate);
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
    await _tts.setSpeechRate(spec.speechRate);
    _isSpeaking = true;
    await _tts.speak(spec.script);
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;

    await _tts.stop();
    _isSpeaking = false;
  }

  /// Pause speaking
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;

    _isSpeaking = false;
    await _tts.pause();
  }

  /// Resume speaking
  Future<void> resume() async {
    if (!_isInitialized || _isSpeaking) return;

    _isSpeaking = true;
    await _tts.speak(_currentScript ?? '');
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    await stop();
    _isInitialized = false;
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
