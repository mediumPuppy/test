import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/data/sample_videos.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // User Methods
  Future<void> createUserProfile(String userId, String email, {String? userName}) {
    return _db.collection('users').doc(userId).set({
      'email': email,
      'userName': userName ?? email.split('@')[0],
      'createdAt': FieldValue.serverTimestamp(),
      'completedTopics': [],
      'progress': {},
    });
  }

  Future<String?> getUserName(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['userName'] as String?;
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
        .where((userName) => userName.isNotEmpty)
        .toList();
  }

  // Learning Path Methods
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserLearningPath(String userId) {
    return _db.collection('users')
        .doc(userId)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningPaths() {
    return _db.collection('learning_paths')
        .orderBy('order')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getLearningPathTopics(String pathId) {
    return _db.collection('learning_paths')
        .doc(pathId)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Future<void> setUserLearningPath(String userId, String pathId) async {
    await _db.collection('users').doc(userId).set({
      'currentPath': pathId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Video Methods
  Stream<QuerySnapshot<Map<String, dynamic>>> getVideosForDifficulty(String difficulty) {
    var query = _db.collection('videos').orderBy('order');
    
    if (difficulty != "All") {
      query = query.where('difficulty', isEqualTo: difficulty);
    }

    return query.withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    ).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getVideosByTopic(String topicId) {
    return _db.collection('videos')
        .where('topic', isEqualTo: topicId)
        .orderBy('orderInPath')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getVideosByLearningPath(String learningPathId) {
    return _db.collection('videos')
        .where('learningPathId', isEqualTo: learningPathId)
        .orderBy('orderInPath')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRandomVideos() {
    return _db.collection('videos')
        .limit(20)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<int> getVideoCommentsCount(String videoId) {
    return _db.collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['comments'] ?? 0);
  }

  Stream<int> getVideoLikesCount(String videoId) {
    return _db.collection('videos')
        .doc(videoId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['likes'] ?? 0);
  }

  // Comment Methods
  Stream<QuerySnapshot<Map<String, dynamic>>> getVideoComments(
    String videoId, {
    required String sortBy,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) {
    var query = _db.collection('video_comments')
        .where('videoId', isEqualTo: videoId)
        .where('replyToId', isNull: true)
        .limit(limit);

    if (sortBy == 'likes') {
      query = query.orderBy('likes', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    ).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCommentReplies(String commentId) {
    return _db.collection('video_comments')
        .where('replyToId', isEqualTo: commentId)
        .orderBy('timestamp', descending: false)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Future<DocumentReference> addVideoComment(
    String videoId,
    String comment, {
    String? replyToId,
    List<String> mentionedUsers = const [],
  }) async {
    if (userId == null) throw Exception('User not signed in');
    
    final userName = await getUserName(userId!);
    if (userName == null) throw Exception('User profile not found');

    final commentData = {
      'videoId': videoId,
      'userId': userId,
      'userName': userName,
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
      for (final mentionedUser in mentionedUsers) {
        await _db.collection('notifications').add({
          'type': 'mention',
          'userId': userId,
          'mentionedUser': mentionedUser,
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

  // Topic Methods
  Stream<QuerySnapshot<Map<String, dynamic>>> getTopics() {
    return _db.collection('topics')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

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

  Stream<QuerySnapshot<Map<String, dynamic>>> getVideosBySelectedTopic(String topicId) {
    return _db.collection('videos')
        .where('topic', isEqualTo: topicId)
        .orderBy('orderInPath')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Future<void> markTopicAsCompleted(String userId, String topicId) async {
    // Update the completedTopics array
    await _db.collection('users').doc(userId).update({
      'completedTopics': FieldValue.arrayUnion([topicId])
    });
    
    // Also store in the subcollection for more detailed tracking
    await _db.collection('users')
        .doc(userId)
        .collection('completedTopics')
        .doc(topicId)
        .set({
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markTopicAsIncomplete(String userId, String topicId) async {
    // Remove from the completedTopics array
    await _db.collection('users').doc(userId).update({
      'completedTopics': FieldValue.arrayRemove([topicId])
    });
    
    // Also remove from the subcollection
    await _db.collection('users')
        .doc(userId)
        .collection('completedTopics')
        .doc(topicId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompletedTopics(String userId) {
    return _db.collection('users')
        .doc(userId)
        .collection('completedTopics')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  // Initialization Methods
  Future<void> initializeSampleData() async {
    final pathsSnapshot = await _db.collection('learning_paths').get();
    if (pathsSnapshot.docs.isEmpty) {
      final batch = _db.batch();
      
      final paths = [
        {
          'title': 'Beginner Mathematics',
          'description': 'Start your journey with basic math concepts',
          'order': 1,
          'topics': ['arithmetic', 'basic_algebra', 'geometry_basics'],
          'totalVideos': 15,
        },
        {
          'title': 'Intermediate Mathematics',
          'description': 'Advance your mathematical understanding',
          'order': 2,
          'topics': ['advanced_algebra', 'trigonometry', 'precalculus'],
          'totalVideos': 20,
        },
        {
          'title': 'Advanced Mathematics',
          'description': 'Master complex mathematical concepts',
          'order': 3,
          'topics': ['calculus', 'linear_algebra', 'statistics'],
          'totalVideos': 25,
        },
      ];

      paths.forEach((path) {
        final docRef = _db.collection('learning_paths').doc();
        batch.set(docRef, path);
      });

      await batch.commit();
    }

    // Upload videos
    for (var video in sampleVideos) {
      await _db.collection('videos').add(video);
    }
  }

  Future<void> initializeTopics() async {
    final topicsSnapshot = await _db.collection('topics').get();
    if (topicsSnapshot.docs.isEmpty) {
      final batch = _db.batch();
      
      final topics = [
        {
          'name': 'arithmetic',
          'prerequisite': null,
          'nextTopics': ['basic_algebra'],
        },
        {
          'name': 'basic_algebra',
          'prerequisite': 'arithmetic',
          'nextTopics': ['geometry_basics', 'advanced_algebra'],
        },
        {
          'name': 'geometry_basics',
          'prerequisite': 'basic_algebra',
          'nextTopics': ['trigonometry'],
        },
        {
          'name': 'advanced_algebra',
          'prerequisite': 'basic_algebra',
          'nextTopics': ['precalculus'],
        },
        {
          'name': 'trigonometry',
          'prerequisite': 'geometry_basics',
          'nextTopics': ['precalculus'],
        },
        {
          'name': 'precalculus',
          'prerequisite': 'advanced_algebra',
          'nextTopics': ['calculus'],
        },
        {
          'name': 'calculus',
          'prerequisite': 'precalculus',
          'nextTopics': ['linear_algebra'],
        },
        {
          'name': 'linear_algebra',
          'prerequisite': 'calculus',
          'nextTopics': ['statistics'],
        },
        {
          'name': 'statistics',
          'prerequisite': 'linear_algebra',
          'nextTopics': [],
        },
      ];

      topics.forEach((topic) {
        final docRef = _db.collection('topics').doc(topic['name'] as String);
        batch.set(docRef, topic);
      });

      await batch.commit();
    }
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

  // Comment Methods
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

  // Topic Methods
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
      await markTopicAsCompleted(userId!, topicId);
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
}