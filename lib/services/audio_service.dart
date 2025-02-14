import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAudio(String script) async {
    // For testing, use a fixed audio URL.
    // In a real scenario you could convert `script` into an audio file URL via a TTS API.
    String audioUrl = 'https://www.example.com/audio/sample.mp3';
    await _audioPlayer.setUrl(audioUrl);
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
