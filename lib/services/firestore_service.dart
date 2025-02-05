import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/data/learning_paths.dart';
import 'package:test/data/sample_videos.dart';
import 'package:test/data/topics.dart';

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
    final userData = userDoc.data() as Map<String, dynamic>;

    final commentData = {
      'userId': userId,
      'userEmail': userData['email'] ?? 'Anonymous',
      'userName': userData['displayName'] ?? userData['email']?.split('@')[0] ?? 'Anonymous',
      'userPhotoUrl': userData['photoUrl'],
      'videoId': videoId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'replyToId': replyToId,
      'mentionedUsers': mentionedUsers,
      'commentLength': comment.length,
    };

    final commentRef = await _db.collection('video_comments').add(commentData);

    // Increment comments count
    await _db.collection('videos').doc(videoId).update({
      'comments': FieldValue.increment(1)
    });

    // Notify mentioned users (you would implement notification logic here)
    for (final username in mentionedUsers) {
      await _db.collection('notifications').add({
        'type': 'mention',
        'userId': userId,
        'mentionedUser': username,
        'mentionedBy': userData['userName'],
        'commentId': commentRef.id,
        'videoId': videoId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    return commentRef;
  }

  Future<void> toggleCommentLike(String commentId) async {
    if (userId == null) return;
    
    final likeRef = _db.collection('comment_likes').doc('${userId}_$commentId');
    final commentRef = _db.collection('video_comments').doc(commentId);

    return _db.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final commentDoc = await transaction.get(commentRef);
      
      if (!likeDoc.exists) {
        // Add like
        transaction.set(likeRef, {
          'userId': userId,
          'commentId': commentId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(commentRef, {
          'likes': (commentDoc.data()?['likes'] ?? 0) + 1
        });
      } else {
        // Remove like
        transaction.delete(likeRef);
        transaction.update(commentRef, {
          'likes': (commentDoc.data()?['likes'] ?? 1) - 1
        });
      }
    });
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

    return _db.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likeRef);
      final videoDoc = await transaction.get(videoRef);
      
      if (!likeDoc.exists) {
        // Add like
        transaction.set(likeRef, {
          'userId': userId,
          'videoId': videoId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(videoRef, {
          'likes': (videoDoc.data()?['likes'] ?? 0) + 1
        });
      } else {
        // Remove like
        transaction.delete(likeRef);
        transaction.update(videoRef, {
          'likes': (videoDoc.data()?['likes'] ?? 1) - 1
        });
      }
    });
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
} 