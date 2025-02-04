import 'package:flutter/material.dart';
import '../models/video_feed.dart';
import 'action_bar.dart';

class VideoFeedItem extends StatelessWidget {
  final int index;
  final VideoFeed feed;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;

  const VideoFeedItem({
    super.key,
    required this.index,
    required this.feed,
    required this.onLike,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder for video
        Container(
          color: Colors.grey[900],
          child: Center(
            child: Text(
              'Video ${feed.id}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        
        // Right side action bar
        Positioned(
          right: 16,
          bottom: 100,
          child: ActionBar(
            onLike: onLike,
            onShare: onShare,
            onComment: onComment,
            likes: feed.likes,
            shares: feed.shares,
          ),
        ),
        
        // Bottom description
        Positioned(
          left: 16,
          right: 72,
          bottom: 16,
          child: Text(
            feed.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
} 