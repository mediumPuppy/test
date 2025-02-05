import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/video_feed_item.dart';
import '../models/video_feed.dart';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _PathVideoFeed extends StatefulWidget {
  final String? selectedPath;

  const _PathVideoFeed({
    Key? key,
    required this.selectedPath,
  }) : super(key: key);

  @override
  State<_PathVideoFeed> createState() => _PathVideoFeedState();
}

class _PathVideoFeedState extends State<_PathVideoFeed> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select a Learning Path',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/learning_paths');
              },
              child: const Text('Browse Learning Paths'),
            ),
          ],
        ),
      );
    }

    print('Building feed for learning path: ${widget.selectedPath}');
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getVideosByLearningPath(widget.selectedPath!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Feed error: ${snapshot.error}');
          print('Feed error stack trace: ${snapshot.stackTrace}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Feed loading...');
          return const Center(child: CircularProgressIndicator());
        }
        
        final videos = snapshot.data?.docs ?? [];
        print('Feed received ${videos.length} videos');
        
        if (videos.isEmpty) {
          return Center(
            child: Text(
              'No videos available for this learning path',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          );
        }
        
        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final videoData = videos[index].data() as Map<String, dynamic>;
            final videoId = videos[index].id;
            print('Building video ${index + 1}/${videos.length}');
            print('Video data: $videoData');
            print('Video ID: $videoId');
            
            try {
              final video = VideoFeed.fromFirestore(videoData, videoId);
              return VideoFeedItem(
                index: index,
                feed: video,
                onShare: () {},
              );
            } catch (e, stackTrace) {
              print('Error building video $videoId:');
              print('Error: $e');
              print('Stack trace: $stackTrace');
              return const SizedBox.shrink(); // Skip invalid videos
            }
          },
        );
      },
    );
  }
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedLearningPath;
  StreamSubscription? _pathSubscription;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserLearningPath();
  }

  void _loadUserLearningPath() {
    final user = _auth.currentUser;
    if (user != null) {
      print('Loading learning path for user: ${user.uid}');
      _pathSubscription = _firestoreService.getUserLearningPath(user.uid).listen(
        (snapshot) {
          if (mounted) {
            final data = snapshot.data();
            print('User data from Firestore: $data');
            setState(() {
              _selectedLearningPath = data?['currentPath'] as String?;
              print('Selected learning path: $_selectedLearningPath');
            });
          }
        },
        onError: (error, stackTrace) {
          print('Error loading learning path:');
          print('Error: $error');
          print('Stack trace: $stackTrace');
        },
      );
    } else {
      print('No user logged in');
    }
  }

  @override
  void dispose() {
    _pathSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _PathVideoFeed(selectedPath: _selectedLearningPath),
      ),
    );
  }
}