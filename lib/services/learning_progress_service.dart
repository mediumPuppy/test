import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import 'dart:math';

class LearningProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // SuperMemo-2 algorithm constants
  static const double _minEaseFactor = 1.3;
  static const int _defaultInterval = 1;

  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    final doc = await _firestore.collection('user_progress').doc(userId).get();
    return doc.data() ?? {
      'currentPath': null,
      'topicsCompleted': {},
      'lastQuizDate': null,
      'performanceMetrics': {},
      'masteryLevels': {},
      'nextQuizDue': null,
    };
  }

  Future<void> updateUserProgress({
    required String userId,
    required String topicId,
    required double performance,
    DateTime? completionDate,
  }) async {
    final now = completionDate ?? DateTime.now();
    
    await _firestore.collection('user_progress').doc(userId).set({
      'topicsCompleted': {
        topicId: now.toIso8601String(),
      },
      'performanceMetrics': {
        topicId: performance,
      },
      'lastUpdated': now.toIso8601String(),
    }, SetOptions(merge: true));

    // Schedule next quiz based on performance
    final nextQuizDate = await _scheduleNextQuiz(
      userId: userId,
      topicId: topicId,
      performance: performance,
    );

    await _firestore.collection('user_progress').doc(userId).update({
      'nextQuizDue': nextQuizDate.toIso8601String(),
    });
  }

  Future<DateTime> _scheduleNextQuiz({
    required String userId,
    required String topicId,
    required double performance,
  }) async {
    final doc = await _firestore
        .collection('quiz_scheduling')
        .doc(userId)
        .collection('topics')
        .doc(topicId)
        .get();

    final data = doc.data() ?? {
      'repetitionCount': 0,
      'easeFactor': 2.5,
      'interval': _defaultInterval,
    };

    final int repetitionCount = data['repetitionCount'] + 1;
    double easeFactor = data['easeFactor'];
    int interval = data['interval'];

    // Calculate new interval using SuperMemo-2
    if (repetitionCount == 1) {
      interval = _defaultInterval;
    } else if (repetitionCount == 2) {
      interval = 6;
    } else {
      interval = (interval * easeFactor).round();
    }

    // Update ease factor
    easeFactor = max(
      _minEaseFactor,
      easeFactor + (0.1 - (5 - performance) * (0.08 + (5 - performance) * 0.02)),
    );

    // Store updated scheduling data
    await doc.reference.set({
      'repetitionCount': repetitionCount,
      'easeFactor': easeFactor,
      'interval': interval,
      'lastQuizDate': DateTime.now().toIso8601String(),
    });

    return DateTime.now().add(Duration(days: interval));
  }

  Future<bool> shouldTriggerQuiz(String userId) async {
    final progress = await getUserProgress(userId);
    
    if (progress['nextQuizDue'] == null) return false;
    
    final nextQuizDue = DateTime.parse(progress['nextQuizDue']);
    return DateTime.now().isAfter(nextQuizDue);
  }

  Future<Map<String, double>> getTopicMasteryLevels(String userId) async {
    final progress = await getUserProgress(userId);
    return Map<String, double>.from(progress['performanceMetrics'] ?? {});
  }
}
