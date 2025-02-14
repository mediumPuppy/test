// lib/services/progress/video_progress_tracker.dart
// ================================================================================
import 'dart:async';
import '../../models/video_feed.dart';
import 'progress_tracker.dart';
import 'package:flutter/widgets.dart'; // Add this for BuildContext
import 'package:flutter/material.dart'; // Add this for Material widgets
import '../../widgets/video_feed_item.dart'; // Add this for VideoFeedItem
import '../quiz_scheduler_service.dart';
import '../../screens/quiz_screen.dart';

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
  static final List<VideoFeed> _recentVideos = [];
  static const int _quizThreshold = 3; // Show quiz after 3 videos
  final _quizScheduler = QuizSchedulerService();

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

  // Replace the old quiz-related methods with a single async method
  Future<bool> checkAndShowQuiz(BuildContext context, String userId) async {
    // First, track this video
    if (!_recentVideos.any((video) => video.id == _content.id)) {
      _recentVideos.add(_content);
      print(
          'VideoProgressTracker: Added video[${_content.id}] to recent videos. Count: ${_recentVideos.length}');
    }

    // Check if we've reached the threshold
    if (_recentVideos.length < _quizThreshold) {
      print('VideoProgressTracker: Not enough videos watched for quiz yet.');
      return false;
    }

    print('VideoProgressTracker: Quiz threshold reached. Preparing quiz...');

    // Stop video playback
    VideoFeedItem.stopPlayback(context);

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Video Paused',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quiz incoming...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Preparing your progress check'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Generate quiz
    final quiz = await _quizScheduler.generateQuizForUser(
      userId: userId,
      currentTopics: _content.topics,
      previousVideos: List<VideoFeed>.from(_recentVideos),
      questionCount: 5,
    );

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show quiz if generated successfully
    if (quiz != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quiz: quiz,
            userId: userId,
            videoContext: List<VideoFeed>.from(_recentVideos),
          ),
        ),
      );

      // Clear the list after quiz is completed
      _recentVideos.clear();
      return true;
    }

    // If we get here, no quiz was shown
    return false;
  }
}
