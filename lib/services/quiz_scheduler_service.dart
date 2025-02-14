import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../models/video_feed.dart';
import 'learning_progress_service.dart';
import 'quiz_service.dart';
import 'gpt_service.dart';

class QuizSchedulerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LearningProgressService _progressService = LearningProgressService();
  final QuizService _quizService = QuizService();
  final GptService _gptService = GptService();

  static const int _defaultQuestionCount = 10;
  static const double _recentTopicsWeight = 0.5;
  static const double _reviewTopicsWeight = 0.3;
  static const double _advancedTopicsWeight = 0.2;

  Future<List<QuizQuestion>> _getQuestionsForTopics({
    required List<String> topics,
    required int count,
    required DifficultyLevel difficulty,
  }) async {
    if (topics.isEmpty || count <= 0) {
      print('[QuizScheduler] No topics provided or count is 0');
      return [];
    }

    print(
        '[QuizScheduler] Searching for questions with topics: ${topics.join(", ")}');
    print('[QuizScheduler] Difficulty level: $difficulty');

    final quiz = await _gptService.generateQuizFromTopics(
      topics: topics,
      difficulty: difficulty,
      questionCount: count,
    );

    if (quiz == null) {
      print('[QuizScheduler] Failed to generate quiz questions');
      return [];
    }

    print(
        '[QuizScheduler] Successfully generated ${quiz.questions.length} questions');
    return quiz.questions;
  }

  Future<Quiz?> generateQuizForUser({
    required String userId,
    required List<String> currentTopics,
    List<VideoFeed>? previousVideos,
    int questionCount = _defaultQuestionCount,
  }) async {
    try {
      print('[QuizScheduler] Generating quiz for user: $userId');
      print('[QuizScheduler] Current topics: ${currentTopics.join(", ")}');

      final masteryLevels =
          await _progressService.getTopicMasteryLevels(userId);
      print('[QuizScheduler] User mastery levels: $masteryLevels');

      // If we have previous videos, extract their topics
      var allTopics = List<String>.from(currentTopics); // Create new list
      if (previousVideos != null && previousVideos.isNotEmpty) {
        for (var video in previousVideos) {
          allTopics.addAll(video.topics);
        }
        // Remove duplicates
        allTopics = allTopics.toSet().toList();
        print(
            '[QuizScheduler] Updated topics after adding from videos: ${allTopics.join(", ")}');
      }

      // Calculate difficulty based on mastery of current topics
      final difficulty = _getDifficultyForMastery(
        masteryLevels[allTopics.last] ?? 0.0,
      );
      print('[QuizScheduler] Calculated difficulty level: $difficulty');

      // Generate questions with consistent difficulty
      final questions = await _getQuestionsForTopics(
        topics: allTopics,
        count: 5, // Generate 5 questions for a comprehensive review
        difficulty: difficulty,
      );

      if (questions.isEmpty) {
        print('[QuizScheduler] No questions generated');
        return null;
      }

      print(
          '[QuizScheduler] Successfully generated ${questions.length} questions');

      // Create quiz with consistent difficulty
      return Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: previousVideos != null
            ? '5-Video Progress Check'
            : 'Progress Check Quiz',
        topics: allTopics,
        difficulty: difficulty,
        questions: questions,
        timeLimit: previousVideos != null
            ? 600 // 10 minutes for 5-video quiz
            : 900, // 15 for regular
        shuffleQuestions: true,
        metadata: {
          'generatedFor': userId,
          'generatedAt': DateTime.now().toIso8601String(),
          'type': previousVideos != null ? 'video_progress' : 'adaptive',
        },
      );
    } catch (e, stackTrace) {
      print('[QuizScheduler] Error generating quiz: $e');
      print('[QuizScheduler] Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<String>> _getCompletedTopics(String userId) async {
    final progress = await _progressService.getUserProgress(userId);
    return List<String>.from(progress['topicsCompleted']?.keys ?? []);
  }

  Future<List<String>> _getUpcomingTopics(String currentTopic) async {
    final snapshot = await _firestore
        .collection('topics')
        .where('prerequisite', isEqualTo: currentTopic)
        .limit(3)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  DifficultyLevel _getDifficultyForMastery(double mastery) {
    if (mastery < 0.4) return DifficultyLevel.beginner;
    if (mastery < 0.7) return DifficultyLevel.intermediate;
    return DifficultyLevel.advanced;
  }
}
