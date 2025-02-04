import 'package:flutter/material.dart';
import '../widgets/video_feed_item.dart';
import '../models/video_feed.dart';
import '../widgets/app_drawer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final List<VideoFeed> _dummyFeeds = List.generate(
    20,
    (index) => VideoFeed(
      id: index.toString(),
      videoUrl: '',
      creatorId: 'teacher${index % 5 + 1}', // Cycles through teacher1-5
      description: 'Math Lesson ${index + 1}',
      likes: index * 10, // Some fake engagement numbers
      shares: index * 5,
      createdAt: DateTime.now().subtract(Duration(days: index)), // Older as index increases
    ),
  );
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Feed
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _dummyFeeds.length,
            itemBuilder: (context, index) {
              return VideoFeedItem(
                index: index,
                feed: _dummyFeeds[index],
                onLike: () {},
                onShare: () {},
                onComment: () {},
              );
            },
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