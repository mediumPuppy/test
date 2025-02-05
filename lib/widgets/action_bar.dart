import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final int likes;
  final int shares;
  final int comments;
  final bool isLiked;

  const ActionBar({
    super.key,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.likes,
    required this.shares,
    required this.comments,
    required this.isLiked,
  });

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
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 