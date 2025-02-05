import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/data/sample_videos.dart';
import './learning_progress_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LearningProgressService _progressService = LearningProgressService();

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
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLearningPathTopics(String pathId) {
    return _db.collection('learning_paths')
        .doc(pathId)
        .collection('topics')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .orderBy('order')
        .snapshots();
  }

  Future<void> setCurrentLearningPath(String userId, String pathId) {
    return _db.collection('users').doc(userId).update({
      'currentPath': pathId,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserLearningPath(String userId, String pathId) async {
    await _db.collection('users').doc(userId).set({
      'currentPath': pathId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> getTopicCount(String pathId) async {
    final snapshot = await _db
        .collection('learning_paths')
        .doc(pathId)
        .collection('topics')
        .count()
        .get();
    return snapshot.count ?? 0;
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
        .where('topicId', isEqualTo: topicId)
        .orderBy('orderInPath')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getVideosByLearningPath(String learningPathId) async* {
    print('Getting videos for learning path: $learningPathId');
    
    // First, get the learning path topics in order
    final topicsQuery = await _db.collection('learning_paths')
        .doc(learningPathId)
        .collection('topics')
        .orderBy('order')
        .get();
    
    final topics = topicsQuery.docs;
    print('Found ${topics.length} topics in learning path');
    
    if (topics.isEmpty) {
      print('No topics found in learning path');
      yield* _db.collection('videos')
          .where('learningPathId', isEqualTo: learningPathId)
          .limit(0)
          .snapshots();
      return;
    }

    // Get user's progress
    final userId = _auth.currentUser?.uid;
    print('Current user ID: $userId');
    
    if (userId == null) {
      print('No user logged in');
      yield* _db.collection('videos')
          .where('learningPathId', isEqualTo: learningPathId)
          .limit(0)
          .snapshots();
      return;
    }

    // Get user's progress using LearningProgressService
    final progress = await _progressService.getUserProgress(userId);
    final completedTopics = (progress['topicsCompleted'] as Map<String, dynamic>? ?? {}).keys.toSet();
    print('User completed topics: $completedTopics');

    // Find the first incomplete topic
    String? currentTopicId;
    for (final topic in topics) {
      final topicId = topic.id;
      final topicData = topic.data();
      final topicName = topicData['name'] as String? ?? 'Unnamed Topic';
      print('Checking topic: $topicId - $topicName');
      
      if (!completedTopics.contains(topicId)) {
        currentTopicId = topicId;
        print('Found first incomplete topic: $topicId');
        break;
      }
    }

    if (currentTopicId == null) {
      // All topics completed, show videos from the last topic
      currentTopicId = topics.last.id;
      print('All topics completed, using last topic: $currentTopicId');
    }

    print('Getting videos for topic: $currentTopicId');
    
    // Get videos for the current topic
    yield* _db.collection('videos')
        .where('topicId', isEqualTo: currentTopicId)
        .where('learningPathId', isEqualTo: learningPathId)
        .snapshots()
        .map((snapshot) {
          print('Received snapshot with ${snapshot.docs.length} videos');
          print('Video IDs: ${snapshot.docs.map((d) => d.id).join(', ')}');
          
          final sortedDocs = List.from(snapshot.docs)
            ..sort((a, b) {
              final orderA = (a.data() as Map<String, dynamic>)['orderInPath'] as int? ?? 0;
              final orderB = (b.data() as Map<String, dynamic>)['orderInPath'] as int? ?? 0;
              return orderA.compareTo(orderB);
            });
            
          print('Sorted video order: ${sortedDocs.map((d) => '${d.id}(${(d.data() as Map<String, dynamic>)['orderInPath']})').join(', ')}');
          return snapshot;
        });
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
    print('Starting sample data initialization...');
    
    // Clear existing data first
    print('Clearing existing data...');
    final batch = _db.batch();
    
    // Clear videos
    final existingVideos = await _db.collection('videos').get();
    for (final doc in existingVideos.docs) {
      batch.delete(doc.reference);
    }
    
    // Clear learning paths and their subcollections
    final existingPaths = await _db.collection('learning_paths').get();
    for (final pathDoc in existingPaths.docs) {
      // Clear topics subcollection
      final topics = await pathDoc.reference.collection('topics').get();
      for (final topicDoc in topics.docs) {
        batch.delete(topicDoc.reference);
      }
      batch.delete(pathDoc.reference);
    }
    
    // Clear topics
    final existingTopics = await _db.collection('topics').get();
    for (final doc in existingTopics.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('Existing data cleared');
    
    // Initialize fresh data
    await initializeSampleLearningPaths();
    await initializeTopics();

    print('Initializing videos...');
    
    // First, get all learning paths to map their IDs
    final learningPathsSnapshot = await _db.collection('learning_paths').get();
    final learningPathMap = Map.fromEntries(
      learningPathsSnapshot.docs.map((doc) => MapEntry(doc.data()['id'] as String, doc.id))
    );
    print('Learning path mapping: $learningPathMap');
    
    // Then get all topics to map their IDs
    final topicsSnapshot = await _db.collection('topics').get();
    final topicMap = Map.fromEntries(
      topicsSnapshot.docs.map((doc) => MapEntry(doc.data()['id'] as String, doc.id))
    );
    print('Topic mapping: $topicMap');
    
    // Add sample videos with mapped IDs
    for (var video in sampleVideos) {
      final videoData = Map<String, dynamic>.from(video);
      
      // Map the old topic ID to the new one
      final oldTopicId = videoData['topicId'] as String;
      final newTopicId = topicMap[oldTopicId];
      if (newTopicId == null) {
        print('Warning: No mapping found for topic ID: $oldTopicId');
        continue;
      }
      videoData['topicId'] = newTopicId;
      
      // Map the old learning path ID to the new one
      final oldPathId = videoData['learningPathId'] as String;
      final newPathId = learningPathMap[oldPathId];
      if (newPathId == null) {
        print('Warning: No mapping found for learning path ID: $oldPathId');
        continue;
      }
      videoData['learningPathId'] = newPathId;
      
      // Convert DateTime to Timestamp for Firestore
      videoData['createdAt'] = Timestamp.fromDate(videoData['createdAt'] as DateTime);
      
      await _db.collection('videos').add(videoData);
      print('Added video: ${videoData['title']} to path: ${videoData['learningPathId']} and topic: ${videoData['topicId']}');
    }
    print('Sample data initialization complete');
  }

  Future<void> initializeSampleLearningPaths() async {
    // Check if learning paths already exist
    final existingPaths = await _db.collection('learning_paths').get();
    if (!existingPaths.docs.isEmpty) {
      print('Learning paths already initialized');
      return;
    }

    print('Initializing learning paths...');
    final learningPaths = [
      {
        'creatorId': 'teacher1',
        'description': 'Learn fundamental algebra concepts',
        'difficulty': 'beginner',
        'estimatedHours': 0.5,
        'id': 'algebra_basics',
        'prerequisites': [],
        'subject': 'algebra',
        'thumbnail': '',
        'title': 'Algebra Basics',
        'totalVideos': 7,
        'topics': [
          {
            'id': 'variables_expressions',
            'name': 'Variables and Expressions',
            'description': 'Understanding variables and basic expressions',
            'subject': 'algebra',
            'prerequisite': null,
            'order': 1,
          },
          {
            'id': 'equations',
            'name': 'Equations',
            'description': 'Solving basic equations',
            'subject': 'algebra',
            'prerequisite': 'variables_expressions',
            'order': 2,
          },
          {
            'id': 'inequalities',
            'name': 'Inequalities',
            'description': 'Understanding and solving inequalities',
            'subject': 'algebra',
            'prerequisite': 'equations',
            'order': 3,
          }
        ]
      },
      {
        'creatorId': 'teacher1',
        'description': 'Master basic geometric concepts',
        'difficulty': 'beginner',
        'estimatedHours': 0.5,
        'id': 'geometry_fundamentals',
        'prerequisites': ['algebra_basics'],
        'subject': 'geometry',
        'thumbnail': '',
        'title': 'Geometry Fundamentals',
        'totalVideos': 6,
        'topics': [
          {
            'id': 'basic_shapes',
            'name': 'Basic Shapes',
            'description': 'Understanding basic geometric shapes',
            'subject': 'geometry',
            'prerequisite': null,
            'order': 1,
          },
          {
            'id': 'area_perimeter',
            'name': 'Area and Perimeter',
            'description': 'Calculating area and perimeter',
            'subject': 'geometry',
            'prerequisite': 'basic_shapes',
            'order': 2,
          }
        ]
      }
    ];

    print('Initializing learning paths...');
    for (final path in learningPaths) {
      final topics = List<Map<String, dynamic>>.from(path['topics'] as List);
      path.remove('topics');
      
      final pathRef = await _db.collection('learning_paths').add(path);
      print('Created learning path: ${path['title']}');
      
      for (final topic in topics) {
        final topicId = topic['id'] as String;
        await _db
            .collection('learning_paths')
            .doc(pathRef.id)
            .collection('topics')
            .doc(topicId)  
            .set(topic);
        print('Added topic: ${topic['name']} with ID: $topicId to ${path['title']}');
      }
    }
  }

  Future<void> initializeTopics() async {
    // Check if topics already exist
    final topicsSnapshot = await _db.collection('topics').get();
    if (!topicsSnapshot.docs.isEmpty) {
      print('Topics already initialized');
      return;
    }

    print('Initializing topics...');
    final batch = _db.batch();
    
    final topics = [
      {
        'id': 'variables_expressions',
        'name': 'Variables and Expressions',
        'description': 'Understanding variables and basic expressions',
        'subject': 'algebra',
        'prerequisite': null,
        'order': 1,
      },
      {
        'id': 'equations',
        'name': 'Equations',
        'description': 'Solving basic equations',
        'subject': 'algebra',
        'prerequisite': 'variables_expressions',
        'order': 2,
      },
      {
        'id': 'inequalities',
        'name': 'Inequalities',
        'description': 'Understanding and solving inequalities',
        'subject': 'algebra',
        'prerequisite': 'equations',
        'order': 3,
      },
      {
        'id': 'basic_shapes',
        'name': 'Basic Shapes',
        'description': 'Understanding basic geometric shapes',
        'subject': 'geometry',
        'prerequisite': null,
        'order': 1,
      },
      {
        'id': 'area_perimeter',
        'name': 'Area and Perimeter',
        'description': 'Calculating area and perimeter',
        'subject': 'geometry',
        'prerequisite': 'basic_shapes',
        'order': 2,
      }
    ];

    for (final topic in topics) {
      final id = topic['id'] as String;
      batch.set(_db.collection('topics').doc(id), topic);
    }

    await batch.commit();
    print('Topics initialized');
  }

  Future<void> temporaryUpdateLearningPaths() async {
    print('Starting temporary learning path update...');
    
    final pathsSnapshot = await _db.collection('learning_paths').get();
    
    for (final doc in pathsSnapshot.docs) {
      final data = doc.data();
      if (data['title'] == 'Algebra Basics') {
        await doc.reference.update({
          'creatorId': 'teacher1',
          'description': 'Learn fundamental algebra concepts',
          'difficulty': 'beginner',
          'estimatedHours': 0.5,
          'id': 'algebra_basics',
          'prerequisites': [],
          'subject': 'algebra',
          'thumbnail': '',
          'title': 'Algebra Basics',
          'totalVideos': 7
        });
        print('Updated Algebra Basics path');
      } else if (data['title'] == 'Geometry Fundamentals') {
        await doc.reference.update({
          'creatorId': 'teacher1',
          'description': 'Master basic geometric concepts',
          'difficulty': 'beginner',
          'estimatedHours': 0.5,
          'id': 'geometry_fundamentals',
          'prerequisites': ['algebra_basics'],
          'subject': 'geometry',
          'thumbnail': '',
          'title': 'Geometry Fundamentals',
          'totalVideos': 6
        });
        print('Updated Geometry Fundamentals path');
      }
    }
    print('Temporary learning path update complete');
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