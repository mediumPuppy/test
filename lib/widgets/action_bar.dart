import 'package:flutter/material.dart';
import '../services/quiz_scheduler_service.dart';
import '../screens/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final int likes;
  final int shares;
  final int comments;
  final bool isLiked;
  final List<String> currentTopics;

  const ActionBar({
    super.key,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.isLiked,
    required this.currentTopics,
  });

  Future<void> _triggerQuiz(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final quizScheduler = QuizSchedulerService();
      final quiz = await quizScheduler.generateQuizForUser(
        userId: user.uid,
        currentTopics: currentTopics,
      );

      if (quiz != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Quiz Ready!'),
            content: const Text(
              'Ready to test your knowledge of recent topics? '
              'This quiz will help reinforce your learning.',
            ),
            actions: [
              TextButton(
                child: const Text('Later'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Start Quiz'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(quiz: quiz, userId: user.uid),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No quiz available at the moment. Complete more topics first!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: likes.toString(),
          onTap: onLike,
          color: isLiked ? Colors.red : Colors.white,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.comment,
          label: comments.toString(),
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.share,
          label: shares.toString(),
          onTap: onShare,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.quiz,
          label: 'Quiz',
          onTap: () => _triggerQuiz(context),
          showCount: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool showCount = true,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: onTap,
        ),
        Text(
          showCount ? label : '',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}