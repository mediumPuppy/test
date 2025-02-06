import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/learning_progress_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopicsScreen extends StatefulWidget {
  final String learningPathId;

  const TopicsScreen({
    super.key,
    required this.learningPathId,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _firestoreService = FirestoreService();
  final _progressService = LearningProgressService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, bool> _completedTopics = {};
  Map<String, double> _masteryLevels = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final progress = await _progressService.getUserProgress(_userId);
      final completedMap = progress['topicsCompleted'] as Map<String, dynamic>? ?? {};
      final masteryMap = progress['performanceMetrics'] as Map<String, dynamic>? ?? {};

      setState(() {
        _completedTopics = completedMap.map((key, value) => MapEntry(key, true));
        _masteryLevels = masteryMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading progress: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markTopicComplete(String topicId, String topicName) async {
    if (_userId == null) return;

    try {
      // Show performance input dialog
      final performance = await showDialog<double>(
        context: context,
        builder: (context) => _PerformanceDialog(topicName: topicName),
      );

      if (performance == null) {
        return;
      }

      // Update progress
      await _progressService.updateUserProgress(
        userId: _userId,
        topicId: topicId,
        performance: performance,
      );

      // Refresh progress
      await _loadProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topic marked as complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking topic complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.getLearningPathTopics(widget.learningPathId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final topics = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index].data();
                    final topicId = topics[index].id;
                    final isCompleted = _completedTopics[topicId] ?? false;
                    final mastery = _masteryLevels[topicId] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(topic['name'] ?? 'Unnamed Topic'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic['description'] ?? ''),
                            if (isCompleted) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: mastery,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                              Text(
                                'Mastery: ${(mastery * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        trailing: isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : TextButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Mark Complete'),
                                onPressed: () => _markTopicComplete(
                                  topicId,
                                  topic['name'] ?? 'Unnamed Topic',
                                ),
                              ),
                        children: [
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _firestoreService.getVideosByTopic(topicId),
                            builder: (context, videoSnapshot) {
                              if (videoSnapshot.hasError) {
                                return Center(child: Text('Error: ${videoSnapshot.error}'));
                              }

                              if (!videoSnapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final videos = videoSnapshot.data!.docs;
                              return Column(
                                children: videos.map((video) {
                                  final videoData = video.data();
                                  return ListTile(
                                    leading: const Icon(Icons.play_circle_outline),
                                    title: Text(videoData['title'] ?? 'Untitled Video'),
                                    subtitle: Text(videoData['description'] ?? ''),
                                    trailing: Text('${videoData['estimatedMinutes']} min'),
                                    onTap: () {
                                      // TODO: Navigate to video player
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PerformanceDialog extends StatefulWidget {
  final String topicName;

  const _PerformanceDialog({required this.topicName});

  @override
  State<_PerformanceDialog> createState() => _PerformanceDialogState();
}

class _PerformanceDialogState extends State<_PerformanceDialog> {
  double _performance = 0.8; // Default performance

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate Your Understanding: ${widget.topicName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How well do you understand this topic?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Slider(
            value: _performance,
            onChanged: (value) => setState(() => _performance = value),
            divisions: 10,
            label: '${(_performance * 100).round()}%',
          ),
          Text(
            _getPerformanceDescription(_performance),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _performance),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getPerformanceDescription(double performance) {
    if (performance < 0.2) return 'Need significant review';
    if (performance < 0.4) return 'Basic understanding';
    if (performance < 0.6) return 'Good understanding';
    if (performance < 0.8) return 'Very good understanding';
    return 'Complete mastery';
  }
}