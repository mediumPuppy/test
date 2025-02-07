import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'whiteboard_screen.dart';
import '../services/explanation_service.dart';
import '../services/ai_explanation_service.dart';
import 'package:just_audio/just_audio.dart';

class AIExplanationScreen extends StatefulWidget {
  final String videoContext;

  const AIExplanationScreen({
    super.key,
    required this.videoContext,
  });

  @override
  State<AIExplanationScreen> createState() => _AIExplanationScreenState();
}

class _AIExplanationScreenState extends State<AIExplanationScreen> {
  final TextEditingController _questionController = TextEditingController();
  late final ExplanationState _explanationState;
  late final AIExplanationService _aiService;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _explanationState = ExplanationState();
    _aiService = AIExplanationService();
    _audioPlayer = AudioPlayer();
    _questionController.addListener(_onQuestionChanged);
  }

  @override
  void dispose() {
    _questionController.removeListener(_onQuestionChanged);
    _questionController.dispose();
    _explanationState.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onQuestionChanged() {
    _explanationState.updateQuestionText(_questionController.text);
  }

  void _toggleListening() {
    if (_explanationState.status != ExplanationStatus.listening) {
      _explanationState.startListening();
      // TODO: Implement speech-to-text
    } else {
      _explanationState.stopListening();
    }
  }

  Future<void> _handleSubmit() async {
    final question = _questionController.text;
    if (question.isEmpty) return;
    
    try {
      _explanationState.startProcessing();
      
      // Generate explanation and drawing commands
      final result = await _aiService.generateExplanation(
        question: question,
        videoContext: widget.videoContext,
      );
      
      // Generate speech audio
      final audioBytes = await _aiService.synthesizeSpeech(result['explanation']);
      
      // Create audio source from bytes
      final audioSource = AudioSource.uri(
        Uri.dataFromBytes(audioBytes, mimeType: 'audio/wav'),
      );
      
      // Load and start playing audio
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      
      // Start explanation with drawing commands
      _explanationState.startExplanation(
        explanationText: result['explanation'],
        drawingCommands: result['drawingCommands'],
      );
      
      // Listen for audio completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _explanationState.completeExplanation();
        }
      });
      
    } catch (e) {
      _explanationState.setError(e.toString());
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              enabled: _explanationState.status == ExplanationStatus.idle ||
                      _explanationState.status == ExplanationStatus.error,
              decoration: InputDecoration(
                hintText: 'What would you like me to explain?',
                border: const OutlineInputBorder(),
                errorText: _explanationState.status == ExplanationStatus.error
                    ? _explanationState.error
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _explanationState.status == ExplanationStatus.listening
                  ? Icons.mic
                  : Icons.mic_none,
              color: _explanationState.status == ExplanationStatus.listening
                  ? Colors.red
                  : null,
            ),
            onPressed: _explanationState.status == ExplanationStatus.idle ||
                      _explanationState.status == ExplanationStatus.listening
                ? _toggleListening
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _explanationState.status == ExplanationStatus.idle ||
                      _explanationState.status == ExplanationStatus.error
                ? _handleSubmit
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _explanationState,
      child: Scaffold(
        body: Stack(
          children: [
            const WhiteboardScreen(),  // Base whiteboard functionality
            if (_explanationState.status == ExplanationStatus.processing)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildInputBar(),
            ),
          ],
        ),
      ),
    );
  }
}
