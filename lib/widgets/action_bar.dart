import 'package:flutter/material.dart';
import '../screens/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/quiz_service.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onExplain;
  final int likes;
  final int shares;
  final bool isLiked;
  final List<String> currentTopics;

  const ActionBar({
    super.key,
    required this.onLike,
    required this.onShare,
    required this.onExplain,
    required this.likes,
    required this.shares,
    required this.isLiked,
    required this.currentTopics,
  });

  Future<void> _triggerQuiz(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final quizService = QuizService();
      final quizzes = await quizService.getQuizzesForTopics(
        topics: ['arithmetic'], // Hardcode to match the quiz in Firestore
        limit: 1,
      );

      if (quizzes.isNotEmpty && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizScreen(quiz: quizzes[0], userId: user.uid),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No quiz available at the moment. Complete more topics first!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quiz: $e')),
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
          labelStyle: const TextStyle(color: Colors.black),
          onTap: onLike,
          color: isLiked ? Colors.red : Colors.black,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.quiz_outlined,
          label: 'Quiz',
          onTap: () => _triggerQuiz(context),
          showCount: false,
          color: Colors.black,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.lightbulb_outlined,
          label: 'Explain',
          onTap: onExplain,
          showCount: false,
          color: Colors.black,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool showCount = true,
    TextStyle? labelStyle,
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
          style: labelStyle,
        ),
      ],
    );
  }
}
