import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../models/video_feed.dart';
import 'learning_progress_service.dart';
import 'quiz_service.dart';

class QuizSchedulerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LearningProgressService _progressService = LearningProgressService();
  final QuizService _quizService = QuizService();

  static const int _defaultQuestionCount = 10;
  static const double _recentTopicsWeight = 0.5;
  static const double _reviewTopicsWeight = 0.3;
  static const double _advancedTopicsWeight = 0.2;

  Future<Quiz?> generateQuizForUser({
    required String userId,
    required List<String> currentTopics,
    List<VideoFeed>? previousVideos,
    int questionCount = _defaultQuestionCount,
  }) async {
    try {
      final masteryLevels =
          await _progressService.getTopicMasteryLevels(userId);

      // If we have previous videos, extract their topics and context
      String? contextSummary;
      if (previousVideos != null && previousVideos.isNotEmpty) {
        final contextBuilder = StringBuffer();
        contextBuilder.writeln('Quiz based on your recent lessons:');

        for (var video in previousVideos) {
          contextBuilder.writeln('• ${video.title}');
          // Add topics from previous videos to current topics
          currentTopics.addAll(video.topics);
        }

        // Remove duplicates
        currentTopics = currentTopics.toSet().toList();
        contextSummary = contextBuilder.toString();
      }

      // Calculate question distribution
      final recentCount = (questionCount * _recentTopicsWeight).round();
      final reviewCount = (questionCount * _reviewTopicsWeight).round();
      final advancedCount = (questionCount * _advancedTopicsWeight).round();

      // Adjust counts to ensure they sum to questionCount
      final totalCount = recentCount + reviewCount + advancedCount;
      final adjustment = questionCount - totalCount;
      final adjustedRecentCount = recentCount + adjustment;

      // Get questions for each category
      final recentQuestions = await _getQuestionsForTopics(
        topics: currentTopics,
        count: adjustedRecentCount,
        difficulty: _getDifficultyForMastery(
          masteryLevels[currentTopics.last] ?? 0.0,
        ),
      );

      final completedTopics = await _getCompletedTopics(userId);
      final reviewQuestions = await _getQuestionsForTopics(
        topics: completedTopics,
        count: reviewCount,
        difficulty: DifficultyLevel.intermediate,
      );

      final upcomingTopics = await _getUpcomingTopics(currentTopics.last);
      final advancedQuestions = await _getQuestionsForTopics(
        topics: upcomingTopics,
        count: advancedCount,
        difficulty: DifficultyLevel.advanced,
      );

      // Combine all questions
      final allQuestions = [
        ...recentQuestions,
        ...reviewQuestions,
        ...advancedQuestions,
      ];

      if (allQuestions.isEmpty) return null;

      // Create a new quiz
      return Quiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: previousVideos != null
            ? 'Quick Progress Check'
            : 'Progress Check Quiz',
        topics: [...currentTopics, ...completedTopics, ...upcomingTopics],
        difficulty: _getDifficultyForMastery(
          masteryLevels[currentTopics.last] ?? 0.0,
        ),
        questions: allQuestions,
        timeLimit: previousVideos != null
            ? 300
            : 900, // 5 minutes for quick quiz, 15 for regular
        shuffleQuestions: true,
        metadata: {
          'generatedFor': userId,
          'generatedAt': DateTime.now().toIso8601String(),
          'type': previousVideos != null ? 'video_progress' : 'adaptive',
          if (contextSummary != null) 'contextSummary': contextSummary,
        },
      );
    } catch (e) {
      print('Error generating quiz: $e');
      return null;
    }
  }

  Future<List<QuizQuestion>> _getQuestionsForTopics({
    required List<String> topics,
    required int count,
    required DifficultyLevel difficulty,
  }) async {
    if (topics.isEmpty || count <= 0) return [];

    final quizzes = await _quizService.getQuizzesForTopics(
      topics: topics,
      difficulty: difficulty,
      limit: 5,
    );

    final questions = quizzes
        .expand((quiz) => quiz.questions)
        .where((q) => q.difficulty == difficulty)
        .toList();

    questions.shuffle();
    return questions.take(count).toList();
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
