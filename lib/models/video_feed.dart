import 'package:cloud_firestore/cloud_firestore.dart';

class VideoFeed {
  final String id;
  final String videoUrl;
  final String creatorId;
  final String description;
  final int likes;
  final int shares;
  final DateTime createdAt;
  final String learningPathId;
  final int orderInPath;
  final String title;
  final String topic;
  final String subject;
  final String skillLevel;
  final List<String> prerequisites;

  VideoFeed({
    required this.id,
    required this.videoUrl,
    required this.creatorId,
    required this.description,
    required this.likes,
    required this.shares,
    required this.createdAt,
    required this.learningPathId,
    required this.orderInPath,
    required this.title,
    required this.topic,
    required this.subject,
    required this.skillLevel,
    required this.prerequisites,
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
      learningPathId: data['learningPathId'] ?? '',
      orderInPath: data['orderInPath'] ?? 0,
      title: data['title'] ?? '',
      topic: data['topic'] ?? '',
      subject: data['subject'] ?? '',
      skillLevel: data['skillLevel'] ?? '',
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
    );
  }
} 