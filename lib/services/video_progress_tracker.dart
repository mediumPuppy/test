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
    _recentVideos.add(video);
    if (_recentVideos.length > videosBeforeQuiz) {
      _recentVideos.removeAt(0);
    }
  }

  Future<bool> shouldShowQuiz(BuildContext context, String userId) async {
    if (_recentVideos.length < videosBeforeQuiz) return false;

    // Get unique topics from recent videos
    final topics =
        _recentVideos.expand((video) => video.topics).toSet().toList();

    // Generate a quiz based on recent videos
    final quiz = await _quizScheduler.generateQuizForUser(
      userId: userId,
      currentTopics: topics,
      previousVideos: _recentVideos,
      questionCount: 5, // Shorter quiz for between-video experience
    );

    if (quiz == null) return false;

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

    // Clear tracked videos after quiz
    _recentVideos.clear();
    return true;
  }

  List<VideoFeed> get recentVideos => List.unmodifiable(_recentVideos);
}
