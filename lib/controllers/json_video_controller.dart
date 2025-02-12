import 'dart:async';
import 'package:flutter/material.dart';

/// A custom video controller that "plays" video content defined by a JSON object.
/// In a real implementation, this controller would drive animations, speech synthesis,
/// and render drawings based on the JSON configuration.
class JsonVideoController extends ChangeNotifier {
  final Map<String, dynamic> videoJson;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Simulated duration and current position.
  Duration _duration;
  Duration _position = Duration.zero;
  Duration get duration => _duration;
  Duration get position => _position;

  Timer? _timer;

  JsonVideoController({required this.videoJson})
      : _duration = const Duration(seconds: 10); // Default duration

  /// Simulate initialization (e.g. parsing JSON, setting up animations)
  Future<void> initialize() async {
    // Add any JSON parsing or asset preloading here.
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
    notifyListeners();
  }

  /// Simulate playing the "video" by gradually updating the position.
  void play() {
    _timer?.cancel();
    // Update progress every 250ms.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_position < _duration) {
        _position += const Duration(milliseconds: 250);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void pause() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
