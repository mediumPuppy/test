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
      return [];
    }
  }

  // Get a stream of available quizzes
  Stream<List<Quiz>> getAvailableQuizzes() {
    try {
      return _firestore.collection('quizzes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final quizzes = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data();
            final questionIds = List<String>.from(data['questionIds'] ?? []);
            
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
      });
    } catch (e) {
      return Stream.value([]);
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
          'question': 'What is 2 + 2?',
          'type': QuestionType.multipleChoice.toString(),
          'difficulty': DifficultyLevel.beginner.toString(),
          'topics': ['arithmetic'],
          'metadata': {'category': 'basic_math'},
          'options': ['3', '4', '5', '6'],
          'correctAnswer': '4',
          'explanation': 'Basic addition: 2 + 2 = 4',
          'commonMistakes': {
            '3': 'Make sure to count carefully',
            '5': 'You might have counted one number twice'
          },
        },
        {
          'id': 'q2',
          'question': 'Solve for x: 2x + 4 = 12',
          'type': QuestionType.multipleChoice.toString(),
          'difficulty': DifficultyLevel.intermediate.toString(),
          'topics': ['basic_algebra'],
          'metadata': {'category': 'algebra'},
          'options': ['2', '4', '6', '8'],
          'correctAnswer': '4',
          'explanation': 'Subtract 4 from both sides: 2x = 8, then divide by 2: x = 4',
          'commonMistakes': {
            '2': 'Did you forget to divide by 2?',
            '8': 'Did you forget to subtract 4?'
          },
        },
        {
          'id': 'q3',
          'question': 'What is the derivative of x²?',
          'type': QuestionType.multipleChoice.toString(),
          'difficulty': DifficultyLevel.advanced.toString(),
          'topics': ['calculus'],
          'metadata': {'category': 'calculus'},
          'options': ['x²', '2x', '2', '0'],
          'correctAnswer': '2x',
          'explanation': 'The power rule states that the derivative of x^n is nx^(n-1)',
          'commonMistakes': {
            'x²': 'This is the original function, not its derivative',
            '2': 'You forgot to keep the x term'
          },
        },
      ];

      // Add questions to Firestore
      for (final question in questions) {
        final questionRef = _firestore.collection('questions').doc(question['id'] as String);
        final questionData = Map<String, dynamic>.from(question);
        questionData.remove('id');
        batch.set(questionRef, questionData);
      }

      // Create sample quizzes
      final timestamp = FieldValue.serverTimestamp();
      final quizzes = [
        {
          'id': 'quiz1',
          'title': 'Basic Math Quiz',
          'topics': ['arithmetic'],
          'difficulty': DifficultyLevel.beginner.toString(),
          'questionIds': ['q1'],
          'timeLimit': 300,
          'shuffleQuestions': true,
          'metadata': {'level': 1, 'points': 10},
          'createdAt': timestamp,
        },
        {
          'id': 'quiz2',
          'title': 'Algebra Quiz',
          'topics': ['basic_algebra'],
          'difficulty': DifficultyLevel.intermediate.toString(),
          'questionIds': ['q2'],
          'timeLimit': 600,
          'shuffleQuestions': true,
          'metadata': {'level': 2, 'points': 20},
          'createdAt': timestamp,
        },
        {
          'id': 'quiz3',
          'title': 'Advanced Math Quiz',
          'topics': ['calculus'],
          'difficulty': DifficultyLevel.advanced.toString(),
          'questionIds': ['q3'],
          'timeLimit': 900,
          'shuffleQuestions': true,
          'metadata': {'level': 3, 'points': 30},
          'createdAt': timestamp,
        },
      ];

      // Add quizzes to Firestore
      for (final quiz in quizzes) {
        final quizRef = _firestore.collection('quizzes').doc(quiz['id'] as String);
        final quizData = Map<String, dynamic>.from(quiz);
        quizData.remove('id');
        batch.set(quizRef, quizData);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
