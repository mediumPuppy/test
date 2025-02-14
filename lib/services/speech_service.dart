import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class SpeechService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  String? get _apiKey => dotenv.env['ELEVEN_LABS_API_KEY'];
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';
  static const String _defaultVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Adam voice
  File? _currentAudioFile;
  String? _selectedModelId;

  Future<void> initialize() async {
    if (!_isInitialized) {
      if (_apiKey == null) {
        throw Exception(
            'ELEVEN_LABS_API_KEY not found in environment variables');
      }
      await _fetchAvailableModels();
      _isInitialized = true;
    }
  }

  Future<void> _fetchAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'xi-api-key': _apiKey!,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final models = json.decode(response.body);
        // Select the first available model or a specific one
        if (models is List && models.isNotEmpty) {
          _selectedModelId = models[0]['model_id'];
          print('Selected model: $_selectedModelId');
        }
      } else {
        print('Failed to fetch models: ${response.body}');
        // Fallback to a known model ID
        _selectedModelId = 'eleven_multilingual_v2';
      }
    } catch (e) {
      print('Error fetching models: $e');
      // Fallback to a known model ID
      _selectedModelId = 'eleven_multilingual_v2';
    }
  }

  Future<void> speak(String text) async {
    try {
      await initialize();

      if (_selectedModelId == null) {
        throw Exception('No text-to-speech model available');
      }

      // Get audio bytes from Eleven Labs
      final url = Uri.parse('$_baseUrl/text-to-speech/$_defaultVoiceId');
      final response = await http.post(
        url,
        headers: {
          'xi-api-key': _apiKey!,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': text,
          'model_id': _selectedModelId,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
            'style': 0.0,
            'use_speaker_boost': true
          }
        }),
      );

      if (response.statusCode != 200) {
        print('API Response: ${response.body}');
        throw Exception('Failed to generate speech: ${response.body}');
      }

      // Save audio bytes to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
      _currentAudioFile = File(tempPath);
      await _currentAudioFile!.writeAsBytes(response.bodyBytes);

      // Play the audio from the temporary file
      await _audioPlayer.setFilePath(_currentAudioFile!.path);
      await _audioPlayer.play();
    } catch (e) {
      print('Error in speak: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    await _cleanupTempFile();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
    await _cleanupTempFile();
  }

  Future<void> _cleanupTempFile() async {
    if (_currentAudioFile != null && await _currentAudioFile!.exists()) {
      try {
        await _currentAudioFile!.delete();
        _currentAudioFile = null;
      } catch (e) {
        print('Error cleaning up temp file: $e');
      }
    }
  }

  bool get isPlaying => _audioPlayer.playing;
}
