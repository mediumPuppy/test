import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedLearningPath;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserLearningPath();
  }

  void _loadUserLearningPath() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestoreService.getUserLearningPath(user.uid).listen((pathId) {
        setState(() {
          _selectedLearningPath = pathId;
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildNoPathSelected() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Feed
          TabBarView(
            controller: _tabController,
            children: [
              // Up Next Tab
              _selectedLearningPath == null
                  ? _buildNoPathSelected()
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getVideosByLearningPath(_selectedLearningPath!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final videos = snapshot.data?.docs ?? [];
                        return PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final videoData = videos[index].data() as Map<String, dynamic>;
                            final video = VideoFeed.fromFirestore(videoData, videos[index].id);
                            return VideoFeedItem(
                              index: index,
                              feed: video,
                              onLike: () {},
                              onShare: () {},
                              onComment: () {},
                            );
                          },
                        );
                      },
                    ),
              
              // Explore Tab (Random Videos)
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getRandomVideos(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final videos = snapshot.data?.docs ?? [];
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final videoData = videos[index].data() as Map<String, dynamic>;
                      final video = VideoFeed.fromFirestore(videoData, videos[index].id);
                      return VideoFeedItem(
                        index: index,
                        feed: video,
                        onLike: () {},
                        onShare: () {},
                        onComment: () {},
                      );
                    },
                  );
                },
              ),
            ],
          ),
          
          // Top Navigation
          SafeArea(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Up Next'),
                    Tab(text: 'Explore'),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 