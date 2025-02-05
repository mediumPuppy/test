class Topic {
  final String id;
  final String title;
  final String description;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final String subject; // 'arithmetic', 'visual_learning', 'geometry', 'practical_math'
  final List<String> prerequisites;
  final String thumbnail;
  final int orderIndex;

  Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.subject,
    required this.prerequisites,
    required this.thumbnail,
    required this.orderIndex,
  });

  factory Topic.fromFirestore(Map<String, dynamic> data, String id) {
    return Topic(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      subject: data['subject'] ?? '',
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      thumbnail: data['thumbnail'] ?? '',
      orderIndex: data['orderIndex'] ?? 0,
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
    };
  }
} 