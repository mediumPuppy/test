import 'package:flutter/material.dart';
import '../services/ai_explanation_service.dart';
import '../widgets/ai_message_bubble.dart';
import '../screens/interactive_whiteboard_screen.dart';
import '../models/video_feed.dart';

class AIExplanationScreen extends StatefulWidget {
  final VideoFeed? videoContext;
  final Map<String, dynamic>? videoObject;

  const AIExplanationScreen({
    super.key,
    this.videoContext,
    this.videoObject,
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

  @override
  void initState() {
    super.initState();
    if (widget.videoObject != null) {
      _initializeConversation();
    } else {
      _messages.add({
        'text': "Ask me anything you need help understanding!",
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    }
  }

  Future<void> _initializeConversation() async {
    if (widget.videoObject != null) {
      setState(() => _isLoading = true);

      try {
        final videoMetadata = widget.videoObject!;
        final videoJson = videoMetadata['videoJson'];
        final contextBuilder = StringBuffer();

        // Add lesson context
        contextBuilder.writeln('Lesson Details:');
        contextBuilder.writeln('Subject: ${videoMetadata['subject']}');
        contextBuilder.writeln('Topic: ${videoMetadata['title']}');
        contextBuilder.writeln('Skill Level: ${videoMetadata['skillLevel']}');
        contextBuilder.writeln('Topic ID: ${videoMetadata['topicId']}');

        // Extract from instructions object in videoJson
        if (videoJson != null && videoJson['instructions'] != null) {
          // Add visual descriptions from timing array
          if (videoJson['instructions']['timing'] != null) {
            contextBuilder.writeln('\nWhat was shown in the lesson:');
            for (var timing in videoJson['instructions']['timing']) {
              contextBuilder.writeln('- ${timing['description']}');
            }
          }

          // Add narration from speech object
          if (videoJson['instructions']['speech'] != null) {
            contextBuilder.writeln('\nLesson Explanation:');
            contextBuilder
                .writeln(videoJson['instructions']['speech']['script']);
          }
        }

        final response =
            await _aiService.generateExplanation('''Based on this lesson:
${contextBuilder.toString()}

Please identify 3-4 key concepts that were covered, formatted as:
A) [concept 1]
B) [concept 2]
C) [concept 3]
List only the concepts, no additional text.''');

        setState(() {
          _messages.add({
            'text': '''Hi! Which of these would you like me to explain?

$response

Or feel free to ask any other questions about the video.''',
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
                'I encountered an error preparing the lesson summary. Feel free to ask any questions about what you saw, and I\'ll do my best to help!',
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
              'You\'ve reached the maximum number of questions. Starting a new conversation.'),
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

      // Build enhanced prompt with lesson context
      final videoMetadata = widget.videoObject;
      final contextBuilder = StringBuffer();

      if (videoMetadata != null) {
        contextBuilder.writeln(
            'This is a ${videoMetadata['skillLevel']} level lesson about "${videoMetadata['title']}" in ${videoMetadata['subject']}.');

        // Add visual descriptions from timing array
        if (videoMetadata['videoJson']?['instructions']?['timing'] != null) {
          contextBuilder.writeln('\nThe lesson showed:');
          for (var timing in videoMetadata['videoJson']['instructions']
              ['timing']) {
            contextBuilder.writeln('- ${timing['description']}');
          }
        }

        // Add narration
        if (videoMetadata['videoJson']?['instructions']?['speech']?['script'] !=
            null) {
          contextBuilder.writeln('\nThe explanation given was:');
          contextBuilder.writeln(
              videoMetadata['videoJson']['instructions']['speech']['script']);
        }
      }

      contextBuilder.writeln('\nPrevious conversation:');
      contextBuilder.writeln(_conversationContext);

      final prompt = '''VIDEO CONTEXT:
${contextBuilder.toString()}

STUDENT QUESTION:
$message

INSTRUCTIONS:
Provide a clear, helpful explanation that builds on the video content shown above. Reference specific visual examples or explanations from the video when relevant.''';

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

  String _convertLatexToPlainMath(String latex) {
    final conversions = <String, String Function(Match)?>{
      // Fractions: handle nested expressions properly
      r'\\frac{(.*?)}{(.*?)}': (Match m) {
        var numerator = m.group(1)!;
        var denominator = m.group(2)!;
        // Add parentheses if the numerator/denominator has operators
        if (numerator.contains('+') || numerator.contains('-')) {
          numerator = '($numerator)';
        }
        if (denominator.contains('+') || denominator.contains('-')) {
          denominator = '($denominator)';
        }
        return '$numerator/$denominator';
      },
      // Exponents: maintain proper order
      r'([a-zA-Z0-9]+)\^([a-zA-Z0-9]+)': (Match m) =>
          '${m.group(1)}^${m.group(2)}',
      // Square roots
      r'\\sqrt{(.*?)}': (Match m) => 'sqrt(${m.group(1)})',
      // Multiplication symbols
      r'\\cdot': (Match m) => '×',
      r'\\times': (Match m) => '×',
      // Division symbol
      r'\\div': (Match m) => '÷',
      // Remove LaTeX command markers
      r'\\left': null,
      r'\\right': null,
      // Keep parentheses and brackets
      r'[()[\]]': null,
      // Special constants
      r'\\pi': (Match m) => 'π',
      r'\\infty': (Match m) => '∞',
    };

    String plainMath = latex;
    print('Converting LaTeX: $latex');

    conversions.forEach((pattern, replacement) {
      if (replacement == null) {
        // Just remove the LaTeX command, keep the character
        plainMath = plainMath.replaceAll(RegExp(pattern), '');
      } else {
        plainMath = plainMath.replaceAllMapped(RegExp(pattern), replacement);
      }
    });

    // Clean up
    plainMath = plainMath
        .replaceAll(RegExp(r'\s+'), '') // Remove whitespace
        .replaceAll(r'\{', '(') // Replace remaining braces
        .replaceAll(r'\}', ')')
        .trim();

    print('Converted to: $plainMath');
    return plainMath;
  }

  String _extractEquationsForWhiteboard(String message) {
    final mathRegExp = RegExp(r'\$\$(.*?)\$\$');
    final equations = mathRegExp.allMatches(message).map((match) {
      final latex = match.group(1)!;
      return _convertLatexToPlainMath(latex);
    }).join('\n');

    print('Final equations string: $equations');
    return equations;
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: _showWhiteboard && _messages.isNotEmpty
                  ? InteractiveWhiteboardScreen(
                      text: _extractEquationsForWhiteboard(
                        _messages.last['text'] as String,
                      ),
                      duration: const Duration(seconds: 10),
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
                child: CircularProgressIndicator(),
              ),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
