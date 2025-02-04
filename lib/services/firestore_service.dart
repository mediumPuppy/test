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
  Stream<QuerySnapshot> getVideoComments(String videoId) {
    return _db.collection('comments')
        .where('videoId', isEqualTo: videoId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addComment(String videoId, String text) {
    return _db.collection('comments').add({
      'userId': userId,
      'videoId': videoId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Topic Methods
  Future<void> initializeTopics() async {
    for (var topic in topics) {
      await _db.collection('topics').doc(topic['id']).set(topic);
    }
  }

  Stream<QuerySnapshot> getTopics() {
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
} 