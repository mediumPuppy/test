import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

// Abstract class for text generation service
abstract class ITextGenerationService {
  Future<String> generateExplanation(String query);
}

// Abstract class for text-to-speech service
abstract class ITextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

// Implementation of OpenAI text generation service using LangChain
class OpenAITextGenerationService implements ITextGenerationService {
  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  late final ChatOpenAI _model;
  late final ChatPromptTemplate _promptTemplate;
  late final StringOutputParser _outputParser;
  late final LLMChain _chain;

  OpenAITextGenerationService() {
    _initializeChain();
  }

  void _initializeChain() {
    if (_apiKey == null) {
      throw Exception('OpenAI API key not found in environment variables');
    }

    _model = ChatOpenAI(
      apiKey: _apiKey!,
    );

    _promptTemplate = ChatPromptTemplate.fromTemplates([
      (ChatMessageType.system, 'You are a helpful assistant that provides clear and concise explanations.'),
      (ChatMessageType.human, '{query}'),
    ]);

    _outputParser = const StringOutputParser();

    _chain = LLMChain(
      prompt: _promptTemplate,
      llm: _model,
      outputParser: _outputParser,
    );
  }

  @override
  Future<String> generateExplanation(String query) async {
    try {
      final response = await _chain.run(query);
      return response;
    } catch (e) {
      throw Exception('Error generating explanation: $e');
    }
  }
}

// Implementation of text-to-speech service using just_audio
class AudioTextToSpeechService implements ITextToSpeechService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  Future<void> speak(String text) async {
    try {
      final String audioUrl = await _getAudioUrlFromText(text);
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Error playing audio: $e');
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<String> _getAudioUrlFromText(String text) async {
    // Implement text-to-speech API call here
    // This is a placeholder - you'll need to integrate with a TTS service
    throw UnimplementedError('Text-to-speech API integration required');
  }
}

// Facade service that combines both text generation and speech
class AIExplanationService {
  final ITextGenerationService _textService;
  final ITextToSpeechService _speechService;

  AIExplanationService({
    ITextGenerationService? textService,
    ITextToSpeechService? speechService,
  })  : _textService = textService ?? OpenAITextGenerationService(),
        _speechService = speechService ?? AudioTextToSpeechService();

  Future<String> generateExplanation(String query) async {
    return await _textService.generateExplanation(query);
  }

  Future<void> explainAndSpeak(String query) async {
    final explanation = await generateExplanation(query);
    await _speechService.speak(explanation);
  }

  Future<void> stopSpeaking() async {
    await _speechService.stop();
  }
}
