import 'package:cloud_firestore/cloud_firestore.dart';

class Skill {
  final String id;
  final String title;
  final String description;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String subject; // 'arithmetic', 'visual_learning', 'geometry', 'practical_math'
  final List<String> prerequisites;
  final String thumbnail;
  final int orderIndex;
  
  // New fields for skill tree
  final List<String> childSkillIds; // For progression branches
  final bool isUnlocked; // Track availability
  final bool isMiniChallenge; // For mini-boss nodes
  final String? prerequisiteSkillId; // Optional parent skill
  final int difficultyLevel; // 1-5 scale for more granular difficulty
  final Map<String, dynamic> rewards; // Completion rewards
  final String? videoUrl; // Optional video content
  final int xpPoints; // Experience points for completing this skill
  final double completionRate; // Percentage of completion (0-100)
  final DateTime? lastAttempted; // When the user last worked on this skill
  
  Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.subject,
    required this.prerequisites,
    required this.thumbnail,
    required this.orderIndex,
    required this.childSkillIds,
    this.isUnlocked = false,
    this.isMiniChallenge = false,
    this.prerequisiteSkillId,
    required this.difficultyLevel,
    required this.rewards,
    this.videoUrl,
    this.xpPoints = 0,
    this.completionRate = 0.0,
    this.lastAttempted,
  });

  factory Skill.fromFirestore(Map<String, dynamic> data, String id) {
    return Skill(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      subject: data['subject'] ?? '',
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      thumbnail: data['thumbnail'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
      childSkillIds: List<String>.from(data['childSkillIds'] ?? []),
      isUnlocked: data['isUnlocked'] ?? false,
      isMiniChallenge: data['isMiniChallenge'] ?? false,
      prerequisiteSkillId: data['prerequisiteSkillId'],
      difficultyLevel: data['difficultyLevel'] ?? 1,
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
      videoUrl: data['videoUrl'],
      xpPoints: data['xpPoints'] ?? 0,
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      lastAttempted: data['lastAttempted'] != null 
          ? (data['lastAttempted'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'subject': subject,
      'prerequisites': prerequisites,
      'thumbnail': thumbnail,
      'orderIndex': orderIndex,
      'childSkillIds': childSkillIds,
      'isUnlocked': isUnlocked,
      'isMiniChallenge': isMiniChallenge,
      'prerequisiteSkillId': prerequisiteSkillId,
      'difficultyLevel': difficultyLevel,
      'rewards': rewards,
      'videoUrl': videoUrl,
      'xpPoints': xpPoints,
      'completionRate': completionRate,
      'lastAttempted': lastAttempted != null ? Timestamp.fromDate(lastAttempted!) : null,
    };
  }

  // Helper method to create a copy of the skill with updated fields
  Skill copyWith({
    String? title,
    String? description,
    String? difficulty,
    String? subject,
    List<String>? prerequisites,
    String? thumbnail,
    int? orderIndex,
    List<String>? childSkillIds,
    bool? isUnlocked,
    bool? isMiniChallenge,
    String? prerequisiteSkillId,
    int? difficultyLevel,
    Map<String, dynamic>? rewards,
    String? videoUrl,
    int? xpPoints,
    double? completionRate,
    DateTime? lastAttempted,
  }) {
    return Skill(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      subject: subject ?? this.subject,
      prerequisites: prerequisites ?? this.prerequisites,
      thumbnail: thumbnail ?? this.thumbnail,
      orderIndex: orderIndex ?? this.orderIndex,
      childSkillIds: childSkillIds ?? this.childSkillIds,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isMiniChallenge: isMiniChallenge ?? this.isMiniChallenge,
      prerequisiteSkillId: prerequisiteSkillId ?? this.prerequisiteSkillId,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      rewards: rewards ?? this.rewards,
      videoUrl: videoUrl ?? this.videoUrl,
      xpPoints: xpPoints ?? this.xpPoints,
      completionRate: completionRate ?? this.completionRate,
      lastAttempted: lastAttempted ?? this.lastAttempted,
    );
  }
} 