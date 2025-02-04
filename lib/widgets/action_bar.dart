import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final int likes;
  final int shares;

  const ActionBar({
    super.key,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.likes,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          Icons.favorite_border,
          likes.toString(),
          onLike,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          Icons.comment,
          '0',
          onComment,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          Icons.share,
          shares.toString(),
          onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: Colors.white,
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 