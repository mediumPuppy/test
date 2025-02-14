import 'package:flutter/material.dart';
import '../models/video_feed.dart';
import '../screens/quiz_screen.dart';
import '../services/quiz_scheduler_service.dart';
import 'package:collection/collection.dart';

class VideoProgressTracker {
  static const int videosBeforeQuiz = 2;
  final List<VideoFeed> _recentVideos = [];
  final QuizSchedulerService _quizScheduler = QuizSchedulerService();

  void trackVideo(VideoFeed video) {
    print('[VideoTracker] Adding video to tracker: ${video.title}');
    print(
        '[VideoTracker] Current video count before adding: ${_recentVideos.length}');

    _recentVideos.add(video);
    if (_recentVideos.length > videosBeforeQuiz) {
      print(
          '[VideoTracker] Removing oldest video as we exceeded $videosBeforeQuiz videos');
      _recentVideos.removeAt(0);
    }

    print(
        '[VideoTracker] Current videos tracked: ${_recentVideos.map((v) => v.title).join(", ")}');
  }

  Future<bool> shouldShowQuiz(BuildContext context, String userId) async {
    print('[VideoTracker] Checking if should show quiz...');
    print('[VideoTracker] Current video count: ${_recentVideos.length}');

    if (_recentVideos.length < videosBeforeQuiz) {
      print(
          '[VideoTracker] Not enough videos watched yet (${_recentVideos.length}/$videosBeforeQuiz)');
      return false;
    }

    // Get unique topics from recent videos
    final topics =
        _recentVideos.expand((video) => video.topics).toSet().toList();
    print('[VideoTracker] Topics collected for quiz: ${topics.join(", ")}');

    // Generate a quiz based on recent videos
    print('[VideoTracker] Generating quiz for user: $userId');
    final quiz = await _quizScheduler.generateQuizForUser(
      userId: userId,
      currentTopics: topics,
      previousVideos: _recentVideos,
      questionCount: 5, // Shorter quiz for between-video experience
    );

    if (quiz == null) {
      print('[VideoTracker] Failed to generate quiz');
      return false;
    }

    print('[VideoTracker] Successfully generated quiz, showing to user');
    // Show the quiz
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quiz: quiz,
            userId: userId,
            videoContext: _recentVideos,
          ),
        ),
      );
    }

    print('[VideoTracker] Quiz completed, clearing video history');
    // Clear tracked videos after quiz
    _recentVideos.clear();
    return true;
  }

  List<VideoFeed> get recentVideos => List.unmodifiable(_recentVideos);
}
