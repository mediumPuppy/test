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
  String? _selectedTopic;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserLearningPath();
    _loadUserSelectedTopic();
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

  void _loadUserSelectedTopic() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestoreService.getUserSelectedTopic(user.uid).listen((topicId) {
        setState(() {
          _selectedTopic = topicId;
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

  Widget _buildNoTopicSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select a Topic',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/topics');
            },
            child: const Text('Browse Topics'),
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
              // Path Tab (formerly Up Next)
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
                              onShare: () {},
                            );
                          },
                        );
                      },
                    ),
              
              // Topic Tab (formerly Explore)
              _selectedTopic == null
                  ? _buildNoTopicSelected()
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getVideosBySelectedTopic(_selectedTopic!),
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
                              onShare: () {},
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
                    Tab(text: 'Path'),
                    Tab(text: 'Topic'),
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