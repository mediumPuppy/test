import 'dart:async';

class TopicProgressService {
  static final TopicProgressService _instance = TopicProgressService._internal();
  factory TopicProgressService() => _instance;
  TopicProgressService._internal();

  int _currentPosition = 0;
  int _totalVideos = 0;
  final _positionController = StreamController<int>.broadcast();

  Stream<int> get positionStream => _positionController.stream;
  int get totalVideos => _totalVideos;
  int get currentPosition => _currentPosition;

  void setTotalVideos(int count) {
    _totalVideos = count;
    // Reset position when total changes
    _currentPosition = 0;
    _positionController.add(_currentPosition);
  }

  void incrementPosition() {
    if (_totalVideos == 0) return;
    _currentPosition = (_currentPosition + 1).clamp(0, _totalVideos - 1);
    _positionController.add(_currentPosition);
  }

  void decrementPosition() {
    if (_totalVideos == 0) return;
    _currentPosition = (_currentPosition - 1).clamp(0, _totalVideos - 1);
    _positionController.add(_currentPosition);
  }

  double getProgress() {
    if (_totalVideos == 0) return 0;
    final progress = (_currentPosition + 1) / _totalVideos;
    return progress.clamp(0.0, 1.0);
  }

  void dispose() {
    _positionController.close();
  }
}
