import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../widgets/video_feed_item.dart';
import '../models/video_feed.dart';
import '../widgets/app_drawer.dart';
import '../services/firestore_service.dart';
import '../services/topic_progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _PathVideoFeed extends StatefulWidget {
  final String? selectedPath;

  const _PathVideoFeed({
    required this.selectedPath,
  });

  @override
  State<_PathVideoFeed> createState() => _PathVideoFeedState();
}

class _PathVideoFeedState extends State<_PathVideoFeed> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  final _progressService = TopicProgressService();
  int _lastPage = 0;
  int _lastVideoCount = 0; // Track video count changes

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    if (_pageController.page != null) {
      final currentPage = _pageController.page!.round();
      if (currentPage > _lastPage) {
        // Scrolling down (next video)
        _progressService.incrementPosition();
      } else if (currentPage < _lastPage) {
        // Scrolling up (previous video)
        _progressService.decrementPosition();
      }
      _lastPage = currentPage;
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
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

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getVideosByLearningPath(widget.selectedPath!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Only show loading if we're waiting for the first data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final videos = snapshot.data?.docs ?? [];

        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Congratulations!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve completed all topics in this learning path.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/learning_paths');
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explore New Learning Paths'),
                ),
              ],
            ),
          );
        }

        // Only set total videos when path/topic changes, not during scrolling
        if (_lastVideoCount != videos.length) {
          _lastVideoCount = videos.length;
          _progressService.setTotalVideos(videos.length);
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (index) {
            if (index == 0) {
              // Reset progress when starting a new topic
              // _progressService.setTotalVideos(videos.length);
            }
          },
          itemBuilder: (context, index) {
            final videoData = videos[index].data() as Map<String, dynamic>;
            final videoId = videos[index].id;

            try {
              final video = VideoFeed.fromFirestore(videoData, videoId);
              return VideoFeedItem(
                index: index,
                feed: video,
                onShare: () {},
                pageController: _pageController,
              );
            } catch (e) {
              return const SizedBox.shrink(); // Skip invalid videos
            }
          },
        );
      },
    );
  }
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
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
      _pathSubscription =
          _firestoreService.getUserLearningPath(user.uid).listen(
        (snapshot) {
          if (mounted) {
            final data = snapshot.data();
            setState(() {
              _selectedLearningPath = data?['currentPath'] as String?;
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
