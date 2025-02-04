import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Stream<QuerySnapshot> getLearningPaths() {
    return _db.collection('learningPaths').snapshots();
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
} 