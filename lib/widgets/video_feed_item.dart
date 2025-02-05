import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/video_feed.dart';
import '../services/firestore_service.dart';
import 'action_bar.dart';

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
    final firestoreService = FirestoreService();
    firestoreService.toggleVideoLike(feed.id);
  }

  void _handleComment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => CommentSheet(
          videoId: feed.id,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              return StreamBuilder<int>(
                stream: firestoreService.getVideoLikesCount(feed.id),
                builder: (context, likesSnapshot) {
                  return StreamBuilder<int>(
                    stream: firestoreService.getVideoCommentsCount(feed.id),
                    builder: (context, commentsSnapshot) {
                      return ActionBar(
                        onLike: () => _handleLike(context),
                        onShare: onShare,
                        onComment: () => _handleComment(context),
                        likes: likesSnapshot.data ?? feed.likes,
                        shares: feed.shares,
                        comments: commentsSnapshot.data ?? 0,
                        isLiked: likedSnapshot.data ?? false,
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
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _scrollController = ScrollController();
  String? _replyToId;
  String? _replyToUser;
  String _sortBy = 'timestamp'; // or 'likes'
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  final List<DocumentSnapshot> _comments = [];
  final Set<String> _mentionedUsers = {};
  bool _showMentionsList = false;
  List<String> _mentionSuggestions = [];
  final Map<String, int> _optimisticLikes = {};
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load comments after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestoreService.getVideoComments(
        widget.videoId,
        sortBy: _sortBy,
        lastDocument: _lastDocument,
      ).first;

      setState(() {
        _comments.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.lastOrNull;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadComments();
    }
  }

  void _handleSortChange(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() {
      _sortBy = value;
      _comments.clear();
      _lastDocument = null;
      _loadComments();
    });
  }

  void _onTextChanged(String text) {
    final lastWord = text.split(' ').last;
    if (lastWord.startsWith('@') && lastWord.length > 1) {
      _updateMentionSuggestions(lastWord.substring(1));
    } else {
      setState(() {
        _showMentionsList = false;
        _mentionSuggestions = [];
      });
    }
  }

  Future<void> _updateMentionSuggestions(String prefix) async {
    final suggestions = await _firestoreService.getMentionSuggestions(prefix);
    if (mounted) {
      setState(() {
        _mentionSuggestions = suggestions;
        _showMentionsList = suggestions.isNotEmpty;
      });
    }
  }

  void _onMentionSelected(String username) {
    final text = _commentController.text;
    final lastAtIndex = text.lastIndexOf('@');
    final newText = text.substring(0, lastAtIndex) + '@$username ';
    
    setState(() {
      _mentionedUsers.add(username);
      _showMentionsList = false;
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
      _replyToUser = userName;
      _commentController.text = '@$userName ';
    });
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToUser = null;
      _commentController.clear();
      _mentionedUsers.clear();
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Optimistic update
    final optimisticData = {
      'userId': _firestoreService.userId,
      'userName': 'You', // Will be replaced with actual data
      'comment': text,
      'timestamp': Timestamp.now(),
      'likes': 0,
      'replyToId': _replyToId,
      'mentionedUsers': _mentionedUsers.toList(),
      'isPending': true,
    };

    // Create a fake DocumentSnapshot for optimistic update
    final optimisticDoc = FakeDocumentSnapshot(
      'temp_${DateTime.now().millisecondsSinceEpoch}',
      optimisticData,
    );

    setState(() {
      _comments.insert(0, optimisticDoc);
    });

    try {
      await _firestoreService.addVideoComment(
        widget.videoId,
        text,
        replyToId: _replyToId,
        mentionedUsers: _mentionedUsers.toList(),
      );

      if (mounted) {
        _commentController.clear();
        _cancelReply();
        FocusScope.of(context).unfocus();
        
        // Remove optimistic comment and add real one
        setState(() {
          _comments.removeWhere((c) => (c.data() as Map<String, dynamic>)['isPending'] == true);
        });
      }
    } catch (e) {
      // Remove optimistic comment on error
      setState(() {
        _comments.removeWhere((c) => (c.data() as Map<String, dynamic>)['isPending'] == true);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleCommentLike(String commentId, int currentLikes) async {
    // Optimistic update
    setState(() {
      final isCurrentlyLiked = _optimisticLikes[commentId] != null;
      if (isCurrentlyLiked) {
        _optimisticLikes.remove(commentId);
      } else {
        _optimisticLikes[commentId] = currentLikes + 1;
      }
    });

    try {
      await _firestoreService.toggleCommentLike(commentId);
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _optimisticLikes.remove(commentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final commentId = doc.id;
    final isPending = data['isPending'] == true;
    final optimisticLikeCount = _optimisticLikes[commentId];
    final baseCount = data['likes'] as int? ?? 0;
    final displayLikeCount = optimisticLikeCount ?? baseCount;

    return Opacity(
      opacity: isPending ? 0.7 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                data['userName'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  data['userName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPending) Text(
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
                  data['comment'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data['commentLength'] > 200)
                  TextButton(
                    child: const Text('Show more'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: SingleChildScrollView(
                            child: Text(data['comment']),
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
                if (!isPending) Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: _firestoreService.isCommentLiked(commentId),
                      builder: (context, snapshot) {
                        final isLiked = snapshot.data ?? false || _optimisticLikes.containsKey(commentId);
                        return TextButton.icon(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : null,
                          ),
                          label: Text('$displayLikeCount'),
                          onPressed: () => _handleCommentLike(commentId, baseCount),
                        );
                      },
                    ),
                    if (data['replyToId'] == null)
                      TextButton(
                        child: const Text('Reply'),
                        onPressed: () => _setReplyTo(commentId, data['userName']),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Show replies
          if (data['replyToId'] == null && !isPending)
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getCommentReplies(commentId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final replies = snapshot.data!.docs;
                  return Column(
                    children: replies.map((reply) => _buildCommentItem(reply)).toList(),
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
              controller: _scrollController,
              reverse: true,
              itemCount: _comments.length + (_isLoading ? 1 : 0),
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
          if (_showMentionsList)
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
          if (_replyToUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Text('Replying to $_replyToUser'),
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

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data[field.toString()];
  
  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field.toString()];

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();
} 