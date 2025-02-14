import 'package:flutter/material.dart';
import 'dart:async';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/math_expression_service.dart';
import '../models/video_feed.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String userId;
  final List<VideoFeed>? videoContext;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.userId,
    this.videoContext,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final MathExpressionService _mathExpressionService = MathExpressionService();
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  final Map<String, bool> _isCorrect = {};
  bool _showExplanation = false;
  Timer? _timer;
  int _timeRemaining = 0;
  final TextEditingController _openEndedController = TextEditingController();
  final bool _showDebugInfo = true; // Add debug flag
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeQuiz();
  }

  void _initializeQuiz() {
    setState(() {
      _timeRemaining = 60; // Set to 1 minute (60 seconds)
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  Widget _buildContextHeader() {
    if (widget.videoContext == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Based on your recent lessons:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...widget.videoContext!.map((video) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '• ${video.title ?? "Untitled"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (question.visualAid != null)
                Image.network(
                  question.visualAid!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              Text(
                question.question,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (question.type == QuestionType.multipleChoice)
                _buildMultipleChoiceOptions(question)
              else
                _buildOpenEndedInput(),
              if (_showExplanation && question.explanation != null)
                _buildExplanation(question),
              if (_showDebugInfo)
                Text(
                  'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length} '
                  '(${question.difficulty})',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(QuizQuestion question) {
    return Column(
      children: question.options!.map((option) {
        final isSelected = _answers[question.id] == option;
        final showCorrect = _showExplanation;
        final isCorrect = option == question.correctAnswer;

        return ListTile(
          title: Text(option),
          leading: Radio<String>(
            value: option,
            groupValue: _answers[question.id],
            onChanged: _showExplanation
                ? null
                : (value) {
                    setState(() {
                      _answers[question.id] = value!;
                      _isCorrect[question.id] =
                          (value == question.correctAnswer);
                    });
                  },
          ),
          tileColor: showCorrect
              ? (isCorrect ? Colors.green.withOpacity(0.2) : null)
              : (isSelected ? Colors.blue.withOpacity(0.1) : null),
        );
      }).toList(),
    );
  }

  Widget _buildOpenEndedInput() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    return TextField(
      controller: _openEndedController,
      decoration: InputDecoration(
        hintText: 'Enter your answer',
        border: OutlineInputBorder(),
      ),
      enabled: !_showExplanation,
      onChanged: (value) {
        _answers[question.id] = value;
        // For open-ended questions, we'll do a more flexible comparison
        _isCorrect[question.id] =
            _compareAnswers(value, question.correctAnswer);
      },
    );
  }

  bool _compareAnswers(String userAnswer, String correctAnswer) {
    final question = widget.quiz.questions[_currentQuestionIndex];

    if (question.type == QuestionType.mathExpression) {
      return _mathExpressionService.areExpressionsEquivalent(
          userAnswer,
          correctAnswer,
          question.expressionFormat!,
          question.acceptableVariations);
    }

    // Fall back to simple comparison for non-math questions
    return userAnswer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();
  }

  Widget _buildExplanation(QuizQuestion question) {
    final isCorrect = _isCorrect[question.id] ?? false;
    final userAnswer = _answers[question.id];
    final mistake = question.commonMistakes?[userAnswer];

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Correct!' : 'Incorrect',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explanation:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(question.explanation ?? 'No explanation available.'),
          if (!isCorrect && mistake != null) ...[
            SizedBox(height: 8),
            Text(
              'Common Mistake:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(mistake),
          ],
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();

    // Calculate actual time spent
    final endTime = DateTime.now();
    final timeSpent = endTime.difference(_startTime);

    int score = _isCorrect.values.where((correct) => correct).length;
    await _quizService.recordQuizAttempt(
      userId: widget.userId,
      quizId: widget.quiz.id,
      answers: _answers,
      isCorrect: _isCorrect,
      score: score,
      totalPossible: widget.quiz.questions.length,
      timeSpent: timeSpent,
    );

    // Show results dialog with actual time spent
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Quiz Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $score out of ${widget.quiz.questions.length}'),
            const SizedBox(height: 8),
            Text(
              'Time taken: ${timeSpent.inMinutes}:${(timeSpent.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Review Answers'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showExplanation = true;
              });
            },
          ),
          TextButton(
            child: Text('Done'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format remaining time as MM:SS
    final minutes = (_timeRemaining ~/ 60).toString().padLeft(1, '0');
    final seconds = (_timeRemaining % 60).toString().padLeft(2, '0');
    final timeDisplay = '$minutes:$seconds';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          if (_showDebugInfo)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showDebugDialog,
            ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _timeRemaining <= 10 ? Colors.red.withOpacity(0.2) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                timeDisplay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeRemaining <= 10 ? Colors.red : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            backgroundColor: Colors.grey[200],
          ),
          _buildContextHeader(),
          Expanded(
            child: _buildQuestionCard(
                widget.quiz.questions[_currentQuestionIndex]),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
                    child: Text('Previous'),
                  )
                else
                  SizedBox(width: 80),
                Text(
                  '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                  style: TextStyle(fontSize: 16),
                ),
                if (_currentQuestionIndex < widget.quiz.questions.length - 1)
                  ElevatedButton(
                    onPressed: _answers[widget
                                .quiz.questions[_currentQuestionIndex].id] !=
                            null
                        ? () {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          }
                        : null,
                    child: Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _showExplanation
                        ? () => Navigator.pop(context)
                        : (_answers[widget.quiz.questions[_currentQuestionIndex]
                                    .id] !=
                                null
                            ? _submitQuiz
                            : null),
                    child: Text(_showExplanation ? 'Done' : 'Submit'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quiz ID: ${widget.quiz.id}'),
              Text('Topics: ${widget.quiz.topics.join(", ")}'),
              Text('Difficulty: ${widget.quiz.difficulty}'),
              Text('Total Questions: ${widget.quiz.questions.length}'),
              Text('Time Limit: ${widget.quiz.timeLimit} seconds'),
              Text('Remaining Time: $_timeRemaining seconds'),
              if (widget.videoContext != null) ...[
                const Divider(),
                const Text('Video Context:'),
                ...widget.videoContext!.map((v) => Text(
                      '• ${v.title ?? "Untitled"} (${v.topics.join(", ")})',
                    )),
              ],
              const Divider(),
              Text('Current Question: ${_currentQuestionIndex + 1}'),
              Text('Selected Answers: ${_answers.values.join(", ")}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _openEndedController.dispose();
    super.dispose();
  }
}
