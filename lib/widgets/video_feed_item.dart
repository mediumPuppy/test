import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import '../models/video_feed.dart';
import '../services/firestore_service.dart';
import 'action_bar.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart' show debugPrint;

class VideoFeedItem extends StatelessWidget {
  final int index;
  final VideoFeed feed;
  final VoidCallback onShare;

  const VideoFeedItem({
    super.key,
    required this.index,
    required this.feed,
    required this.onShare,
  });

  void _handleLike(BuildContext context) {
    debugPrint('[DEBUG] Like button pressed for video: ${feed.id}');
    final firestoreService = FirestoreService();
    firestoreService.toggleVideoLike(feed.id);
  }

  void _handleComment(BuildContext context) {
    debugPrint('[DEBUG] Comment button pressed for video: ${feed.id}');
    debugPrint('[DEBUG] Opening comment sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        debugPrint('[DEBUG] Building comment sheet');
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            debugPrint('[DEBUG] Initializing CommentSheet widget');
            return CommentSheet(
              videoId: feed.id,
              scrollController: controller,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG] Building VideoFeedItem for video: ${feed.id}');
    final firestoreService = FirestoreService();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder for video
        Container(
          color: Colors.grey[900],
          child: Center(
            child: Text(
              'Video ${feed.id}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        
        // Right side action bar
        Positioned(
          right: 16,
          bottom: 100,
          child: StreamBuilder<bool>(
            stream: firestoreService.isVideoLiked(feed.id),
            builder: (context, likedSnapshot) {
              debugPrint('[DEBUG] Building like status for video: ${feed.id}');
              return StreamBuilder<int>(
                stream: firestoreService.getVideoLikesCount(feed.id),
                builder: (context, likesSnapshot) {
                  debugPrint('[DEBUG] Building likes count for video: ${feed.id}');
                  return StreamBuilder<int>(
                    stream: firestoreService.getVideoCommentsCount(feed.id),
                    builder: (context, commentsSnapshot) {
                      debugPrint('[DEBUG] Building comments count for video: ${feed.id}');
                      return ActionBar(
                        onLike: () => _handleLike(context),
                        onShare: onShare,
                        onComment: () => _handleComment(context),
                        likes: likesSnapshot.data ?? feed.likes,
                        shares: feed.shares,
                        comments: commentsSnapshot.data ?? 0,
                        isLiked: likedSnapshot.data ?? false,
                        currentTopics: feed.topics,
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
            feed.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
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
    debugPrint('[DEBUG] Initializing CommentSheet state for video: ${widget.videoId}');
    super.initState();
    _setupCommentsStream();
  }

  void _setupCommentsStream() {
    debugPrint('[DEBUG] Setting up comments stream for video: ${widget.videoId}');
    try {
      _firestoreService
          .getVideoComments(widget.videoId, sortBy: _sortBy)
          .listen((snapshot) {
        debugPrint('[DEBUG] Received comments update. Count: ${snapshot.docs.length}');
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
        debugPrint('[ERROR] Error in comments stream: $error');
      });
    } catch (e) {
      debugPrint('[ERROR] Failed to setup comments stream: $e');
    }
  }

  Future<void> _submitComment() async {
    debugPrint('[DEBUG] Starting comment submission');
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      debugPrint('[DEBUG] Comment text is empty, returning');
      return;
    }

    debugPrint('[DEBUG] Comment text: $text');
    debugPrint('[DEBUG] Reply to: $_replyToId');
    debugPrint('[DEBUG] Mentioned users: $_mentionedUsers');
    debugPrint('[DEBUG] Current user ID: ${_firestoreService.userId}');

    // Clear the input immediately
    _commentController.clear();
    FocusScope.of(context).unfocus();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[DEBUG] Generated temp id: $tempId');
    
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
    debugPrint('[DEBUG] Created optimistic data: $optimisticData');

    final optimisticComment = CommentData.optimistic(tempId, optimisticData);

    setState(() {
      debugPrint('[DEBUG] Adding optimistic comment to UI');
      _comments.insert(0, optimisticComment);
      _cancelReply();
    });

    try {
      debugPrint('[DEBUG] Attempting to add comment to Firestore');
      await _firestoreService.addVideoComment(
        widget.videoId,
        text,
        replyToId: _replyToId,
        mentionedUsers: _mentionedUsers.toList(),
      );
      debugPrint('[DEBUG] Successfully added comment to Firestore');
    } catch (e, stackTrace) {
      debugPrint('[ERROR] Failed to submit comment: $e');
      debugPrint('[ERROR] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          debugPrint('[DEBUG] Removing failed optimistic comment from UI');
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