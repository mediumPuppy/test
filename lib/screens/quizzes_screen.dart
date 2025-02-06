import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizzesScreen extends StatelessWidget {
  final QuizService _quizService = QuizService();

  QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: _quizService.getAvailableQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final quizzes = snapshot.data ?? [];

          if (quizzes.isEmpty) {
            return const Center(
              child: Text('No quizzes available at the moment'),
            );
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.quiz),
                  title: Text(quiz.title),
                  subtitle: Text(
                    'Topics: ${quiz.topics.join(", ")}\n'
                    'Difficulty: ${quiz.difficulty.name}',
                  ),
                  trailing: Text('${quiz.questions.length} questions'),
                  onTap: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            quiz: quiz,
                            userId: user.uid,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
