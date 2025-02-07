import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'explanation_service.dart';

class AIExplanationService {
  static const String _openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _openAITTSEndpoint = 'https://api.openai.com/v1/audio/speech';
  
  final String _openAIKey;
  
  AIExplanationService({
    String? openAIKey,
  }) : _openAIKey = openAIKey ?? dotenv.env['OPENAI_API_KEY'] ?? '';
  
  Future<Map<String, dynamic>> generateExplanation({
    required String question,
    required String videoContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an expert tutor. Generate a clear, step-by-step explanation 
              that includes mathematical concepts and visual aids. Format your response as JSON with:
              1. 'explanation': The text to be spoken (keep it natural and conversational for TTS)
              2. 'drawings': Array of drawing commands, each with:
                 - type: 'path', 'text', 'circle', etc.
                 - params: coordinates, color, size, etc.
              Keep explanations concise and focused.'''
            },
            {
              'role': 'user',
              'content': '''Context: $videoContext
              
              Question: $question'''
            }
          ],
          'response_format': { 'type': 'json_object' }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate explanation: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = jsonDecode(data['choices'][0]['message']['content']);
      
      return {
        'explanation': content['explanation'],
        'drawingCommands': (content['drawings'] as List).map((cmd) => 
          DrawingCommand(
            type: cmd['type'],
            params: cmd['params'],
          )
        ).toList(),
      };
    } catch (e) {
      throw Exception('Failed to generate explanation: $e');
    }
  }

  Future<List<int>> synthesizeSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_openAITTSEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': text,
          'voice': 'alloy',  // Using alloy voice, alternatives: echo, fable, onyx, nova, shimmer
          'speed': 1.0,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to synthesize speech: ${response.body}');
      }

      return response.bodyBytes;
    } catch (e) {
      throw Exception('Failed to synthesize speech: $e');
    }
  }
}
