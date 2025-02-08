import 'package:flutter/material.dart';
import '../services/ai_explanation_service.dart';
import '../widgets/ai_message_bubble.dart';
import '../screens/interactive_whiteboard_screen.dart';

class AIExplanationScreen extends StatefulWidget {
  final String? videoContext;

  const AIExplanationScreen({
    super.key,
    this.videoContext,
  });

  @override
  State<AIExplanationScreen> createState() => _AIExplanationScreenState();
}

class _AIExplanationScreenState extends State<AIExplanationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIExplanationService _aiService = AIExplanationService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String _conversationContext = '';
  static const int _maxUserMessages = 5;
  int _userMessageCount = 0;

  // TO BE DELETED LATER - Test variables for whiteboard toggle
  bool _showWhiteboard = false;
  final String _testEquation = "2x + 5 = 15";

  @override
  void initState() {
    super.initState();
    // Comment out original initialization for testing
    // _initializeConversation();

    // TO BE DELETED LATER - Add test message
    _messages.add({
      'text':
          'Here\'s the equation we\'ll solve: \$\$\\frac{2x-4}{3} = 2y^3\$\$\n\nLet\'s break this down step by step...',
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _initializeConversation() async {
    if (widget.videoContext != null && widget.videoContext!.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        final response = await _aiService.generateExplanation(
            '''For a video about "${widget.videoContext}", respond with ONLY a list of 3-4 key concepts formatted exactly as:
A) [concept 1]
B) [concept 2]
C) [concept 3]
Do not add any other text before or after the options.''');

        setState(() {
          _messages.add({
            'text': '''Hi! Which of these would you like me to explain?

$response

Or ask me anything else about ${widget.videoContext}!''',
            'isUser': false,
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });

        _updateConversationContext();
      } catch (e) {
        setState(() {
          _messages.add({
            'text':
                'I encountered an error while preparing your options. Please feel free to ask any question about ${widget.videoContext}.',
            'isUser': false,
            'timestamp': DateTime.now(),
            'isError': true,
          });
          _isLoading = false;
        });
      }
    }
  }

  void _updateConversationContext() {
    // Build context from the last few messages
    _conversationContext = _messages.map((msg) {
      return "${msg['isUser'] ? 'Student' : 'Tutor'}: ${msg['text']}";
    }).join('\n\n');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_userMessageCount >= _maxUserMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You\'ve reached the maximum number of messages. Starting a new conversation.'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _messages.clear();
        _userMessageCount = 0;
        _conversationContext = '';
      });
      await _initializeConversation();
      return;
    }

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _userMessageCount++;
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      _updateConversationContext();
      final prompt =
          '''Context: This is a math tutoring session about "${widget.videoContext}".
Previous conversation:
$_conversationContext

Student's question: $message

Provide a clear, helpful explanation that builds on our previous conversation. Remember to be encouraging and break down complex concepts.''';

      final response = await _aiService.generateExplanation(prompt);
      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
      _updateConversationContext();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'text':
              'Sorry, I encountered an error while generating the explanation. Please try again.',
          'isUser': false,
          'timestamp': DateTime.now(),
          'isError': true,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Flexible(
              child: Text('AI Math Tutor'),
            ),
            if (_userMessageCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_maxUserMessages - _userMessageCount} questions left',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 1,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _userMessageCount = 0;
                  _conversationContext = '';
                });
                _initializeConversation();
              },
              tooltip: 'Start New Conversation',
            ),
          // TO BE DELETED LATER - Add whiteboard toggle
          IconButton(
            icon: Icon(_showWhiteboard ? Icons.text_fields : Icons.draw),
            onPressed: () {
              setState(() {
                _showWhiteboard = !_showWhiteboard;
              });
            },
            tooltip: _showWhiteboard ? 'Show Text' : 'Show Whiteboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            //     child: ListView.builder(
            // controller: _scrollController,
            // padding: const EdgeInsets.all(16),
            // itemCount: _messages.length,
            // itemBuilder: (context, index) {
            //   final message = _messages[index];
            //   return AiMessageBubble(
            //     message: message['text'],
            //     isUser: message['isUser'],
            //     isError: message['isError'] ?? false,
            //   );
            // },
            // ),
            child: _showWhiteboard
                ? InteractiveWhiteboardScreen(
                    text: _testEquation,
                    duration: const Duration(seconds: 5),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return AiMessageBubble(
                        message: message['text'],
                        isUser: message['isUser'],
                        isError: message['isError'] ?? false,
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _userMessageCount >= _maxUserMessages
                            ? 'Maximum messages reached. Tap send to start new conversation.'
                            : 'Ask me about math...',
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
