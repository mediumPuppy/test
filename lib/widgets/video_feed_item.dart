import 'package:flutter/material.dart';
import 'dart:async';
import '../models/video_feed.dart';
import '../services/firestore_service.dart';
import '../services/topic_progress_service.dart';
import 'action_bar.dart';
import '../screens/ai_explanation_screen.dart';
import '../controllers/json_video_controller.dart';
import '../widgets/geometry_drawing_painter.dart';
import '../models/drawing_spec_models.dart';
import '../utils/handwriting_util.dart';
import '../services/speech_service.dart';

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

class _VideoFeedItemState extends State<VideoFeedItem>
    with SingleTickerProviderStateMixin {
  final _progressService = TopicProgressService();
  final SpeechService _speechService = SpeechService();
  StreamSubscription? _positionSubscription;
  late JsonVideoController _jsonController;
  bool _isInitialized = false;
  bool _showTransition = false;
  late ScrollController _innerScrollController;
  bool _hasTriggeredPageTurn = false;
  static const double _scrollThreshold = 100.0;
  double _overscrollAmount = 0.0;
  late AnimationController _animationController;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _jsonController = JsonVideoController(videoJson: widget.feed.videoJson);
    _initializeJsonVideo();
    _innerScrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(
          seconds: (widget.feed.videoJson['instructions']['timing']
                  .last['endTime'] as num)
              .round()),
    );

    // Add delay before starting animation and audio
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _animationController.forward();
        _startSpeech();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _positionSubscription?.cancel();
    _positionSubscription = _progressService.positionStream.listen((position) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeJsonVideo() async {
    await _jsonController.initialize();
    if (!mounted) return;
    setState(() {
      _isInitialized = _jsonController.isInitialized;
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
          videoContext: widget.feed,
          videoObject: widget.feed.toJson(),
        ),
      ),
    );
  }

  void _togglePlayPause() {
    print(
        '_togglePlayPause called - animation state: ${_animationController.isAnimating}');
    if (_animationController.isAnimating) {
      print('Stopping animation and audio');
      _animationController.stop();
      _speechService.pause();
      _isSpeaking = false;
    } else {
      print('Starting animation from: ${_animationController.value}');
      _animationController.forward(from: _animationController.value);
      if (!_isSpeaking) {
        print('Starting speech since not currently speaking');
        _startSpeech();
      } else {
        print('Resuming existing speech');
        _speechService.resume();
      }
    }
  }

  void _startSpeech() async {
    print('_startSpeech called');
    final script =
        widget.feed.videoJson['instructions']['speech']['script'] as String;
    print(
        'Speech script: ${script.substring(0, script.length > 50 ? 50 : script.length)}...');
    if (script.isNotEmpty) {
      print('Script is not empty, setting _isSpeaking to true');
      setState(() {
        _isSpeaking = true;
      });
      print('Attempting to play audio');
      try {
        await _speechService.speak(script);
        print('Audio playback started');

        // Listen for playback completion
        if (_speechService.isPlaying) {
          while (_speechService.isPlaying) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          print('Audio playback completed naturally');
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        }
      } catch (e) {
        print('Error playing audio: $e');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      }
    } else {
      print('Script is empty, skipping audio playback');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final currentTime = _animationController.value *
                  widget
                      .feed.videoJson['instructions']['timing'].last['endTime']
                      .toDouble();
              return Container(
                color: Colors.white,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      if (_innerScrollController.position.pixels >=
                              _innerScrollController.position.maxScrollExtent &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent) {
                        _overscrollAmount += notification.scrollDelta ?? 0;
                      } else if (_innerScrollController.position.pixels <=
                              _innerScrollController.position.minScrollExtent &&
                          notification.metrics.pixels <=
                              notification.metrics.minScrollExtent) {
                        _overscrollAmount += notification.scrollDelta ?? 0;
                      } else {
                        _overscrollAmount = 0;
                      }

                      if (_overscrollAmount.abs() >= _scrollThreshold &&
                          !_hasTriggeredPageTurn) {
                        _hasTriggeredPageTurn = true;
                        if (_overscrollAmount > 0) {
                          widget.pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          widget.pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        }
                        _overscrollAmount = 0;
                      }
                    } else if (notification is ScrollEndNotification) {
                      _hasTriggeredPageTurn = false;
                      _overscrollAmount = 0;
                    }
                    return false;
                  },
                  child: CustomPaint(
                    painter: GeometryDrawingPainter(
                      currentTime: currentTime,
                      specification: GeometryDrawingSpec(
                        stages: List<DrawingStage>.from(widget
                            .feed.videoJson['instructions']['timing']
                            .map((stage) => DrawingStage(
                                  stage: stage['stage'],
                                  startTime:
                                      (stage['startTime'] as num).toDouble(),
                                  endTime: (stage['endTime'] as num).toDouble(),
                                  description: stage['description'],
                                  easing: stage['easing'],
                                ))),
                        shapes: List<GeometryShape>.from(widget
                            .feed.videoJson['instructions']['drawing']['shapes']
                            .map((shape) => GeometryShape(
                                  id: shape['id'],
                                  vertices: shape['vertices']
                                          ?.map<Offset>((v) => Offset(
                                              (v['x'] as num).toDouble(),
                                              (v['y'] as num).toDouble()))
                                          ?.toList() ??
                                      [],
                                  path: shape['path'],
                                  style: shape['style'],
                                  strokeWidth:
                                      (shape['strokeWidth'] as num).toDouble(),
                                  color: _hexToColor(shape['color']),
                                  fadeInRange: (shape['fadeInRange'] as List)
                                      .map<double>((v) => (v as num).toDouble())
                                      .toList(),
                                ))),
                        labels: List<GeometryLabel>.from(widget
                            .feed.videoJson['instructions']['drawing']['labels']
                            .map((label) => GeometryLabel(
                                  id: label['id'],
                                  text: label['text'],
                                  position: Offset(
                                      (label['position']['x'] as num)
                                          .toDouble(),
                                      (label['position']['y'] as num)
                                          .toDouble()),
                                  color: _hexToColor(label['color']),
                                  fadeInRange: (label['fadeInRange'] as List)
                                      .map<double>((v) => (v as num).toDouble())
                                      .toList(),
                                  drawingCommands: label['handwritten'] == true
                                      ? generateHandwrittenCommands(
                                          label['text'],
                                          Offset(
                                              (label['position']['x'] as num)
                                                  .toDouble(),
                                              (label['position']['y'] as num)
                                                  .toDouble()))
                                      : null,
                                ))),
                        speechScript: widget.feed.videoJson['instructions']
                                ['speech']['script'] ??
                            '',
                        speechPacing: (widget.feed.videoJson['instructions']
                                        ['speech']['pacing']
                                    as Map<String, dynamic>? ??
                                {})
                            .map((key, value) =>
                                MapEntry(key, (value as num).toDouble())),
                      ),
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
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
          Positioned(
            left: 16,
            right: 72,
            bottom: 16,
            child: Text(
              widget.feed.description,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexColor) {
    final buffer = StringBuffer();
    if (hexColor.length == 7) {
      buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _jsonController.dispose();
    _innerScrollController.dispose();
    _animationController.dispose();
    _speechService.dispose();
    super.dispose();
  }
}
