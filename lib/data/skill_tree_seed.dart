import 'package:cloud_firestore/cloud_firestore.dart';

final List<Map<String, dynamic>> skillTreeData = [
  // Level 1: Foundation Skills
  {
    'id': 'num_recog',
    'title': 'Number Recognition',
    'description': 'Learn to recognize numbers 0-9',
    'difficulty': 'beginner',
    'subject': 'arithmetic',
    'prerequisites': [],
    'thumbnail': 'assets/images/skills/number_recognition.png',
    'orderIndex': 1,
    'childSkillIds': ['count_basic'],
    'isUnlocked': true,
    'isMiniChallenge': false,
    'prerequisiteSkillId': null,
    'difficultyLevel': 1,
    'rewards': {
      'xp': 50,
      'badge': 'Number Explorer',
      'badge_icon': 'assets/badges/number_explorer.png'
    },
    'videoUrl': 'https://example.com/videos/number_recognition',
    'xpPoints': 50,
    'completionRate': 0.0,
  },
  {
    'id': 'count_basic',
    'title': 'Counting Basics',
    'description': 'Count objects and numbers from 1 to 20',
    'difficulty': 'beginner',
    'subject': 'arithmetic',
    'prerequisites': ['num_recog'],
    'thumbnail': 'assets/images/skills/counting_basics.png',
    'orderIndex': 2,
    'childSkillIds': ['add_found', 'sub_found', 'teens'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'num_recog',
    'difficultyLevel': 1,
    'rewards': {
      'xp': 75,
      'badge': 'Counting Champion',
      'badge_icon': 'assets/badges/counting_champion.png'
    },
    'videoUrl': 'https://example.com/videos/counting_basics',
    'xpPoints': 75,
    'completionRate': 0.0,
  },

  // Level 2: Basic Operations Branch
  {
    'id': 'add_found',
    'title': 'Addition Foundations',
    'description': 'Learn to add single-digit numbers',
    'difficulty': 'intermediate',
    'subject': 'arithmetic',
    'prerequisites': ['count_basic'],
    'thumbnail': 'assets/images/skills/addition_foundations.png',
    'orderIndex': 3,
    'childSkillIds': ['add_double', 'word_basic'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'count_basic',
    'difficultyLevel': 2,
    'rewards': {
      'xp': 100,
      'badge': 'Addition Apprentice',
      'badge_icon': 'assets/badges/addition_apprentice.png'
    },
    'videoUrl': 'https://example.com/videos/addition_foundations',
    'xpPoints': 100,
    'completionRate': 0.0,
  },
  {
    'id': 'sub_found',
    'title': 'Subtraction Foundations',
    'description': 'Learn to subtract single-digit numbers',
    'difficulty': 'intermediate',
    'subject': 'arithmetic',
    'prerequisites': ['count_basic'],
    'thumbnail': 'assets/images/skills/subtraction_foundations.png',
    'orderIndex': 4,
    'childSkillIds': ['sub_double', 'word_basic'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'count_basic',
    'difficultyLevel': 2,
    'rewards': {
      'xp': 100,
      'badge': 'Subtraction Starter',
      'badge_icon': 'assets/badges/subtraction_starter.png'
    },
    'videoUrl': 'https://example.com/videos/subtraction_foundations',
    'xpPoints': 100,
    'completionRate': 0.0,
  },

  // Level 3: Advanced Operations & Patterns
  {
    'id': 'pattern_basic',
    'title': 'Pattern Recognition',
    'description': 'Identify and create number patterns',
    'difficulty': 'intermediate',
    'subject': 'visual_learning',
    'prerequisites': ['count_100'],
    'thumbnail': 'assets/images/skills/patterns.png',
    'orderIndex': 8,
    'childSkillIds': ['pattern_adv', 'skip_count'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'count_100',
    'difficultyLevel': 3,
    'rewards': {
      'xp': 150,
      'badge': 'Pattern Pro',
      'badge_icon': 'assets/badges/pattern_pro.png',
      'special_effect': 'pattern_burst'
    },
    'videoUrl': 'https://example.com/videos/patterns',
    'xpPoints': 150,
  },

  // Geometry Branch
  {
    'id': 'shapes_2d',
    'title': '2D Shapes',
    'description': 'Learn basic 2D shapes and their properties',
    'difficulty': 'intermediate',
    'subject': 'geometry',
    'prerequisites': ['count_basic'],
    'thumbnail': 'assets/images/skills/shapes_2d.png',
    'orderIndex': 9,
    'childSkillIds': ['shapes_3d', 'symmetry'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'count_basic',
    'difficultyLevel': 2,
    'rewards': {
      'xp': 125,
      'badge': 'Shape Shifter',
      'badge_icon': 'assets/badges/shape_shifter.png'
    },
    'videoUrl': 'https://example.com/videos/2d_shapes',
    'xpPoints': 125,
  },

  // Practical Math Branch
  {
    'id': 'time_basic',
    'title': 'Telling Time',
    'description': 'Learn to read analog and digital clocks',
    'difficulty': 'intermediate',
    'subject': 'practical_math',
    'prerequisites': ['count_basic'],
    'thumbnail': 'assets/images/skills/time_basic.png',
    'orderIndex': 10,
    'childSkillIds': ['time_adv', 'calendar'],
    'isUnlocked': false,
    'isMiniChallenge': false,
    'prerequisiteSkillId': 'count_basic',
    'difficultyLevel': 2,
    'rewards': {
      'xp': 150,
      'badge': 'Time Keeper',
      'badge_icon': 'assets/badges/time_keeper.png'
    },
    'videoUrl': 'https://example.com/videos/telling_time',
    'xpPoints': 150,
  },

  // Advanced Concepts
  {
    'id': 'fractions_intro',
    'title': 'Introduction to Fractions',
    'description': 'Learn about basic fractions and parts of a whole',
    'difficulty': 'advanced',
    'subject': 'arithmetic',
    'prerequisites': ['mult_intro'],
    'thumbnail': 'assets/images/skills/fractions_intro.png',
    'orderIndex': 11,
    'childSkillIds': ['fractions_comp', 'fractions_add'],
    'isUnlocked': false,
    'isMiniChallenge': true,
    'prerequisiteSkillId': 'mult_intro',
    'difficultyLevel': 4,
    'rewards': {
      'xp': 300,
      'badge': 'Fraction Friend',
      'badge_icon': 'assets/badges/fraction_friend.png',
      'special_effect': 'fraction_slice'
    },
    'videoUrl': 'https://example.com/videos/fractions_intro',
    'xpPoints': 300,
  },

  // Mini Game Challenges
  {
    'id': 'number_ninja',
    'title': 'Number Ninja Challenge',
    'description': 'Test your speed with number facts!',
    'difficulty': 'advanced',
    'subject': 'arithmetic',
    'prerequisites': ['add_double', 'sub_double'],
    'thumbnail': 'assets/images/skills/number_ninja.png',
    'orderIndex': 12,
    'childSkillIds': [],
    'isUnlocked': false,
    'isMiniChallenge': true,
    'prerequisiteSkillId': 'add_double',
    'difficultyLevel': 4,
    'rewards': {
      'xp': 500,
      'badge': 'Number Ninja Master',
      'badge_icon': 'assets/badges/number_ninja.png',
      'special_effect': 'ninja_stars',
      'unlock_message': 'You\'ve become a true Number Ninja!'
    },
    'videoUrl': null, // No video - pure challenge
    'xpPoints': 500,
  },

  // Continue with all other skills following the same pattern...
  // I'll show one example of a mini-challenge skill:
  {
    'id': 'add_double',
    'title': 'Double-Digit Addition',
    'description': 'Add numbers up to 100',
    'difficulty': 'advanced',
    'subject': 'arithmetic',
    'prerequisites': ['add_found', 'teens'],
    'thumbnail': 'assets/images/skills/double_digit_addition.png',
    'orderIndex': 7,
    'childSkillIds': ['mult_intro'],
    'isUnlocked': false,
    'isMiniChallenge': true,
    'prerequisiteSkillId': 'add_found',
    'difficultyLevel': 3,
    'rewards': {
      'xp': 200,
      'badge': 'Addition Master',
      'badge_icon': 'assets/badges/addition_master.png',
      'special_effect': 'sparkle_burst',
      'unlock_message': 'You\'ve mastered addition! Time for multiplication!'
    },
    'videoUrl': 'https://example.com/videos/double_digit_addition',
    'xpPoints': 200,
    'completionRate': 0.0,
  },
];

// Achievement definitions with more categories and rewards
final List<Map<String, dynamic>> achievements = [
  {
    'id': 'math_explorer',
    'title': 'Math Explorer',
    'description': 'Complete all Level 1 skills',
    'requiredSkills': ['num_recog', 'count_basic'],
    'reward': {
      'xp': 300,
      'badge': 'Math Explorer Supreme',
      'badge_icon': 'assets/badges/math_explorer_supreme.png',
      'special_effect': 'explorer_burst'
    }
  },
  {
    'id': 'speed_demon',
    'title': 'Speed Demon',
    'description': 'Complete any skill with perfect score under 2 minutes',
    'type': 'performance',
    'reward': {
      'xp': 250,
      'badge': 'Lightning Calculator',
      'badge_icon': 'assets/badges/lightning_calculator.png',
      'special_effect': 'lightning_strike'
    }
  },
  {
    'id': 'perfect_streak',
    'title': 'Perfect Streak',
    'description': 'Complete 5 skills with 100% accuracy',
    'type': 'accuracy',
    'reward': {
      'xp': 400,
      'badge': 'Precision Master',
      'badge_icon': 'assets/badges/precision_master.png',
      'special_effect': 'precision_sparkle'
    }
  },
  // ... Add more achievements ...
];

// Special Events and Challenges
final List<Map<String, dynamic>> specialEvents = [
  {
    'id': 'summer_math',
    'title': 'Summer Math Challenge',
    'description': 'Complete special summer-themed math problems',
    'duration': 14, // days
    'rewards': {
      'xp_multiplier': 2.0,
      'special_badge': 'Summer Math Champion',
      'badge_icon': 'assets/badges/summer_champion.png'
    }
  },
  // ... Add more events ...
];

// Skill Categories for filtering and organization
final List<Map<String, dynamic>> skillCategories = [
  {
    'id': 'arithmetic',
    'name': 'Number Operations',
    'color': '#FF4081',
    'icon': 'assets/icons/arithmetic.png'
  },
  {
    'id': 'geometry',
    'name': 'Shapes and Space',
    'color': '#2196F3',
    'icon': 'assets/icons/geometry.png'
  },
  // ... Add more categories ...
];

// Helper function to initialize the skill tree in Firestore
Future<void> initializeSkillTree(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  
  // Add skills
  for (final skill in skillTreeData) {
    final docRef = firestore.collection('skills').doc(skill['id']);
    batch.set(docRef, skill);
  }
  
  // Add achievements
  for (final achievement in achievements) {
    final docRef = firestore.collection('achievements').doc(achievement['id']);
    batch.set(docRef, achievement);
  }
  
  // Add special events
  for (final event in specialEvents) {
    final docRef = firestore.collection('special_events').doc(event['id']);
    batch.set(docRef, event);
  }
  
  // Add skill categories
  for (final category in skillCategories) {
    final docRef = firestore.collection('skill_categories').doc(category['id']);
    batch.set(docRef, category);
  }
  
  await batch.commit();
}

// Helper function to reset user progress (for testing)
Future<void> resetUserProgress(FirebaseFirestore firestore, String userId) async {
  await firestore.collection('users').doc(userId).update({
    'unlockedSkills': ['num_recog'],
    'completedSkills': [],
    'skillProgress': {},
    'achievements': [],
    'totalXP': 0
  });
} 