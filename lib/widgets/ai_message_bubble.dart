import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class AiMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isError;

  // Regular expression to identify math expressions between $$ markers
  static final _mathRegExp = RegExp(r'\$\$(.*?)\$\$');

  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isError = false,
  });

  String _processNewlines(String text) {
    // Replace \n with <br> but preserve existing HTML tags
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('<br><br>');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.shade100
              : isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildMessageContent(context),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (isUser) {
      return Text(
        message,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      );
    }

    // Split the message by math expressions
    final parts = message.split(_mathRegExp);
    final matches = _mathRegExp.allMatches(message).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(parts.length, (index) {
        // Process newlines in the text part
        final processedText = _processNewlines(parts[index]);

        // Regular text part - render as HTML
        final textWidget = HtmlWidget(
          processedText,
          textStyle: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          customStylesBuilder: (element) {
            switch (element.localName) {
              case 'h3':
                return {
                  'font-size': '18px',
                  'font-weight': 'bold',
                  'margin': '8px 0',
                };
              case 'br':
                return {
                  'margin': '8px 0',
                };
              default:
                return null;
            }
          },
        );

        // If there's a math expression after this text part, add it
        if (index < matches.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Math.tex(
                  matches[index].group(1)!,
                  textStyle: TextStyle(
                    fontSize: 16,
                    color: isUser ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          );
        }

        return textWidget;
      }),
    );
  }
}
