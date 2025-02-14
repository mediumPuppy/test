// lib/services/progress/video_progress_tracker.dart
// ================================================================================
import 'dart:async';
import '../../models/video_feed.dart';
import 'progress_tracker.dart';
import 'package:flutter/widgets.dart'; // Add this for BuildContext
import '../../widgets/video_feed_item.dart'; // Add this for VideoFeedItem

/// Tracks progress for video content
/// Following Single Responsibility Principle by handling only video progress
class VideoProgressTracker implements ProgressTracker {
  final VideoFeed _content;
  final _progressController = StreamController<double>.broadcast();
  double _progress = 0.0;
  double _highestProgress = 0.0; // Track highest progress achieved
  bool _completed = false;
  DateTime? _lastUpdateTime;
  static const _inactivityThreshold =
      Duration(seconds: 3); // Mark complete if user leaves for 3+ seconds

  // Add quiz-related fields
  final List<String> _recentVideos = [];
  static const int _quizThreshold = 3; // Show quiz after 3 videos

  VideoProgressTracker(this._content) {
    _progress = _content.progress;
    _highestProgress = _progress;
    _completed = _content.isCompleted;
    print(
        'VideoProgressTracker: Initialized for video[${_content.id}] with progress: ${(_progress * 100).toStringAsFixed(1)}%');
  }

  @override
  Stream<double> get progressStream => _progressController.stream;

  @override
  double get currentProgress => _progress;

  @override
  bool get isCompleted => _completed;

  @override
  Future<void> updateProgress(double progress) async {
    await _updateProgress(progress);
  }

  Future<void> _updateProgress(double progress) async {
    final now = DateTime.now();
    final newProgress = progress.clamp(0.0, 1.0);

    // Check for inactivity (potential early exit)
    if (_lastUpdateTime != null) {
      final inactivityDuration = now.difference(_lastUpdateTime!);
      if (inactivityDuration > _inactivityThreshold && _progress > 0.1) {
        print(
            'VideoProgressTracker: Inactivity detected (${inactivityDuration.inSeconds}s), marking as completed');
        await markCompleted();
        return;
      }
    }

    _lastUpdateTime = now;

    // Only update if new progress is higher than highest seen
    if (newProgress > _highestProgress) {
      _highestProgress = newProgress;
      _progress = newProgress;
      _progressController.add(_progress);
      print(
          'VideoProgressTracker: Updated video[${_content.id}] progress to new high: ${(_progress * 100).toStringAsFixed(1)}%');

      // Auto-complete if progress reaches 95%
      if (_progress >= 0.95 && !_completed) {
        print(
            'VideoProgressTracker: Progress reached 95%, marking as completed');
        await markCompleted();
      }
    } else {
      print(
          'VideoProgressTracker: Ignoring lower progress ${(newProgress * 100).toStringAsFixed(1)}% < ${(_highestProgress * 100).toStringAsFixed(1)}%');
    }
  }

  @override
  Future<void> markCompleted() async {
    await _markCompleted();
  }

  Future<void> _markCompleted() async {
    if (!_completed) {
      _completed = true;
      _progress = 1.0;
      _highestProgress = 1.0;
      _progressController.add(_progress);
      print('VideoProgressTracker: Marked video[${_content.id}] as completed');
    }
  }

  @override
  Future<void> reset() async {
    print(
        'VideoProgressTracker: Reset requested but ignored to maintain progress');
  }

  @override
  void dispose() {
    print('VideoProgressTracker: Disposing tracker for video[${_content.id}]');
    _progressController.close();
  }

  // Add quiz-related methods
  bool shouldShowQuiz(String videoId) {
    if (!_recentVideos.contains(videoId)) {
      _recentVideos.add(videoId);
      print(
          'VideoProgressTracker: Added video[$videoId] to recent videos. Count: ${_recentVideos.length}');
    }

    if (_recentVideos.length >= _quizThreshold) {
      print('VideoProgressTracker: Quiz threshold reached. Showing quiz.');
      _recentVideos.clear(); // Reset counter after showing quiz
      return true;
    }
    return false;
  }

  Future<void> stopPlayback(BuildContext context) async {
    print('VideoProgressTracker: Stopping video playback');
    VideoFeedItem.stopPlayback(context);
  }
}
