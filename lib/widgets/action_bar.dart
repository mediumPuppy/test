import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
