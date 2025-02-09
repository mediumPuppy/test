import 'package:flutter/material.dart';
import '../models/drawing_spec_models.dart';
import '../services/drawing_spec_parser.dart';
import '../services/speech_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/speech_overlay.dart';

/// A screen that displays the Khan Academy style drawing with narration
class DrawingAndSpeechScreen extends StatefulWidget {
  const DrawingAndSpeechScreen({super.key});

  @override
  State<DrawingAndSpeechScreen> createState() => _DrawingAndSpeechScreenState();
}

class _DrawingAndSpeechScreenState extends State<DrawingAndSpeechScreen> {
  late final SpeechService _speechService;
  DrawingSpec? _spec;
  bool _isPlaying = false;
  String? _error;

  final GlobalKey<DrawingCanvasState> _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
    _loadSampleSpec();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  /// Load a sample drawing specification for testing
  Future<void> _loadSampleSpec() async {
    try {
      // This is a sample JSON spec for testing
      const jsonSpec = '''
      {
        "stages": [
          {
            "name": "init_grid",
            "description": "Let's start by drawing a coordinate grid",
            "startTime": 0.0,
            "endTime": 1.0,
            "easingFunction": "easeInOut",
            "elements": [
              {
                "type": "grid",
                "attributes": {
                  "spacing": 20.0,
                  "color": 4288716960,
                  "lineWidth": 1.0,
                  "opacity": 0.3,
                  "isDashed": false
                }
              }
            ]
          },
          {
            "name": "setup_axes",
            "description": "Now we'll add the x and y axes",
            "startTime": 1.0,
            "endTime": 2.0,
            "easingFunction": "easeInOut",
            "elements": [
              {
                "type": "axes",
                "attributes": {
                  "color": 4278190080,
                  "lineWidth": 2.0,
                  "showArrowheads": true
                }
              }
            ]
          },
          {
            "name": "plot_line",
            "description": "Let's plot a line with slope 2",
            "startTime": 2.0,
            "endTime": 3.0,
            "easingFunction": "drawingnatural",
            "elements": [
              {
                "type": "line",
                "attributes": {
                  "points": [
                    {"x": -80, "y": -160},
                    {"x": 80, "y": 160}
                  ],
                  "color": 4278190335,
                  "lineWidth": 3.0,
                  "isDashed": false
                }
              }
            ]
          },
          {
            "name": "show_slope",
            "description": "The slope is the change in y divided by the change in x",
            "startTime": 3.0,
            "endTime": 4.0,
            "easingFunction": "easeInOut",
            "elements": [
              {
                "type": "slope_indicator",
                "attributes": {
                  "startPoint": {"x": 0, "y": 0},
                  "endPoint": {"x": 40, "y": 80},
                  "riseColor": 4294901760,
                  "runColor": 4278255360,
                  "lineWidth": 2.0
                }
              }
            ]
          },
          {
            "name": "add_labels",
            "description": "The slope is 2, because for every 1 unit we move right, we go up 2 units",
            "startTime": 4.0,
            "endTime": 5.0,
            "easingFunction": "easeInOut",
            "elements": [
              {
                "type": "label",
                "attributes": {
                  "text": "Rise = 2",
                  "position": {"x": -10, "y": 40},
                  "color": 4294901760,
                  "fontSize": 16.0,
                  "fadeInStart": 0.0,
                  "fadeInEnd": 0.5
                }
              },
              {
                "type": "label",
                "attributes": {
                  "text": "Run = 1",
                  "position": {"x": 20, "y": 90},
                  "color": 4278255360,
                  "fontSize": 16.0,
                  "fadeInStart": 0.5,
                  "fadeInEnd": 1.0
                }
              }
            ]
          }
        ],
        "speech": {
          "script": "Let's learn about slope by drawing a line and analyzing its steepness.",
          "initialDelay": 0.0,
          "betweenStagesDelay": 0.5,
          "finalDelay": 1.0,
          "speechRate": 1.0
        },
        "metadata": {
          "title": "Understanding Slope",
          "difficulty": "beginner"
        }
      }
      ''';

      final spec = DrawingSpecParser.parseFromJson(jsonSpec);
      DrawingSpecParser.validate(spec);

      setState(() {
        _spec = spec;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading specification: $e';
      });
    }
  }

  void _handlePlayPause() {
    if (_spec == null) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _canvasKey.currentState?.play();
      _speechService.speakScript(_spec!.speech);
    } else {
      _canvasKey.currentState?.pause();
      _speechService.pause();
    }
  }

  void _handleReset() {
    if (_spec == null) return;

    setState(() {
      _isPlaying = false;
    });

    _canvasKey.currentState?.reset();
    _speechService.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khan Academy Style Drawing'),
        actions: [
          if (_spec != null) ...[
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _handlePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: _handleReset,
            ),
          ],
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _spec == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    DrawingCanvas(
                      key: _canvasKey,
                      spec: _spec!,
                      autoStart: false,
                    ),
                    SpeechOverlay(
                      spec: _spec!.speech,
                      getStageProgress:
                          _canvasKey.currentState?.getStageProgress ??
                              ((_) => 0.0),
                      stages: _spec!.stages,
                      isPlaying: _isPlaying,
                      onTap: _handlePlayPause,
                    ),
                  ],
                ),
    );
  }
}
