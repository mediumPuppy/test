import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  multipleChoice,
  openEnded,
  visualProblem,
  wordProblem,
  mathExpression,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

enum MathExpressionFormat {
  basic,
  algebraic,
  geometric,
  calculus,
  custom,
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final DifficultyLevel difficulty;
  final List<String> topics;
  final Map<String, dynamic> metadata;
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;
  final Map<String, String>? commonMistakes;
  final String? visualAid;
  final MathExpressionFormat? expressionFormat;
  final List<String>? acceptableVariations;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.difficulty,
    required this.topics,
    required this.metadata,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.commonMistakes,
    this.visualAid,
    this.expressionFormat,
    this.acceptableVariations,
  }) {
    if (type == QuestionType.multipleChoice && (options == null || options!.length < 4)) {
      throw ArgumentError('Multiple choice questions must have at least 4 options');
    }
    if (type == QuestionType.mathExpression && expressionFormat == null) {
      throw ArgumentError('Math expression questions must specify an expression format');
    }
  }

  // Factory constructor to create from Firestore
  factory QuizQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizQuestion(
      id: doc.id,
      question: data['question'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == data['type'],
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == data['difficulty'],
      ),
      topics: List<String>.from(data['topics']),
      metadata: data['metadata'] ?? {},
      options: data['options'] != null ? List<String>.from(data['options']) : null,
      correctAnswer: data['correctAnswer'],
      explanation: data['explanation'],
      commonMistakes: data['commonMistakes'] != null 
          ? Map<String, String>.from(data['commonMistakes'])
          : null,
      visualAid: data['visualAid'],
      expressionFormat: data['expressionFormat'] != null 
          ? MathExpressionFormat.values.firstWhere(
              (e) => e.toString() == data['expressionFormat'],
            )
          : null,
      acceptableVariations: data['acceptableVariations'] != null 
          ? List<String>.from(data['acceptableVariations'])
          : null,
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'type': type.toString(),
      'difficulty': difficulty.toString(),
      'topics': topics,
      'metadata': metadata,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'commonMistakes': commonMistakes,
      'visualAid': visualAid,
      'expressionFormat': expressionFormat?.toString(),
      'acceptableVariations': acceptableVariations,
    };
  }
}

class Quiz {
  final String id;
  final String title;
  final List<String> topics;
  final DifficultyLevel difficulty;
  final List<QuizQuestion> questions;
  final int timeLimit;
  final bool shuffleQuestions;
  final Map<String, dynamic> metadata;

  Quiz({
    required this.id,
    required this.title,
    required this.topics,
    required this.difficulty,
    required this.questions,
    required this.timeLimit,
    this.shuffleQuestions = true,
    this.metadata = const {},
  });

  // Factory constructor to create from Firestore
  factory Quiz.fromFirestore(DocumentSnapshot doc, List<QuizQuestion> questions) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'],
      topics: List<String>.from(data['topics']),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == data['difficulty'],
      ),
      questions: questions,
      timeLimit: data['timeLimit'],
      shuffleQuestions: data['shuffleQuestions'] ?? true,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'topics': topics,
      'difficulty': difficulty.toString(),
      'timeLimit': timeLimit,
      'shuffleQuestions': shuffleQuestions,
      'metadata': metadata,
      'questionIds': questions.map((q) => q.id).toList(),
    };
  }
}
