import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../models/video_feed.dart';
import '../services/firestore_service.dart';
import '../services/topic_progress_service.dart';
import 'action_bar.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../widgets/transition_screen.dart';
import '../screens/whiteboard_screen.dart';

class VideoFeedItem extends StatefulWidget {
  final int index;
  final VideoFeed feed;
  final VoidCallback onShare;

  const VideoFeedItem({
    Key? key,
    required this.index,
    required this.feed,
    required this.onShare,
  }) : super(key: key);

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  final _progressService = TopicProgressService();
  StreamSubscription? _positionSubscription;
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _showTransition = false;
  bool _videoCompleted = false;

  @override
  void initState() {
    super.initState();
    print('VideoFeedItem: Initializing video');
    _initializeVideo();
    _positionSubscription = _progressService.positionStream.listen((position) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen for video completion
    _videoController.addListener(_checkVideoCompletion);
  }

  void _checkVideoCompletion() {
    if (!_videoCompleted && 
        _videoController.value.isInitialized &&
        _videoController.value.position >= _videoController.value.duration) {
      print('Video completed - showing transition');
      _videoCompleted = true;
      _showTransitionScreen();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      print('Initializing video from URL: ${widget.feed.videoUrl}');
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.feed.videoUrl),
      );

      await _videoController.initialize();
      print('Video initialized successfully');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      _videoController.play();
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _showTransitionScreen() {
    print('Starting transition screen with whiteboard');
    setState(() {
      _showTransition = true;
      _videoController.pause();
    });

    // Hide transition screen after duration
    Future.delayed(const Duration(seconds: 10), () {
      print('Transition complete');
      if (mounted) {
        setState(() {
          _showTransition = false;
        });
        _videoController.play();
      }
    });
  }

  @override
  void dispose() {
    _videoController.removeListener(_checkVideoCompletion);
    _videoController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  double _calculateProgress() {
    final progress = _progressService.getProgress();
    return progress;
  }

  void _handleLike(BuildContext context) {
    final firestoreService = FirestoreService();
    firestoreService.toggleVideoLike(widget.feed.id);
  }

  void _handleComment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return CommentSheet(
              videoId: widget.feed.id,
              scrollController: controller,
            );
          },
        );
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: _calculateProgress(),
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor.withOpacity(0.9),
        ),
        minHeight: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        _isInitialized
            ? AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                          } else {
                            _videoController.play();
                          }
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Icon(
                            _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        // Right side action bar
        Positioned(
          right: 16,
          bottom: 100,
          child: StreamBuilder<bool>(
            stream: firestoreService.isVideoLiked(widget.feed.id),
            builder: (context, likedSnapshot) {
              return StreamBuilder<int>(
                stream: firestoreService.getVideoLikesCount(widget.feed.id),
                builder: (context, likesSnapshot) {
                  return StreamBuilder<int>(
                    stream: firestoreService.getVideoCommentsCount(widget.feed.id),
                    builder: (context, commentsSnapshot) {
                      return ActionBar(
                        onLike: () => _handleLike(context),
                        onShare: widget.onShare,
                        onComment: () => _handleComment(context),
                        likes: likesSnapshot.data ?? widget.feed.likes,
                        shares: widget.feed.shares,
                        comments: commentsSnapshot.data ?? 0,
                        isLiked: likedSnapshot.data ?? false,
                        currentTopics: widget.feed.topics,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        // Bottom description
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
        // Progress bar positioned at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildProgressIndicator(context),
        ),
        // Transition screen overlay
        if (_showTransition)
          const WhiteboardScreen(),
      ],
    );
  }
}

class CommentData {
  final String id;
  final Map<String, dynamic> data;
  final bool isOptimistic;

  CommentData({
    required this.id,
    required this.data,
    this.isOptimistic = false,
  });

  factory CommentData.fromSnapshot(DocumentSnapshot snapshot) {
    return CommentData(
      id: snapshot.id,
      data: snapshot.data() as Map<String, dynamic>? ?? {},
    );
  }

  factory CommentData.optimistic(String id, Map<String, dynamic> data) {
    return CommentData(
      id: id,
      data: data,
      isOptimistic: true,
    );
  }
}

class CommentSheet extends StatefulWidget {
  final String videoId;
  final ScrollController scrollController;

  const CommentSheet({
    super.key,
    required this.videoId,
    required this.scrollController,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _firestoreService = FirestoreService();
  final _commentController = TextEditingController();
  final _mentionedUsers = <String>{};
  String? _replyToId;
  List<CommentData> _comments = [];
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  String _sortBy = 'timestamp';
  List<String> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;

  @override
  void initState() {
    super.initState();
    _setupCommentsStream();
  }

  void _setupCommentsStream() {
    try {
      _firestoreService
          .getVideoComments(widget.videoId, sortBy: _sortBy)
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _comments = snapshot.docs
                .map((doc) => CommentData.fromSnapshot(doc))
                .where((comment) => !comment.isOptimistic)
                .toList();
            if (snapshot.docs.isNotEmpty) {
              _lastDocument = snapshot.docs.last;
            }
          });
        }
      }, onError: (error) {
        // Removed debug logging
      });
    } catch (e) {
      // Removed debug logging
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    // Clear the input immediately
    _commentController.clear();
    FocusScope.of(context).unfocus();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create optimistic comment
    final optimisticData = {
      'userId': _firestoreService.userId,
      'userName': 'You',
      'comment': text,
      'timestamp': Timestamp.now(),
      'likes': 0,
      'replyToId': _replyToId,
      'mentionedUsers': _mentionedUsers.toList(),
      'isPending': true,
    };

    final optimisticComment = CommentData.optimistic(tempId, optimisticData);

    setState(() {
      _comments.insert(0, optimisticComment);
      _cancelReply();
    });

    try {
      await _firestoreService.addVideoComment(
        widget.videoId,
        text,
        replyToId: _replyToId,
        mentionedUsers: _mentionedUsers.toList(),
      );
    } catch (e, stackTrace) {
      // Removed debug logging
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSortChange(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() {
      _sortBy = value;
      _comments.clear();
      _lastDocument = null;
      _setupCommentsStream();
    });
  }

  void _onTextChanged(String text) {
    final lastWord = text.split(' ').last;
    if (lastWord.startsWith('@') && lastWord.length > 1) {
      _updateMentionSuggestions(lastWord.substring(1));
    } else {
      setState(() {
        _showMentionSuggestions = false;
        _mentionSuggestions = [];
      });
    }
  }

  Future<void> _updateMentionSuggestions(String prefix) async {
    final suggestions = await _firestoreService.getMentionSuggestions(prefix);
    if (mounted) {
      setState(() {
        _mentionSuggestions = suggestions;
        _showMentionSuggestions = suggestions.isNotEmpty;
      });
    }
  }

  void _onMentionSelected(String username) {
    final text = _commentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    final newText = '${text.substring(0, lastAtIndex)}@$username ';
    
    setState(() {
      _mentionedUsers.add(username);
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });
    
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _setReplyTo(String commentId, String userName) {
    setState(() {
      _replyToId = commentId;
      _commentController.text = '@$userName ';
    });
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _commentController.clear();
      _mentionedUsers.clear();
    });
  }

  Widget _buildCommentItem(CommentData comment) {
    final data = comment.data;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final commentId = comment.id;
    final userName = data['userName'] as String? ?? 'Unknown';
    final commentText = data['comment'] as String? ?? '';
    final isLongComment = commentText.length > 200;

    return Opacity(
      opacity: comment.isOptimistic ? 0.7 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (AuthService().currentUser?.email ?? 'Anonymous')[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                StreamBuilder<User?>(
                  stream: AuthService().authStateChanges,
                  builder: (context, snapshot) {
                    return Text(
                      '${(snapshot.data?.email ?? 'Anonymous').substring(0, 9)}...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                ),
                const SizedBox(width: 8),
                if (!comment.isOptimistic) Text(
                  timeago.format(timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  commentText,
                  maxLines: isLongComment ? 3 : null,
                  overflow: isLongComment ? TextOverflow.ellipsis : TextOverflow.clip,
                ),
                if (isLongComment)
                  TextButton(
                    child: const Text('Show more'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: SingleChildScrollView(
                            child: Text(commentText),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Close'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!comment.isOptimistic) Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: _firestoreService.isCommentLiked(commentId),
                      builder: (context, snapshot) {
                        final isLiked = snapshot.data ?? false;
                        return TextButton.icon(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : null,
                          ),
                          label: Text('${data['likes'] ?? 0}'),
                          onPressed: () => _firestoreService.toggleCommentLike(commentId),
                        );
                      },
                    ),
                    if (data['replyToId'] == null)
                      StreamBuilder<User?>(
                        stream: AuthService().authStateChanges,
                        builder: (context, snapshot) {
                          return TextButton(
                            child: const Text('Reply'),
                            onPressed: () => _setReplyTo(
                              commentId, 
                              snapshot.data?.email ?? 'Anonymous'
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Show replies
          if (data['replyToId'] == null && !comment.isOptimistic)
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getCommentReplies(commentId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final replies = snapshot.data!.docs;
                  return Column(
                    children: replies.map((reply) => _buildCommentItem(CommentData.fromSnapshot(reply))).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppBar(
            title: const Text('Comments'),
            automaticallyImplyLeading: false,
            actions: [
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'timestamp',
                    child: Text('Most Recent'),
                  ),
                  DropdownMenuItem(
                    value: 'likes',
                    child: Text('Most Liked'),
                  ),
                ],
                onChanged: _handleSortChange,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Flexible(
            child: ListView.builder(
              controller: widget.scrollController,
              reverse: true,
              itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildCommentItem(_comments[index]);
              },
            ),
          ),
          if (_showMentionSuggestions)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _mentionSuggestions.length,
                itemBuilder: (context, index) {
                  final username = _mentionSuggestions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(username[0].toUpperCase()),
                    ),
                    title: Text(username),
                    onTap: () => _onMentionSelected(username),
                  );
                },
              ),
            ),
          if (_replyToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Text('Replying to'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    onChanged: _onTextChanged,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}