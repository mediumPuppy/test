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
  final String topicId;
  final String subject;
  final String skillLevel;
  final List<String> prerequisites;
  final List<String> topics;
  final int estimatedMinutes;
  final bool hasQuiz;
  double progress;
  bool isCompleted;
  final Map<String, dynamic> videoJson;

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
    required this.topicId,
    required this.subject,
    required this.skillLevel,
    required this.prerequisites,
    required this.estimatedMinutes,
    required this.hasQuiz,
    List<String>? topics,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.videoJson,
  }) : topics = topics ?? [topicId];

  factory VideoFeed.fromFirestore(Map<String, dynamic> data, String id) {
    final List<String> topics = List<String>.from(data['topics'] ?? []);
    final String topicId = data['topicId'] ?? '';

    // If no topics are specified, use the single topic field
    if (topics.isEmpty && topicId.isNotEmpty) {
      topics.add(topicId);
    }

    return VideoFeed(
      id: id,
      videoUrl: data['videoUrl'] ?? '',
      creatorId: data['creatorId'] ?? '',
      description: data['description'] ?? '',
      likes: data['likes'] ?? 0,
      shares: data['shares'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      learningPathId: data['learningPathId'] ?? '',
      orderInPath: data['orderInPath'] ?? 0,
      title: data['title'] ?? '',
      topicId: topicId,
      subject: data['subject'] ?? '',
      skillLevel: data['skillLevel'] ?? '',
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      estimatedMinutes: data['estimatedMinutes'] ?? 5,
      hasQuiz: data['hasQuiz'] ?? false,
      topics: topics,
      progress: data['progress'] ?? 0.0,
      isCompleted: data['isCompleted'] ?? false,
      videoJson: data['videoJson'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'creatorId': creatorId,
      'description': description,
      'likes': likes,
      'shares': shares,
      'createdAt': createdAt.toIso8601String(),
      'learningPathId': learningPathId,
      'orderInPath': orderInPath,
      'title': title,
      'topicId': topicId,
      'subject': subject,
      'skillLevel': skillLevel,
      'prerequisites': prerequisites,
      'topics': topics,
      'estimatedMinutes': estimatedMinutes,
      'hasQuiz': hasQuiz,
      'progress': progress,
      'isCompleted': isCompleted,
      'videoJson': videoJson,
    };
  }
}
