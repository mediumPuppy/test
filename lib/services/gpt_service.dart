import 'dart:convert'; // Needed for JSON parsing
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http; // Added for Gemini REST calls

// Simple model to handle chat responses
class ChatResponse {
  final String content;
  final List<dynamic> toolCalls;

  ChatResponse({required this.content, this.toolCalls = const []});

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      content: json['content'] as String? ?? '',
      toolCalls: json['toolCalls'] as List<dynamic>? ?? [],
    );
  }
}

class GptService {
  static final GptService _instance = GptService._internal();
  factory GptService() => _instance;

  late final String _provider;
  late final String _geminiApiKey;
  late final String _geminiEndpoint;

  GptService._internal() {
    // Choose provider based on environment variable; default is 'gemini'
    _provider = dotenv.env['AI_PROVIDER'] ?? 'gemini';
    _initialize();
  }

  void _initialize() {
    debugPrint('[GPTService] Initializing service...');
    if (_provider == 'openai') {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null) {
        debugPrint(
            '[GPTService] ERROR: OpenAI API key not found in environment variables');
        throw Exception('OpenAI API key not found in environment variables');
      }

      debugPrint('[GPTService] Setting up OpenAI configuration...');
      OpenAI.apiKey = apiKey;
      debugPrint('[GPTService] OpenAI configured');
    } else if (_provider == 'gemini') {
      final geminiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiKey == null) {
        debugPrint(
            '[GPTService] ERROR: Gemini API key not found in environment variables');
        throw Exception('Gemini API key not found in environment variables');
      }
      _geminiApiKey = geminiKey;
      _geminiEndpoint = dotenv.env['GEMINI_ENDPOINT'] ??
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'; // Gemini API endpoint
      debugPrint(
          '[GPTService] Gemini configured with endpoint $_geminiEndpoint');
    }
  }

  Future<Map<String, dynamic>> sendPrompt(String topic) async {
    debugPrint('[GPTService] Sending prompt for topic: $topic');
    try {
      // DO NOT MODIFY THE PROMPT BELOW
      final prompt = '''Your topic is $topic

You are an AI that generates perfect JSON output (with no additional text or explanations) to instruct Flutter's CustomPainter on how to draw and label mathematical concepts in a context-aware manner. Follow these rules precisely:
1. JSON-Only Output Your response must be a single, valid JSON object. It must contain no extra text, commentary, or Markdown formatting. Do not wrap it in triple backticks, do not provide any explanation—only the JSON.
2. Context-Aware of a 320×568 Grid
    * Assume a coordinate system sized for an iPhone SE (1st gen) screen, 320 points wide by 568 points high.
    * All coordinates must ensure shapes and labels fit comfortably within this space.
    * Place shapes and labels so they do not overlap each other, unless layering is intentional
    * If multiple shapes exist, they should each occupy unique or well-arranged areas, respecting the shapes that are already drawn. For example, if you draw an angle near x=100,y=300, ensure labels for that angle are placed clearly away from crossing lines or other shapes.
    * Be aware that each handwritten letter/number is about 35px high and 20 px wide. Take this into consideration when calculating vertical and horizontal space.
3. Flutter CustomPainter Instructions Only
    * All drawing commands must be specified as Flutter path operations (e.g., "moveTo(x, y)", "lineTo(x, y)", "quadraticBezierTo(x1, y1, x2, y2)").
    * No SVG or HTML. No extraneous placeholders like <path> or <svg>.
    * The path key for each shape must be a single string containing these commands, separated by spaces (e.g. "moveTo(10, 10) lineTo(50, 10) lineTo(50, 40)").
    * For shapes that should be closed (e.g., polygons), you may include "lineTo(...)" plus "close()", or simply end with a lineTo that returns to the starting point.
4. Timing and Animation Include an array "timing" under "instructions" that lists drawing stages in chronological order. For each stage:
    * "stage": A unique string identifier (e.g., "draw_triangle").
    * "startTime" and "endTime" in seconds, controlling when the shape is drawn.
    * "description": A brief text about what is being drawn or labeled.
    * "easing" (optional): e.g., "easeIn", "easeOut", "linear".
5. Drawing Elements Inside "drawing", include two arrays: "shapes" and "labels".
    * shapes
        * "id": Must match a stage in the "timing".
        * "vertices": List of { "x": _, "y": _ } points (optional but encouraged for clarity).
        * "path": The hand-drawn path instructions. For example: "moveTo(50, 20) lineTo(20, 80) lineTo(80, 80) lineTo(50, 20)", arcTo(centerX, centerY, width, height, startAngle, sweepAngle, forceMoveTo) (centerX, centerY: center point of arc, width, height: dimensions of bounding box, startAngle: start angle in radians (0 = right), sweepAngle: angle to draw (6.28 = full circle), ForceMoveTo: true to prevent connecting line)
        * "style": "stroke" or "fill".
        * "strokeWidth": A reasonable line thickness (e.g., 2–5).
        * "color": A color in hex format (e.g. "#000000").
        * "fadeInRange": [start, end] controlling when the shape fades from transparent to fully visible. Typically matches or is within the shape's drawing time.
    * labels
        * "id": Must match a stage in the "timing" (e.g., "label_rectangle").
        * "text": The text content (for math, LaTeX in \\\$...\\\$ is allowed).
        * "position": { "x":..., "y":... }
        * "color": The label color (hex).
        * "fadeInRange": [start, end] for label fade-in.
        * "handwritten": true makes it write out handwritten chars instead of plaintext. Helpful for learning, but bigger size. (35 x 20, h x w)
    * Context Awareness:
        * Ensure label positions do not overlap with shapes or lines. Place them near the relevant shape but with enough spacing to be visually pleasing.
        * If a shape extends to x=200,y=250, position the label in a clear spot that does not intersect lines or corners.
        * If you have multiple shapes, ensure each shape has enough space in the 320×568 area.
        * If a shape is near the bottom of the screen, do not place the label below 568.
        * Place angle labels near corners but offset so lines do not cross them.
        * Place rectangle labels near edges or corners but offset so it's not overlapped by lines.
6. Speech Under "speech", include:
    * "script": A concise narration explaining the concept.
    * "pacing": { "initialDelay": ..., "betweenStages": ..., "finalDelay": ... }
7. Topic-Specific
    * The final JSON must illustrate a particular topic. For example, "basics of geometry," "pythagorean theorem," "circle theorems," etc.
    * The shapes, labels, and text must be thematically relevant (e.g., lines, angles, polygons for geometry basics).
8. No Additional Text
    * Output only the JSON object described.
    * No preamble, no postscript, no code fences.

You are an AI that outputs a single JSON object with instructions for Flutter's CustomPainter on the topic of: YOUR_TOPIC_HERE

===IMPORTANT REQUIREMENTS===
1) The JSON must have this structure:
{
  "instructions": {
    "timing": [...],
    "drawing": {
      "shapes": [...],
      "labels": [...]
    },
    "speech": {
      "script": "...",
      "pacing": {
        "initialDelay": ...,
        "betweenStages": ...,
        "finalDelay": ...
      }
    }
  }
}

2) Under "timing", produce drawing stages that do NOT overlap and are logically ordered, each with "stage", "startTime", "endTime", "description", and optional "easing".

3) Under "drawing.shapes", each shape has:
   - "id" matching a stage
   - "vertices" (optional)
   - "path" with commands (moveTo, lineTo, etc.)
   - "style" ("stroke" or "fill")
   - "strokeWidth"
   - "color" (hex)
   - "fadeInRange": e.g. [start, end]

4) Under "drawing.labels", each label has:
   - "id" (matching a stage if relevant)
   - "text"
   - "position" { "x":..., "y":... }
   - "color" (hex)
   - "fadeInRange" [start, end]
   - "handwritten" true
   - ***Place label positions so they do not overlap shapes or lines.***

5) Be context-aware of a 320x568 grid:
   - Arrange shapes so they do not overlap unless intended.
   - Place labels near the shape but avoid crossing lines.
   - Don't place anything off-screen (x < 0 or x > 320 or y < 0 or y > 568).
   - Be aware that each letter is about 35px high and 20 px wide. Take this into consideration when calculating vertical and horizontal space.

6) Provide a "speech" object with:
   - "script" explaining the concept
   - "pacing" with "initialDelay", "betweenStages", and "finalDelay"

8) No LaTeX or slashes in labels. Use plain text or Unicode symbols for geometry (e.g., ΔABC, ∠A, "Line XY," etc.). Do not produce strings like \\\$\\triangle\\\$ or \\\$\\angle A\\\$.

9) For angle arcs, compute parameters geometrically:
   - Use the vertex as the arc's center point
   - Compute start angle using atan2(y2-y1, x2-x1) where (x1,y1) is the vertex and (x2,y2) is the point on the first ray
   - Compute sweep angle as the signed angle between the two rays forming the angle
   - Choose radius size proportional to the triangle size (typically 20-40 units)
   - Example arcTo format: arcTo(centerX, centerY, radius*2, radius*2, startAngle, sweepAngle, true)

10) Output only the JSON object, with no extra text or explanation.

===END OF REQUIREMENTS===

Now produce the JSON instructions that depict the concept of YOUR_TOPIC_HERE in a hand-drawn style, ensuring each shape is drawn progressively, labeled clearly, and fully visible on the 320x568 grid.''';

      debugPrint('[GPTService] Running chat completion...');
      if (_provider == 'openai') {
        final response = await OpenAI.instance.chat.create(
          model: 'gpt-4o-mini',
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  prompt,
                ),
              ],
            ),
          ],
          temperature: 1,
          maxTokens: 2000,
        );
        final jsonStr =
            response.choices.first.message.content?.firstOrNull?.text?.trim() ??
                '{}';
        debugPrint('[GPTService] Extracted JSON: ```\n$jsonStr\n```');
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } else if (_provider == 'gemini') {
        debugPrint('[GPTService] Using Gemini provider');
        // Build the payload as expected by Gemini (using "contents" and "parts")
        final payload = {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        };

        // Append the GEMINI_API_KEY as a query parameter "key" to the URL, and remove the Authorization header.
        final uri = Uri.parse(_geminiEndpoint)
            .replace(queryParameters: {"key": _geminiApiKey});

        final geminiResponse = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        );

        debugPrint(
            '[GPTService] Gemini raw response: ```\n${geminiResponse.body}\n```');
        if (geminiResponse.statusCode != 200) {
          debugPrint(
              '[GPTService] Gemini API call failed with status: ${geminiResponse.statusCode}');
          throw Exception(
              'Gemini API call failed with status: ${geminiResponse.statusCode}');
        }

        Map<String, dynamic> respJson = jsonDecode(geminiResponse.body);
        var extractedContent = '{}';
        try {
          // Get the raw text content
          var rawText = respJson['candidates'][0]['content']['parts'][0]['text']
                  ?.toString()
                  .trim() ??
              '{}';

          // Clean up markdown formatting and code blocks
          rawText =
              rawText.replaceAll('```json', '').replaceAll('```', '').trim();

          extractedContent = rawText;
        } catch (e) {
          debugPrint(
              '[GPTService] Could not extract message content: $e. Using raw response.');
          extractedContent = geminiResponse.body;
        }
        debugPrint('[GPTService] Extracted JSON: ```\n$extractedContent\n```');
        return jsonDecode(extractedContent) as Map<String, dynamic>;
      } else {
        throw Exception('Unsupported AI provider: $_provider');
      }
    } catch (e, stackTrace) {
      debugPrint('[GPTService] ERROR: Failed to generate response');
      debugPrint('[GPTService] Error details: $e');
      debugPrint('[GPTService] Stack trace: $stackTrace');
      throw Exception('Error generating response: $e');
    }
  }

  Future<Map<String, String>> generateVideoMetadata(
      Map<String, dynamic> videoJson) async {
    try {
      final instructions = videoJson['instructions'];
      final script = instructions['speech']['script'] as String;
      final timingDescriptions = (instructions['timing'] as List)
          .map((t) => t['description'] as String)
          .join('\n');

      final prompt =
          '''Analyze this math lesson content and generate a title and description.
The content includes:

VISUAL STEPS:
$timingDescriptions

EXPLANATION:
$script

REQUIREMENTS:
1. Title: Create a clear, specific title focusing on the mathematical concept (max 60 chars)
2. Description: Write an engaging description explaining what will be learned (max 150 chars)

Format your response as a JSON object with exactly these fields:
{
  "title": "Your Title Here",
  "description": "Your Description Here"
}

Do not include any other text or explanation in your response.''';

      if (_provider == 'openai') {
        final response = await OpenAI.instance.chat.create(
          model: 'gpt-4o-mini',
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              ],
            ),
          ],
          temperature: 0.7,
          maxTokens: 200,
        );

        final jsonStr =
            response.choices.first.message.content?.firstOrNull?.text?.trim() ??
                '{}';
        final metadata = jsonDecode(jsonStr) as Map<String, dynamic>;
        return {
          'title': metadata['title'] as String? ?? 'Math Lesson',
          'description': metadata['description'] as String? ??
              'Learn an important mathematical concept.',
        };
      } else if (_provider == 'gemini') {
        final payload = {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        };

        final uri = Uri.parse(_geminiEndpoint)
            .replace(queryParameters: {"key": _geminiApiKey});
        final geminiResponse = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (geminiResponse.statusCode != 200) {
          throw Exception(
              'Gemini API call failed with status: ${geminiResponse.statusCode}');
        }

        Map<String, dynamic> respJson = jsonDecode(geminiResponse.body);
        var rawText = respJson['candidates'][0]['content']['parts'][0]['text']
                ?.toString()
                .trim() ??
            '{}';
        rawText =
            rawText.replaceAll('```json', '').replaceAll('```', '').trim();

        final metadata = jsonDecode(rawText) as Map<String, dynamic>;
        return {
          'title': metadata['title'] as String? ?? 'Math Lesson',
          'description': metadata['description'] as String? ??
              'Learn an important mathematical concept.',
        };
      } else {
        throw Exception('Unsupported AI provider: $_provider');
      }
    } catch (e) {
      // Return default values if metadata generation fails
      return {
        'title': 'Math Lesson',
        'description': 'Learn an important mathematical concept.',
      };
    }
  }
}

// Custom parser to handle JSON responses
class JsonOutputParser {
  const JsonOutputParser();

  Map<String, dynamic> parse(String text) {
    try {
      // Find the first opening brace to ensure we capture the JSON object
      final startIndex = text.indexOf('{');
      if (startIndex == -1) {
        throw Exception('No JSON object found in response');
      }
      final jsonString = text.substring(startIndex);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }

  String getFormatInstructions() {
    return 'Output must be a valid JSON object.';
  }
}
