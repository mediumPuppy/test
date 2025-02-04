import 'package:cloud_firestore/cloud_firestore.dart';

class VideoFeed {
  final String id;
  final String videoUrl;
  final String creatorId;
  final String description;
  final int likes;
  final int shares;
  final DateTime createdAt;

  VideoFeed({
    required this.id,
    required this.videoUrl,
    required this.creatorId,
    required this.description,
    required this.likes,
    required this.shares,
    required this.createdAt,
  });

  factory VideoFeed.fromFirestore(Map<String, dynamic> data, String id) {
    return VideoFeed(
      id: id,
      videoUrl: data['videoUrl'] ?? '',
      creatorId: data['creatorId'] ?? '',
      description: data['description'] ?? '',
      likes: data['likes'] ?? 0,
      shares: data['shares'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
} 