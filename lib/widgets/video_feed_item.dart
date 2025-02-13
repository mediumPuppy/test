import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/video_feed.dart';
import '../services/firestore_service.dart';
import '../services/topic_progress_service.dart';
import 'action_bar.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../screens/ai_explanation_screen.dart';
import '../controllers/json_video_controller.dart';
import 'dart:convert';

class VideoFeedItem extends StatefulWidget {
  final int index;
  final VideoFeed feed;
  final VoidCallback onShare;
  final PageController pageController;

  const VideoFeedItem({
    super.key,
    required this.index,
    required this.feed,
    required this.onShare,
    required this.pageController,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  final _progressService = TopicProgressService();
  StreamSubscription? _positionSubscription;
  late JsonVideoController _jsonController;
  bool _isInitialized = false;
  bool _showTransition = false;
  late ScrollController _innerScrollController;
  bool _hasTriggeredPageTurn = false;
  static const double _scrollThreshold = 100.0;
  double _overscrollAmount = 0.0;

  @override
  void initState() {
    super.initState();
    print(
        'VideoFeedItem: Initializing JSON video controller for video id: ${widget.feed.id}');
    _initializeJsonVideo();
    _innerScrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up the subscription here
    _setupSubscription();
  }

  void _setupSubscription() {
    // Cancel any existing subscription first
    _positionSubscription?.cancel();

    // Only set up new subscription if widget is mounted
    if (mounted) {
      _positionSubscription = _progressService.positionStream.listen(
        (position) {
          // Check mounted state before calling setState
          if (mounted) {
            setState(() {});
          }
        },
        // Add error handling
        onError: (error) {
          print('Error in position stream: $error');
        },
        // Cancel subscription when stream is done
        cancelOnError: true,
      );
    }
  }

  Future<void> _initializeJsonVideo() async {
    _jsonController = JsonVideoController(videoJson: widget.feed.videoJson);
    await _jsonController.initialize();
    _jsonController.play();
    if (mounted) {
      setState(() {
        _isInitialized = _jsonController.isInitialized;
      });
    }
  }

  void _showTransitionScreen() {
    print('Starting transition screen with whiteboard');
    setState(() {
      _showTransition = true;
    });
    Future.delayed(const Duration(seconds: 10), () {
      print('Transition complete');
      if (mounted) {
        setState(() {
          _showTransition = false;
        });
        // Optionally, resume playback here if needed.
      }
    });
  }

  void _handleLike() {
    final firestoreService = FirestoreService();
    firestoreService.toggleVideoLike(widget.feed.id);
  }

  void _handleExplain() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIExplanationScreen(
          videoContext: widget.feed.description,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel subscription first
    _positionSubscription?.cancel();
    _jsonController.dispose();
    _innerScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Use an AnimatedBuilder to rebuild when the JSON controller updates.
        _isInitialized
            ? AnimatedBuilder(
                animation: _jsonController,
                builder: (context, child) {
                  final progressValue =
                      _jsonController.position.inMilliseconds /
                          _jsonController.duration.inMilliseconds;
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is OverscrollNotification &&
                                notification.overscroll < 0 &&
                                _innerScrollController.position.pixels <=
                                    _innerScrollController
                                        .position.minScrollExtent) {
                              if (!_hasTriggeredPageTurn) {
                                _hasTriggeredPageTurn = true;
                                widget.pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            } else if (notification is OverscrollNotification &&
                                notification.overscroll > 0 &&
                                _innerScrollController.position.pixels >=
                                    _innerScrollController
                                        .position.maxScrollExtent) {
                              if (!_hasTriggeredPageTurn) {
                                _hasTriggeredPageTurn = true;
                                widget.pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            } else if (notification is ScrollEndNotification) {
                              _hasTriggeredPageTurn = false;
                            }
                            return false;
                          },
                          child: SingleChildScrollView(
                            controller: _innerScrollController,
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Playing JSON Video:',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  JsonEncoder.withIndent('  ')
                                      .convert(widget.feed.videoJson),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: Colors.grey[700],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.blueAccent),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_jsonController.position.inSeconds}s / ${_jsonController.duration.inSeconds}s',
                                  style: const TextStyle(color: Colors.white),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : const Center(child: CircularProgressIndicator()),
        // Right-side action bar with comment's feature removed.
        Positioned(
          right: 16,
          bottom: 100,
          child: StreamBuilder<bool>(
            stream: firestoreService.isVideoLiked(widget.feed.id),
            builder: (context, likedSnapshot) {
              return StreamBuilder<int>(
                stream: firestoreService.getVideoLikesCount(widget.feed.id),
                builder: (context, likesSnapshot) {
                  return ActionBar(
                    onLike: _handleLike,
                    onShare: widget.onShare,
                    onExplain: _handleExplain,
                    likes: likesSnapshot.data ?? widget.feed.likes,
                    shares: widget.feed.shares,
                    isLiked: likedSnapshot.data ?? false,
                    currentTopics: widget.feed.topics,
                  );
                },
              );
            },
          ),
        ),
        // Bottom description remains unchanged.
        Positioned(
          left: 16,
          right: 72,
          bottom: 16,
          child: Text(
            widget.feed.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        // Removed the progress indicator previously positioned at the bottom.
        // Optionally add a transition overlay here if needed.
        // if (_showTransition) const WhiteboardScreen(),
      ],
    );
  }
}
