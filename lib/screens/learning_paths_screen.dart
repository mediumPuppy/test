import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/learning_progress_service.dart';
import '../services/quiz_scheduler_service.dart';
import '../screens/quiz_screen.dart';
import '../models/quiz_model.dart';
import 'dart:async';

// the quiz class is undefined below, do we need to import it here? 


class LearningPathsScreen extends StatefulWidget {
  @override
  _LearningPathsScreenState createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LearningProgressService _progressService = LearningProgressService();
  final QuizSchedulerService _quizScheduler = QuizSchedulerService();
  bool _isInitialized = false;
  String? _selectedPathId;
  StreamSubscription? _pathSubscription;
  Timer? _quizCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
    _startQuizCheck();
  }

  @override
  void dispose() {
    _pathSubscription?.cancel();
    _quizCheckTimer?.cancel();
    super.dispose();
  }

  void _startQuizCheck() {
    // Check for quiz triggers every 5 minutes
    _quizCheckTimer = Timer.periodic(Duration(minutes: 5), (_) => _checkForQuiz());
  }

  Future<void> _checkForQuiz() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final shouldTrigger = await _progressService.shouldTriggerQuiz(user.uid);
      if (!shouldTrigger) return;

      final currentTopics = await _getCurrentTopics();
      if (currentTopics.isEmpty) return;

      final quiz = await _quizScheduler.generateQuizForUser(
        userId: user.uid,
        currentTopics: currentTopics,
      );

      if (quiz != null && mounted) {
        _showQuizPrompt(quiz);
      }
    } catch (e) {
      print('Error checking for quiz: $e');
    }
  }

  Future<List<String>> _getCurrentTopics() async {
    if (_selectedPathId == null) return [];

    final pathDoc = await _firestoreService
        .getLearningPathTopics(_selectedPathId!)
        .first;

    final data = pathDoc.data() as Map<String, dynamic>;
    return List<String>.from(data['topics'] ?? []);
  }

  void _showQuizPrompt(Quiz quiz) {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Time for a Progress Check!'),
        content: Text(
          'Ready to test your knowledge of recent topics? '
          'This quiz will help reinforce your learning.',
        ),
        actions: [
          TextButton(
            child: Text('Later'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Start Quiz'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    quiz: quiz,
                    userId: user.uid,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _initializeData() async {
    if (!_isInitialized && mounted) {
      try {
        await _firestoreService.initializeSampleData();
        await _firestoreService.initializeTopics();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing data: $e')),
          );
        }
      }
    }
  }

  void _loadCurrentPath() {
    final user = _auth.currentUser;
    if (user != null) {
      _pathSubscription = _firestoreService
          .getUserLearningPath(user.uid)
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _selectedPathId = snapshot.data()?['currentPath'] as String?;
          });
        }
      });
    }
  }

  Future<void> _selectLearningPath(String pathId) async {
    if (mounted) {
      setState(() {
        _selectedPathId = pathId;
      });
    }
    
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestoreService.setUserLearningPath(currentUser.uid, pathId);
      if (mounted) {
        Navigator.pop(context, pathId);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to select a learning path')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Paths'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeData,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getLearningPaths(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final paths = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: paths.length,
            itemBuilder: (context, index) {
              final path = paths[index].data();
              final pathId = paths[index].id;
              
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(path['title']),
                  subtitle: Text(path['description']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text('${path['totalVideos']} videos'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                      if (_selectedPathId == pathId)
                        Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  onTap: () => _selectLearningPath(pathId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}