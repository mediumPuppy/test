import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Slower speed for better clarity
      await _tts.setVolume(1.0);
      _isInitialized = true;
    }
  }

  Future<void> speak(String text) async {
    await initialize();
    return _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<bool> get isPlaying async {
    final ttsState = await _tts.getSpeechRateValidRange;
    return ttsState != null;
  }

  Future<void> dispose() async {
    await stop();
  }
}
