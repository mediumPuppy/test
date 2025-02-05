import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get a quiz by ID with its questions
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) return null;

      final data = quizDoc.data()!;
      final questionIds = List<String>.from(data['questionIds']);
      
      // Fetch all questions in parallel
      final questionDocs = await Future.wait(
        questionIds.map((id) => _firestore.collection('questions').doc(id).get())
      );
      
      final questions = questionDocs
          .where((doc) => doc.exists)
          .map((doc) => QuizQuestion.fromFirestore(doc))
          .toList();
      
      return Quiz.fromFirestore(quizDoc, questions);
    } catch (e) {
      print('Error fetching quiz: $e');
      return null;
    }
  }

  // Get quizzes for specific topics and difficulty
  Future<List<Quiz>> getQuizzesForTopics({
    required List<String> topics,
    DifficultyLevel? difficulty,
    int limit = 5,
  }) async {
    try {
      var query = _firestore.collection('quizzes')
          .where('topics', arrayContainsAny: topics);
      
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.toString());
      }
      
      final quizDocs = await query.limit(limit).get();
      
      // Fetch questions for all quizzes in parallel
      final quizzes = await Future.wait(
        quizDocs.docs.map((doc) async {
          final data = doc.data();
          final questionIds = List<String>.from(data['questionIds']);
          
          final questionDocs = await Future.wait(
            questionIds.map((id) => 
              _firestore.collection('questions').doc(id).get()
            )
          );
          
          final questions = questionDocs
              .where((doc) => doc.exists)
              .map((doc) => QuizQuestion.fromFirestore(doc))
              .toList();
          
          return Quiz.fromFirestore(doc, questions);
        })
      );
      
      return quizzes;
    } catch (e) {
      print('Error fetching quizzes: $e');
      return [];
    }
  }

  // Record a quiz attempt
  Future<void> recordQuizAttempt({
    required String userId,
    required String quizId,
    required Map<String, String> answers,
    required Map<String, bool> isCorrect,
    required int score,
    required int totalPossible,
    required Duration timeSpent,
  }) async {
    try {
      await _firestore.collection('quiz_attempts').add({
        'userId': userId,
        'quizId': quizId,
        'answers': answers,
        'isCorrect': isCorrect,
        'score': score,
        'totalPossible': totalPossible,
        'timeSpent': timeSpent.inSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording quiz attempt: $e');
      rethrow;
    }
  }

  // Get user's quiz history
  Future<List<Map<String, dynamic>>> getUserQuizHistory(String userId) async {
    try {
      final attempts = await _firestore.collection('quiz_attempts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return attempts.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      print('Error fetching quiz history: $e');
      return [];
    }
  }

  // Initialize sample quiz data for testing
  Future<void> initializeSampleQuizzes() async {
    try {
      final batch = _firestore.batch();

      // Sample questions for different topics and difficulties
      final questions = [
        {
          'id': 'q1',
          'text': 'What is 2 + 2?',
          'options': ['3', '4', '5', '6'],
          'correctOption': 1,
          'explanation': 'Basic addition: 2 + 2 = 4',
          'topic': 'arithmetic',
          'difficulty': 'beginner',
          'type': 'multiple_choice',
        },
        {
          'id': 'q2',
          'text': 'Solve for x: 2x + 4 = 12',
          'options': ['2', '4', '6', '8'],
          'correctOption': 1,
          'explanation': 'Subtract 4 from both sides: 2x = 8, then divide by 2: x = 4',
          'topic': 'basic_algebra',
          'difficulty': 'intermediate',
          'type': 'multiple_choice',
        },
        {
          'id': 'q3',
          'text': 'What is the derivative of x²?',
          'options': ['x²', '2x', '2', '0'],
          'correctOption': 1,
          'explanation': 'The power rule states that the derivative of x^n is nx^(n-1)',
          'topic': 'calculus',
          'difficulty': 'advanced',
          'type': 'multiple_choice',
        },
      ];

      // Add questions to Firestore
      for (final question in questions) {
        final questionRef = _firestore.collection('questions').doc(question['id'] as String);
        batch.set(questionRef, question);
      }

      // Create sample quizzes
      final quizzes = [
        {
          'id': 'quiz1',
          'title': 'Basic Math Quiz',
          'topics': ['arithmetic'],
          'difficulty': 'beginner',
          'questionIds': ['q1'],
          'timeLimit': 300,
          'shuffleQuestions': true,
        },
        {
          'id': 'quiz2',
          'title': 'Algebra Quiz',
          'topics': ['basic_algebra'],
          'difficulty': 'intermediate',
          'questionIds': ['q2'],
          'timeLimit': 600,
          'shuffleQuestions': true,
        },
        {
          'id': 'quiz3',
          'title': 'Advanced Math Quiz',
          'topics': ['calculus'],
          'difficulty': 'advanced',
          'questionIds': ['q3'],
          'timeLimit': 900,
          'shuffleQuestions': true,
        },
      ];

      // Add quizzes to Firestore
      for (final quiz in quizzes) {
        final quizRef = _firestore.collection('quizzes').doc(quiz['id'] as String);
        batch.set(quizRef, quiz);
      }

      await batch.commit();
      print('Sample quiz data initialized successfully');
    } catch (e) {
      print('Error initializing sample quiz data: $e');
    }
  }
}
