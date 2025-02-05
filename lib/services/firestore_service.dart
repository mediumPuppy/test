import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/data/learning_paths.dart';
import 'package:test/data/sample_videos.dart';
import 'package:test/data/topics.dart';
import 'package:test/data/skill_tree_seed.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // User Methods
  Future<void> createUserProfile(String userId, String email) {
    return _db.collection('users').doc(userId).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'completedTopics': [],
      'progress': {},
    });
  }

  // Video Methods
  Stream<QuerySnapshot> getVideosForDifficulty(String difficulty) {
    if (difficulty == "All") {
      return _db.collection('videos').orderBy('order').snapshots();
    }
    return _db.collection('videos')
        .where('difficulty', isEqualTo: difficulty)
        .orderBy('order')
        .snapshots();
  }

  // Learning Path Methods
  Future<void> initializeSampleData() async {
    // Upload learning paths
    for (var path in learningPaths) {
      await _db.collection('learning_paths').doc(path['id']).set(path);
    }

    // Upload videos
    for (var video in sampleVideos) {
      await _db.collection('videos').add(video);
    }
  }

  Stream<QuerySnapshot> getLearningPaths() {
    return _db.collection('learning_paths').snapshots();
  }

  // Progress Methods
  Future<void> updateProgress(String learningPathId, double progress) {
    return _db.collection('users').doc(userId).update({
      'progress.$learningPathId': progress,
    });
  }

  // Rating Methods
  Future<void> rateVideo(String videoId, bool understood) {
    return _db.collection('videoRatings').add({
      'userId': userId,
      'videoId': videoId,
      'understood': understood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Comments Methods
  Stream<QuerySnapshot> getVideoComments(
    String videoId, {
    required String sortBy,  // 'timestamp' or 'likes'
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) {
    Query query = _db.collection('video_comments')
        .where('videoId', isEqualTo: videoId)
        .where('replyToId', isNull: true);  // Only get top-level comments

    // Sort based on user preference
    if (sortBy == 'likes') {
      query = query.orderBy('likes', descending: true)
          .orderBy('timestamp', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.limit(limit).snapshots();
  }

  Future<List<String>> getMentionSuggestions(String prefix) async {
    if (prefix.isEmpty) return [];
    
    final userQuery = await _db.collection('users')
        .where('userName', isGreaterThanOrEqualTo: prefix)
        .where('userName', isLessThan: '${prefix}z')
        .limit(5)
        .get();

    return userQuery.docs
        .map((doc) => doc.data()['userName'] as String)
        .toList();
  }

  Future<DocumentReference> addVideoComment(
    String videoId,
    String comment, {
    String? replyToId,
    List<String> mentionedUsers = const [],
  }) async {
    if (userId == null) throw Exception('User must be logged in to comment');

    // Get user info
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) throw Exception('User profile not found');
    
    final userData = userDoc.data() as Map<String, dynamic>;
    final userName = userData['displayName'] ?? 
                    userData['email']?.toString().split('@')[0] ?? 
                    'Anonymous';

    final commentData = {
      'userId': userId,
      'userName': userName,
      'userEmail': userData['email'],
      'userPhotoUrl': userData['photoUrl'],
      'videoId': videoId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'replyToId': replyToId,
      'mentionedUsers': mentionedUsers,
    };

    try {
      final commentRef = await _db.collection('video_comments').add(commentData);

      // Increment comments count
      await _db.collection('videos').doc(videoId).update({
        'comments': FieldValue.increment(1)
      });

      // Notify mentioned users
      for (final username in mentionedUsers) {
        await _db.collection('notifications').add({
          'type': 'mention',
          'userId': userId,
          'mentionedUser': username,
          'mentionedBy': userName,
          'commentId': commentRef.id,
          'videoId': videoId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      return commentRef;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    if (userId == null) return;
    
    final likeRef = _db.collection('comment_likes').doc('${userId}_$commentId');
    final commentRef = _db.collection('video_comments').doc(commentId);

    try {
      await _db.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        if (!likeDoc.exists) {
          // Add like
          transaction.set(likeRef, {
            'userId': userId,
            'commentId': commentId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(commentRef, {
            'likes': FieldValue.increment(1)
          });
        } else {
          // Remove like
          transaction.delete(likeRef);
          transaction.update(commentRef, {
            'likes': FieldValue.increment(-1)
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  Stream<bool> isCommentLiked(String commentId) {
    if (userId == null) return Stream.value(false);
    
    return _db.collection('comment_likes')
        .doc('${userId}_$commentId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<QuerySnapshot> getCommentReplies(String commentId) {
    return _db.collection('video_comments')
        .where('replyToId', isEqualTo: commentId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Stream<int> getVideoCommentsCount(String videoId) {
    return _db.collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['comments'] ?? 0);
  }

  // Topic Methods
  Future<void> initializeTopics() async {
    print('Starting to initialize topics...');
    print('Topics to initialize: ${topics.length}');
    
    for (var topic in topics) {
      print('Initializing topic: ${topic['id']}');
      await _db.collection('topics').doc(topic['id']).set(topic);
    }
    
    print('Topics initialization complete');
  }

  Stream<QuerySnapshot> getTopics() {
    print('Getting topics stream');
    return _db.collection('topics').snapshots();
  }

  Stream<QuerySnapshot> getVideosByTopic(String topicId) {
    return _db.collection('videos')
        .where('topic', isEqualTo: topicId)
        .orderBy('orderInPath')
        .snapshots();
  }

  // Add these methods to FirestoreService class
  Stream<QuerySnapshot> getVideosByLearningPath(String learningPathId) {
    return _db.collection('videos')
        .where('learningPathId', isEqualTo: learningPathId)
        .orderBy('orderInPath')
        .snapshots();
  }

  Stream<QuerySnapshot> getRandomVideos() {
    // Simplified query to avoid needing a composite index
    return _db.collection('videos')
        .limit(20)
        .snapshots();
  }

  // Method to update selected learning path
  Future<void> setUserLearningPath(String userId, String learningPathId) async {
    await _db.collection('users').doc(userId).set({
      'currentLearningPath': learningPathId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String?> getUserLearningPath(String userId) {
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['currentLearningPath'] as String?);
  }

  // Selected Topic Methods
  Future<void> setUserSelectedTopic(String userId, String topicId) async {
    await _db.collection('users').doc(userId).set({
      'selectedTopic': topicId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String?> getUserSelectedTopic(String userId) {
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['selectedTopic'] as String?);
  }

  Stream<QuerySnapshot> getVideosBySelectedTopic(String topicId) {
    return _db.collection('videos')
        .where('topic', isEqualTo: topicId)
        .orderBy('orderInPath')
        .snapshots();
  }

  // New Topic Methods
  Future<void> markTopicAsCompleted(String topicId) async {
    if (userId == null) return;
    
    await _db.collection('users').doc(userId).update({
      'completedTopics': FieldValue.arrayUnion([topicId])
    });
  }

  Future<void> markTopicAsIncomplete(String topicId) async {
    if (userId == null) return;
    
    await _db.collection('users').doc(userId).update({
      'completedTopics': FieldValue.arrayRemove([topicId])
    });
  }

  Stream<List<String>> getUserCompletedTopics() {
    if (userId == null) return Stream.value([]);
    
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => 
            List<String>.from(snapshot.data()?['completedTopics'] ?? []));
  }

  Future<bool> canAccessTopic(String topicId) async {
    if (userId == null) return false;

    // Get the topic to check prerequisites
    final topicDoc = await _db.collection('topics').doc(topicId).get();
    if (!topicDoc.exists) return false;

    final topic = topicDoc.data() as Map<String, dynamic>;
    final prerequisites = List<String>.from(topic['prerequisites'] ?? []);
    
    if (prerequisites.isEmpty) return true;

    // Get user's completed topics
    final userDoc = await _db.collection('users').doc(userId).get();
    final completedTopics = List<String>.from(userDoc.data()?['completedTopics'] ?? []);

    // Check if all prerequisites are completed
    return prerequisites.every((prereq) => completedTopics.contains(prereq));
  }

  Future<double> getTopicProgress(String topicId) async {
    if (userId == null) return 0.0;

    final userDoc = await _db.collection('users').doc(userId).get();
    final progress = (userDoc.data()?['progress'] ?? {}) as Map<String, dynamic>;
    
    return (progress[topicId] ?? 0.0) as double;
  }

  Future<void> updateTopicProgress(String topicId, double progress) async {
    if (userId == null) return;

    await _db.collection('users').doc(userId).update({
      'progress.$topicId': progress,
    });

    // If progress is 100%, mark topic as completed
    if (progress >= 100) {
      await markTopicAsCompleted(topicId);
    }
  }

  // Video Likes Methods
  Future<void> toggleVideoLike(String videoId) async {
    if (userId == null) return;
    
    final likeRef = _db.collection('video_likes').doc('${userId}_$videoId');
    final videoRef = _db.collection('videos').doc(videoId);

    try {
      // First check if the video document exists
      final videoDoc = await videoRef.get();
      if (!videoDoc.exists) {
        throw Exception('Video not found');
      }

      await _db.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        
        if (!likeDoc.exists) {
          // Add like
          transaction.set(likeRef, {
            'userId': userId,
            'videoId': videoId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(videoRef, {
            'likes': FieldValue.increment(1)
          });
        } else {
          // Remove like
          transaction.delete(likeRef);
          transaction.update(videoRef, {
            'likes': FieldValue.increment(-1)
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle video like: $e');
    }
  }

  Stream<bool> isVideoLiked(String videoId) {
    if (userId == null) return Stream.value(false);
    
    return _db.collection('video_likes')
        .doc('${userId}_$videoId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> getVideoLikesCount(String videoId) {
    return _db.collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['likes'] ?? 0);
  }

  // Skill Tree Methods
  Future<void> initializeSkills(List<Map<String, dynamic>> initialSkills) async {
    print('Starting to initialize skills...');
    
    for (var skill in initialSkills) {
      print('Initializing skill: ${skill['id']}');
      await _db.collection('skills').doc(skill['id']).set(skill);
    }
    
    print('Skills initialization complete');
  }

  Stream<QuerySnapshot> getSkills() {
    return _db.collection('skills')
        .orderBy('orderIndex')
        .snapshots()
        .distinct((prev, next) {
          // Only emit if the data has actually changed
          if (prev.docs.length != next.docs.length) return false;
          for (var i = 0; i < prev.docs.length; i++) {
            if (prev.docs[i].data().toString() != next.docs[i].data().toString()) {
              return false;
            }
          }
          return true;
        });
  }

  Future<void> updateSkillProgress(String skillId, double progress) async {
    if (userId == null) return;

    await _db.collection('users').doc(userId).update({
      'skillProgress.$skillId': progress,
      'skillProgress.$skillId.lastAttempted': FieldValue.serverTimestamp(),
    });

    // If progress is 100%, unlock child skills
    if (progress >= 100) {
      await _unlockChildSkills(skillId);
    }
  }

  Future<void> _unlockChildSkills(String skillId) async {
    if (userId == null) return;

    // Get the skill to find child skills
    final skillDoc = await _db.collection('skills').doc(skillId).get();
    if (!skillDoc.exists) return;

    final skill = skillDoc.data() as Map<String, dynamic>;
    final childSkillIds = List<String>.from(skill['childSkillIds'] ?? []);

    // Update user's unlocked skills
    await _db.collection('users').doc(userId).update({
      'unlockedSkills': FieldValue.arrayUnion(childSkillIds)
    });
  }

  Stream<List<String>> getUserUnlockedSkills() {
    if (userId == null) return Stream.value([]);
    
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => 
            List<String>.from(snapshot.data()?['unlockedSkills'] ?? []));
  }

  Future<Map<String, double>> getSkillProgress() async {
    if (userId == null) return {};

    final userDoc = await _db.collection('users').doc(userId).get();
    final progress = (userDoc.data()?['skillProgress'] ?? {}) as Map<String, dynamic>;
    
    return Map<String, double>.from(
      progress.map((key, value) => MapEntry(key, (value['progress'] ?? 0.0) as double))
    );
  }

  Future<bool> canAccessSkill(String skillId) async {
    if (userId == null) return false;

    // Get the skill to check prerequisites
    final skillDoc = await _db.collection('skills').doc(skillId).get();
    if (!skillDoc.exists) return false;

    final skill = skillDoc.data() as Map<String, dynamic>;
    final prerequisiteId = skill['prerequisiteSkillId'] as String?;
    
    if (prerequisiteId == null) return true;

    // Get user's skill progress
    final userDoc = await _db.collection('users').doc(userId).get();
    final progress = (userDoc.data()?['skillProgress'] ?? {}) as Map<String, dynamic>;
    
    // Check if prerequisite is completed (progress >= 100)
    return (progress[prerequisiteId]?['progress'] ?? 0.0) >= 100;
  }

  Future<void> unlockInitialSkills() async {
    if (userId == null) return;

    // Get skills with no prerequisites
    final initialSkills = await _db.collection('skills')
        .where('prerequisiteSkillId', isNull: true)
        .get();

    final initialSkillIds = initialSkills.docs.map((doc) => doc.id).toList();

    // Update user's unlocked skills
    await _db.collection('users').doc(userId).update({
      'unlockedSkills': FieldValue.arrayUnion(initialSkillIds)
    });
  }

  Future<void> updateSkillRewards(String skillId, Map<String, dynamic> rewards) async {
    await _db.collection('skills').doc(skillId).update({
      'rewards': rewards,
    });
  }

  Future<void> updateUserXP(int xpPoints) async {
    if (userId == null) return;

    await _db.collection('users').doc(userId).update({
      'totalXP': FieldValue.increment(xpPoints),
    });
  }

  Stream<int> getUserTotalXP() {
    if (userId == null) return Stream.value(0);
    
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['totalXP'] ?? 0);
  }

  Future<void> completeSkill(String skillId) async {
    if (userId == null) return;

    // Get the skill to get XP points
    final skillDoc = await _db.collection('skills').doc(skillId).get();
    if (!skillDoc.exists) return;

    final skill = skillDoc.data() as Map<String, dynamic>;
    final xpPoints = skill['xpPoints'] as int? ?? 0;

    // Update user's completed skills and XP in a transaction
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection('users').doc(userId);
      
      transaction.update(userRef, {
        'completedSkills': FieldValue.arrayUnion([skillId]),
        'totalXP': FieldValue.increment(xpPoints),
        'skillProgress.$skillId.completionRate': 100.0,
        'skillProgress.$skillId.lastAttempted': FieldValue.serverTimestamp(),
      });
    });

    // Unlock child skills
    await _unlockChildSkills(skillId);
  }

  Stream<List<String>> getUserCompletedSkills() {
    if (userId == null) return Stream.value([]);
    
    return _db.collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => 
            List<String>.from(snapshot.data()?['completedSkills'] ?? []));
  }

  Future<void> initializeSkillTree() async {
    try {
      print('Starting skill tree initialization...');
      
      // Initialize skills from seed data
      final batch = FirebaseFirestore.instance.batch();
      
      for (var skill in skillTreeData) {
        final docRef = _db.collection('skills').doc(skill['id']);
        batch.set(docRef, skill);
      }
      
      await batch.commit();
      print('Skill tree initialization complete');
      
      // Initialize first skill for all existing users
      final usersSnapshot = await _db.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        await _db.collection('users').doc(userDoc.id).update({
          'unlockedSkills': FieldValue.arrayUnion(['num_recog']),
          'skillProgress.num_recog': {
            'isUnlocked': true,
            'completionRate': 0.0,
            'lastAttempted': null
          }
        });
      }
    } catch (e) {
      print('Error initializing skill tree: $e');
      rethrow;
    }
  }
} 