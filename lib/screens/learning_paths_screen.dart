import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class LearningPathsScreen extends StatefulWidget {
  @override
  _LearningPathsScreenState createState() => _LearningPathsScreenState();
}

class _LearningPathsScreenState extends State<LearningPathsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;
  String? _selectedPathId;
  StreamSubscription? _pathSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  @override
  void dispose() {
    _pathSubscription?.cancel();
    super.dispose();
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
          .listen((pathId) {
        if (mounted) {
          setState(() {
            _selectedPathId = pathId;
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
      body: StreamBuilder<QuerySnapshot>(
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
              final path = paths[index].data() as Map<String, dynamic>;
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